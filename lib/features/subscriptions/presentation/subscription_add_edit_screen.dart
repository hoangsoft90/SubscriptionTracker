import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/calendar/date_utils.dart' as cal;
import '../../../core/l10n/l10n.dart';
import '../../../core/money/money.dart';
import '../../ads/ads_controller.dart';
import '../../paywall/entitlement_controller.dart';
import '../../paywall/free_tier.dart';
import '../../settings/application/settings_controller.dart';
import '../application/subscription_list_controller.dart';
import '../data/preset_catalog.dart';
import '../domain/billing_calculator.dart';
import '../domain/billing_cycle.dart';
import '../domain/subscription.dart';
import '../domain/subscription_status.dart';

class SubscriptionAddEditScreen extends ConsumerStatefulWidget {
  const SubscriptionAddEditScreen({super.key, this.subscriptionId});

  /// When null → add mode; otherwise edit mode.
  final String? subscriptionId;

  @override
  ConsumerState<SubscriptionAddEditScreen> createState() =>
      _SubscriptionAddEditScreenState();
}

class _SubscriptionAddEditScreenState
    extends ConsumerState<SubscriptionAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _urlController = TextEditingController();
  final _customIntervalController = TextEditingController();

  String _currency = 'USD';
  BillingCycle _cycle = BillingCycle.monthly;
  DateTime _startDate = cal.DateUtils.localMidnight(DateTime.now());
  DateTime _nextBilling = cal.DateUtils.localMidnight(DateTime.now());
  bool _isTrial = false;
  DateTime? _trialEnd;
  String? _categoryId;
  String? _iconEmoji;
  bool _saving = false;

  bool get _isEdit => widget.subscriptionId != null;

  @override
  void initState() {
    super.initState();
    final currency =
        ref.read(settingsControllerProvider).value?.primaryCurrency ?? 'USD';
    _currency = currency;
    if (_isEdit) {
      _loadExisting();
    } else {
      // Onboarding preset selection pre-fills this first add form (name,
      // category, icon, cancellation URL) — never price/cycle (spec §6).
      _applyPendingPreset();
    }
  }

  /// Consumes the first pending onboarding preset (if any) as pre-fill. The
  /// preset stays queued until a successful save, so cancelling the form does
  /// not lose it.
  Future<void> _applyPendingPreset() async {
    final settings = await ref.read(settingsControllerProvider.future);
    if (!mounted) return;
    final pending = settings.onboardingPresets;
    if (pending.isEmpty) return;
    final preset = PresetCatalog.all
        .where((p) => p.id == pending.first)
        .firstOrNull;
    if (preset == null) return;
    _nameController.text = presetDisplayName(context, preset.displayNameKey);
    _categoryId = preset.category;
    _iconEmoji = preset.icon;
    _urlController.text = preset.cancellationUrl ?? '';
    if (preset.trialDurationSuggestionDays != null) {
      _isTrial = true;
      _trialEnd = cal.DateUtils.localMidnight(
        DateTime.now().add(Duration(days: preset.trialDurationSuggestionDays!)),
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _loadExisting() async {
    final listState = await ref.read(subscriptionListControllerProvider.future);
    final sub = listState.subscriptions
        .where((s) => s.id == widget.subscriptionId)
        .firstOrNull;
    if (sub == null) return;
    _nameController.text = sub.name;
    _amountController.text = _toAmountString(sub);
    _notesController.text = sub.notes ?? '';
    _urlController.text = sub.cancellationUrl ?? '';
    _customIntervalController.text = sub.customIntervalDays?.toString() ?? '';
    _currency = sub.currency;
    _cycle = sub.billingCycle;
    _startDate = sub.startDate;
    _nextBilling = sub.nextBillingDate;
    _isTrial = sub.isTrial;
    _trialEnd = sub.trialEndDate;
    _categoryId = sub.categoryId;
    _iconEmoji = sub.iconEmoji;
    setState(() {});
  }

  String _toAmountString(Subscription sub) {
    final decimals = Money.currencyDecimals[sub.currency] ?? 2;
    final whole = sub.amountMinor ~/ _pow10(decimals);
    final frac = sub.amountMinor % _pow10(decimals);
    if (decimals == 0) return '$whole';
    return '$whole.${frac.toString().padLeft(decimals, '0')}';
  }

  int _pow10(int n) {
    var r = 1;
    for (var i = 0; i < n; i++) {
      r *= 10;
    }
    return r;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    _customIntervalController.dispose();
    super.dispose();
  }

  /// PRICE CHANGED confirmation (plan2_final §7): shows the absolute +
  /// percentage change and the new vs. old yearly cost. Percentage is only
  /// shown when the currency is unchanged — a currency switch records history
  /// without a comparison (no percent). Returns false when the user dismisses
  /// (the edit is aborted so the new price is never silently saved).
  Future<bool> _confirmPriceChange(
    BuildContext context, {
    required Subscription existing,
    required Money newAmount,
  }) async {
    final l10n = context.l10n;
    final sameCurrency = existing.currency == newAmount.currency;

    String delta;
    String percent;
    if (sameCurrency) {
      final diff = newAmount.amountMinor - existing.amountMinor;
      final sign = diff >= 0 ? '+' : '';
      delta = '$sign${Money(diff.abs(), newAmount.currency).format()}';
      if (existing.amountMinor == 0) {
        percent = '—';
      } else {
        final pct = (diff * 100) ~/ existing.amountMinor;
        percent = '${pct >= 0 ? '+' : ''}$pct';
      }
    } else {
      delta = Money(newAmount.amountMinor, newAmount.currency).format();
      percent = '—';
    }

    final oldYearly = BillingCalculator.projectToYearly(
      amountMinor: existing.amountMinor,
      cycle: existing.billingCycle,
      customIntervalDays: existing.customIntervalDays,
    );
    final newYearly = BillingCalculator.projectToYearly(
      amountMinor: newAmount.amountMinor,
      cycle: _cycle,
      customIntervalDays: _cycle == BillingCycle.custom
          ? int.tryParse(_customIntervalController.text.trim())
          : null,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.priceChangedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.priceChangedSummary(delta, percent),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // A currency switch makes the old-vs-new yearly comparison
            // meaningless across two units — show the new yearly only
            // (plan2_final §7: currency change → no comparison).
            Text(
              sameCurrency
                  ? l10n.priceChangedYearly(
                      Money(newYearly, newAmount.currency).format(),
                      Money(oldYearly, existing.currency).format(),
                    )
                  : l10n.priceChangedNewYearly(
                      Money(newYearly, newAmount.currency).format(),
                    ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.priceChangedSave),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _pickDate(
    DateTime initial,
    ValueChanged<DateTime> onPick,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(2040),
    );
    if (picked != null) {
      onPick(cal.DateUtils.localMidnight(picked));
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Free-tier hard block (spec §2.8 + plan2_final §5): adding an 11th
    // paywall-slot subscription (ACTIVE + PENDING_CANCELLATION) is blocked
    // and the user is directed to the Lifetime Pro paywall.
    if (!_isEdit) {
      final listState = await ref.read(
        subscriptionListControllerProvider.future,
      );
      final isPro = ref.read(proEntitlementControllerProvider).value ?? false;
      final slotCount = paywallSlotCount(listState.subscriptions);
      final tier = freeTierState(activeCount: slotCount, isPro: isPro);
      if (tier == FreeTierState.hardBlock) {
        if (mounted) context.push('/paywall');
        return;
      }
    }

    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final amount = Money.parse(_amountController.text.trim(), _currency);
    final now = DateTime.now();
    final id = _isEdit ? widget.subscriptionId! : const Uuid().v4();

    // Edit: keep created_at and status; recompute nothing — nextBilling is a
    // user-editable field in this form (matches the locked data model).
    final existing = _isEdit
        ? (await ref.read(
            subscriptionListControllerProvider.future,
          )).subscriptions.where((s) => s.id == id).firstOrNull
        : null;

    // Price-change detection (plan2_final §7): editing the amount of an ACTIVE
    // subscription shows a PRICE CHANGED confirmation. Percentage is only
    // meaningful when the currency is unchanged — a currency switch records
    // history without a comparison.
    var previousAmountMinor = existing?.previousAmountMinor;
    if (_isEdit &&
        existing != null &&
        existing.status == SubscriptionStatus.active &&
        existing.amountMinor != amount.amountMinor) {
      if (!mounted) return;
      previousAmountMinor = existing.amountMinor;
      final confirmed = await _confirmPriceChange(
        context,
        existing: existing,
        newAmount: amount,
      );
      if (!confirmed || !mounted) return; // dismissed or gone → abort
    }

    final subscription = Subscription(
      id: id,
      name: name,
      amountMinor: amount.amountMinor,
      currency: _currency,
      billingCycle: _cycle,
      customIntervalDays: _cycle == BillingCycle.custom
          ? int.tryParse(_customIntervalController.text.trim())
          : null,
      startDate: _startDate,
      nextBillingDate: _nextBilling,
      billingAnchorDay: _startDate.day,
      isTrial: _isTrial,
      trialEndDate: _isTrial ? _trialEnd : null,
      cancellationUrl: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
      status: existing?.status ?? SubscriptionStatus.active,
      categoryId: _categoryId,
      color: existing?.color,
      iconEmoji: _iconEmoji ?? existing?.iconEmoji,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      previousAmountMinor: previousAmountMinor,
    );

    final notifier = ref.read(subscriptionListControllerProvider.notifier);
    if (_isEdit) {
      // Persist the price history row (plan2_final §7) alongside the update.
      if (previousAmountMinor != null) {
        await notifier.recordPriceChange(subscription.id, subscription);
      }
      await notifier.updateSubscription(subscription);
    } else {
      await notifier.add(subscription);
      // The pre-filled preset is consumed now that it was actually saved.
      final settings = ref.read(settingsControllerProvider).value;
      if (settings != null && settings.onboardingPresets.isNotEmpty) {
        await ref
            .read(settingsControllerProvider.notifier)
            .setOnboardingPresets(settings.onboardingPresets.sublist(1));
      }
      // Rare free-tier interstitial (frequency-guarded inside; Pro: never).
      ref
          .read(interstitialAdsControllerProvider.notifier)
          .onSubscriptionAdded();
    }

    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isPro = ref.watch(proEntitlementControllerProvider).value ?? false;
    final list = ref.watch(subscriptionListControllerProvider).value;
    final slotCount = list == null ? 0 : paywallSlotCount(list.subscriptions);
    final tier = freeTierState(activeCount: slotCount, isPro: isPro);
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.editTitle : l10n.addTitle)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (!_isEdit && tier == FreeTierState.slotsLeft)
              _SlotsBanner(count: freeSlotsLeft(slotCount)),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.fieldName,
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.validationRequired
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: l10n.fieldAmount,
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixIcon: _currencyDropdown(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return l10n.validationRequired;
                        }
                        try {
                          Money.parse(v.trim(), _currency);
                          return null;
                        } on FormatException {
                          return l10n.validationInvalidAmount;
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<BillingCycle>(
                      initialValue: _cycle,
                      decoration: InputDecoration(
                        labelText: l10n.fieldCycle,
                        prefixIcon: const Icon(Icons.repeat),
                      ),
                      items: BillingCycle.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(_cycleLabel(context, c)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _cycle = v);
                      },
                    ),
                    if (_cycle == BillingCycle.custom) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customIntervalController,
                        decoration: InputDecoration(
                          labelText: l10n.customIntervalDays,
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final days = int.tryParse(v?.trim() ?? '');
                          if (days == null || days <= 0) {
                            return l10n.validationRequired;
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: l10n.fieldStartDate,
                            value: _startDate,
                            onTap: () => _pickDate(_startDate, (d) {
                              _startDate = d;
                              _nextBilling = d;
                            }),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DateField(
                            label: l10n.fieldNextBilling,
                            value: _nextBilling,
                            onTap: () => _pickDate(
                              _nextBilling,
                              (d) => _nextBilling = d,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // "Free trial?" toggle in the primary step (spec: independent of
                    // nextBillingDate).
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.fieldTrialToggle),
                      value: _isTrial,
                      onChanged: (v) => setState(() => _isTrial = v),
                    ),
                    if (_isTrial) ...[
                      _DateField(
                        label: l10n.fieldTrialEnd,
                        value:
                            _trialEnd ??
                            DateTime.now().add(const Duration(days: 7)),
                        onTap: () => _pickDate(
                          _trialEnd ??
                              DateTime.now().add(const Duration(days: 7)),
                          (d) => _trialEnd = d,
                        ),
                      ),
                      Text(
                        l10n.fieldTrialSuggestion,
                        style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: l10n.fieldCancellationUrl,
                        prefixIcon: const Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final uri = Uri.tryParse(v.trim());
                        if (uri == null || !uri.hasScheme) {
                          return l10n.validationInvalidUrl;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: l10n.fieldNotes,
                        prefixIcon: const Icon(Icons.notes),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.save),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyDropdown() {
    return PopupMenuButton<String>(
      tooltip: context.l10n.fieldCurrency,
      onSelected: (c) => setState(() => _currency = c),
      itemBuilder: (context) => [
        for (final c in ['USD', 'EUR', 'GBP', 'VND', 'JPY', 'KRW'])
          PopupMenuItem(value: c, child: Text(c)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _currency,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  static String _cycleLabel(BuildContext context, BillingCycle cycle) {
    final l10n = context.l10n;
    return switch (cycle) {
      BillingCycle.weekly => l10n.cycleWeekly,
      BillingCycle.monthly => l10n.cycleMonthly,
      BillingCycle.quarterly => l10n.cycleQuarterly,
      BillingCycle.yearly => l10n.cycleYearly,
      BillingCycle.custom => l10n.cycleCustom,
    };
  }
}

/// Light "N free slots left" banner shown on the add form at 9–10 active
/// subscriptions (spec §2.8 staged messaging).
class _SlotsBanner extends StatelessWidget {
  const _SlotsBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.freeSlotsBanner(count),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event),
        ),
        child: Text(formatDateFull(value)),
      ),
    );
  }

  static String formatDateFull(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}
