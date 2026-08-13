import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/notifications/notification_platform.dart';
import '../../../core/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const _currencies = ['USD', 'EUR', 'GBP', 'VND', 'JPY', 'KRW'];

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  /// OS notification permission state, refreshed on entry and after each
  /// enable attempt (the OS prompt / settings screen changes it externally).
  NotificationPermissionStatus? _notifStatus;
  bool _notifBusy = false;

  @override
  void initState() {
    super.initState();
    _refreshNotifStatus();
  }

  Future<void> _refreshNotifStatus() async {
    final status =
        await ref.read(notificationPermissionServiceProvider).status();
    if (mounted) setState(() => _notifStatus = status);
  }

  Future<void> _enableNotifications() async {
    setState(() => _notifBusy = true);
    try {
      // Requests the OS prompt (first time) or opens the OS notification
      // settings screen (after a previous ask — Android stops showing the
      // prompt after denial). Then refresh the shown status.
      await ref.read(notificationPermissionServiceProvider).enableFromSettings();
      await _refreshNotifStatus();
    } finally {
      if (mounted) setState(() => _notifBusy = false);
    }
  }

  Widget _notificationsSection(AppLocalizations l10n) {
    final enabled = _notifStatus == NotificationPermissionStatus.enabled;
    return Column(
      children: [
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: Text(l10n.settingsNotificationsTitle),
          subtitle: Text(l10n.settingsNotificationsHint),
          trailing: _notifBusy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  _notifStatus == null
                      ? ''
                      : enabled
                          ? l10n.settingsNotificationsEnabled
                          : l10n.settingsNotificationsDisabled,
                  style: TextStyle(
                    color: enabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
        if (_notifStatus != null && !enabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: _notifBusy ? null : _enableNotifications,
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: Text(
                  _notifStatus == null
                      ? ''
                      : l10n.settingsNotificationsEnable,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        top: false,
        child: settings == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.currency_exchange),
                    title: Text(l10n.settingsCurrency),
                    subtitle: Text(l10n.settingsCurrencyHint),
                    trailing: PopupMenuButton<String>(
                      tooltip: l10n.settingsCurrency,
                      onSelected: (c) => ref
                          .read(settingsControllerProvider.notifier)
                          .setPrimaryCurrency(c),
                      itemBuilder: (context) => [
                        for (final c in SettingsScreen._currencies)
                          PopupMenuItem(
                            value: c,
                            child: Row(
                              children: [
                                if (settings.primaryCurrency == c)
                                  const Icon(Icons.check, size: 18),
                                const SizedBox(width: 8),
                                Text(c),
                              ],
                            ),
                          ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              settings.primaryCurrency,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.translate),
                    title: Text(l10n.settingsLanguage),
                    trailing: PopupMenuButton<String?>(
                      tooltip: l10n.settingsLanguage,
                      onSelected: (code) => ref
                          .read(settingsControllerProvider.notifier)
                          .setLocale(code),
                      itemBuilder: (context) => [
                        _langItem(
                          context,
                          null,
                          l10n.languageSystem,
                          settings.localeCode == null,
                        ),
                        _langItem(
                          context,
                          'en',
                          l10n.languageEnglish,
                          settings.localeCode == 'en',
                        ),
                        _langItem(
                          context,
                          'vi',
                          l10n.languageVietnamese,
                          settings.localeCode == 'vi',
                        ),
                      ],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentLanguageLabel(settings.localeCode, l10n),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  // Theme mode: the SegmentedButton must NOT sit in the ListTile
                  // trailing — on narrow screens it gets squeezed to near-zero
                  // width and every label letter wraps to its own line. Render it
                  // full-width below the title instead.
                  ListTile(
                    leading: const Icon(Icons.brightness_6_outlined),
                    title: Text(l10n.settingsTheme),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text(l10n.settingsThemeSystem),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(l10n.settingsThemeLight),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(l10n.settingsThemeDark),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (selection) => ref
                            .read(settingsControllerProvider.notifier)
                            .setThemeMode(selection.first),
                      ),
                    ),
                  ),
                  _notificationsSection(l10n),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.category_outlined),
                    title: Text(l10n.settingsCategories),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/more/categories'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(l10n.settingsAbout),
                    subtitle: Text(l10n.aboutPrivacyLine),
                  ),
                ],
              ),
      ),
    );
  }

  String _currentLanguageLabel(String? localeCode, dynamic l10n) {
    switch (localeCode) {
      case 'en':
        return l10n.languageEnglish;
      case 'vi':
        return l10n.languageVietnamese;
      default:
        return l10n.languageSystem;
    }
  }

  PopupMenuItem<String?> _langItem(
    BuildContext context,
    String? code,
    String label,
    bool selected,
  ) {
    return PopupMenuItem(
      value: code,
      child: Row(
        children: [
          if (selected) const Icon(Icons.check, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
