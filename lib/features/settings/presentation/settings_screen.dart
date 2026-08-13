import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../application/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _currencies = ['USD', 'EUR', 'GBP', 'VND', 'JPY', 'KRW'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        for (final c in _currencies)
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
