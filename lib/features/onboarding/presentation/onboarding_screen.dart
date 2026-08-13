import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../settings/application/settings_controller.dart';
import '../../subscriptions/data/preset_catalog.dart';
import '../../subscriptions/domain/preset.dart';
import '../application/onboarding_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  static const _currencies = ['USD', 'EUR', 'GBP', 'VND', 'JPY', 'KRW'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(onboardingControllerProvider).step;
    final settings = ref.watch(settingsControllerProvider).value;
    final locale = Localizations.localeOf(context).toString();

    // Default currency follows the device locale, USD fallback.
    final defaultCurrency =
        settings?.primaryCurrency ?? SettingsController.defaultCurrencyFromLocale(locale);

    final steps = [
      _PrivacyStep(onNext: () {
        ref.read(onboardingControllerProvider.notifier).next();
      }),
      _CurrencyStep(
        defaultCurrency: defaultCurrency,
        onNext: (currency) {
          ref.read(onboardingControllerProvider.notifier).next();
        },
      ),
      // onDone only marks onboarding complete — the router's redirect
      // handles navigation (restoring any deep-link destination).
      _PresetsStep(onDone: () {
        ref.read(settingsControllerProvider.notifier).completeOnboarding();
      }),
    ];

    final content = step < steps.length ? steps[step] : steps.last;

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(key: ValueKey(step), child: content),
        ),
      ),
    );
  }
}

class _PrivacyStep extends StatelessWidget {
  const _PrivacyStep({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Icon(Icons.shield_outlined,
              size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingPrivacyTitle,
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onboardingPrivacyBody,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onNext,
            child: Text(l10n.onboardingContinue),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _CurrencyStep extends ConsumerStatefulWidget {
  const _CurrencyStep({required this.defaultCurrency, required this.onNext});

  final String defaultCurrency;
  final ValueChanged<String> onNext;

  @override
  ConsumerState<_CurrencyStep> createState() => _CurrencyStepState();
}

class _CurrencyStepState extends ConsumerState<_CurrencyStep> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.defaultCurrency;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Text(
            context.l10n.onboardingCurrencyTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingCurrencyBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final currency in OnboardingScreen._currencies)
                ChoiceChip(
                  label: Text(currency),
                  selected: _selected == currency,
                  onSelected: (_) => setState(() => _selected = currency),
                ),
            ],
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              widget.onNext(_selected);
              ref
                  .read(settingsControllerProvider.notifier)
                  .setPrimaryCurrency(_selected);
            },
            child: Text(context.l10n.onboardingContinue),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _PresetsStep extends ConsumerStatefulWidget {
  const _PresetsStep({required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<_PresetsStep> createState() => _PresetsStepState();
}

class _PresetsStepState extends ConsumerState<_PresetsStep> {
  var _isVnPack = false;

  /// Preset ids the user tapped. Selection is visual only — presets NEVER
  /// create subscriptions; they pre-fill the first add form after onboarding
  /// (spec §6: no prices/cycles are ever hard-coded).
  final _selectedIds = <String>{};

  List<Preset> get _pack => _isVnPack ? PresetCatalog.vietnam : PresetCatalog.global;

  void _togglePreset(Preset preset) {
    setState(() {
      if (!_selectedIds.remove(preset.id)) {
        _selectedIds.add(preset.id);
      }
    });
  }

  void _persistSelection() {
    if (_selectedIds.isEmpty) return;
    ref
        .read(settingsControllerProvider.notifier)
        .setOnboardingPresets(_selectedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.onboardingPresetsTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.onboardingPresetsBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Center(
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(context.l10n.presetPackGlobal),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(context.l10n.presetPackVn),
                ),
              ],
              selected: {_isVnPack},
              onSelectionChanged: (selection) =>
                  setState(() => _isVnPack = selection.first),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 140,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _pack.length,
              itemBuilder: (context, index) {
                final preset = _pack[index];
                return _PresetTile(
                  preset: preset,
                  selected: _selectedIds.contains(preset.id),
                  onTap: () => _togglePreset(preset),
                );
              },
            ),
          ),
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.l10n.onboardingPresetsSelected(_selectedIds.length),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              _persistSelection();
              widget.onDone();
            },
            child: Text(context.l10n.onboardingSkip),
          ),
          FilledButton(
            onPressed: () {
              _persistSelection();
              widget.onDone();
            },
            child: Text(context.l10n.onboardingDone),
          ),
        ],
      ),
    );
  }
}

class _PresetTile extends StatelessWidget {
  const _PresetTile({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final Preset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = presetDisplayName(context, preset.displayNameKey);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: selected ? 2 : 1,
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: selected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(preset.icon, style: const TextStyle(fontSize: 28)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    name,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.check,
                    size: 14,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
