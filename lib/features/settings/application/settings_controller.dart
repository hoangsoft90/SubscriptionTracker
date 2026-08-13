import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';

/// Persisted app settings: theme mode, primary currency, onboarding flag,
/// locale override (null → follow the device locale) and the preset ids
/// selected during onboarding (pre-fill queue for the first add forms).
class SettingsState {
  const SettingsState({
    required this.themeMode,
    required this.primaryCurrency,
    required this.onboardingCompleted,
    this.localeCode,
    this.onboardingPresets = const [],
  });

  final ThemeMode themeMode;
  final String primaryCurrency;
  final bool onboardingCompleted;

  /// BCP-47 language code ('en' / 'vi') or null to follow the device locale.
  final String? localeCode;

  /// Preset ids picked on the onboarding presets step, in order — the add
  /// form consumes them one by one to pre-fill name/category/icon/URL.
  final List<String> onboardingPresets;

  SettingsState copyWith({
    ThemeMode? themeMode,
    String? primaryCurrency,
    bool? onboardingCompleted,
    String? localeCode,
    bool clearLocale = false,
    List<String>? onboardingPresets,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      primaryCurrency: primaryCurrency ?? this.primaryCurrency,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      onboardingPresets: onboardingPresets ?? this.onboardingPresets,
    );
  }
}

/// Loads and persists settings through the M0 `app_settings` repository.
class SettingsController extends AsyncNotifier<SettingsState> {
  static const _themeModeKey = 'themeMode';
  static const _primaryCurrencyKey = 'primaryCurrency';
  static const _onboardingKey = 'onboardingCompleted';
  static const _localeKey = 'language';
  static const _onboardingPresetsKey = 'onboardingPresets';

  static const _fallbackCurrency = 'USD';

  @override
  Future<SettingsState> build() async {
    final repo = await ref.watch(settingsRepositoryProvider.future);
    final themeModeValue = await repo.get(_themeModeKey);
    final currency = await repo.get(_primaryCurrencyKey) ?? _fallbackCurrency;
    final onboarding =
        (await repo.get(_onboardingKey) ?? 'false') == 'true';
    final localeRaw = await repo.get(_localeKey);
    final localeCode =
        (localeRaw == null || localeRaw == 'system') ? null : localeRaw;
    final presetsRaw = await repo.get(_onboardingPresetsKey);
    final onboardingPresets = (presetsRaw == null || presetsRaw.isEmpty)
        ? const <String>[]
        : presetsRaw.split(',');

    return SettingsState(
      themeMode: _parseThemeMode(themeModeValue),
      primaryCurrency: currency,
      onboardingCompleted: onboarding,
      localeCode: localeCode,
      onboardingPresets: onboardingPresets,
    );
  }

  static ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.set(_themeModeKey, mode.name);
    state = AsyncData(state.value!.copyWith(themeMode: mode));
  }

  /// Changes the primary currency without converting historical amounts —
  /// existing amounts keep their own currency; the dashboard regroups.
  Future<void> setPrimaryCurrency(String currency) async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.set(_primaryCurrencyKey, currency);
    state = AsyncData(state.value!.copyWith(primaryCurrency: currency));
  }

  Future<void> completeOnboarding({String? currency}) async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.set(_onboardingKey, 'true');
    if (currency != null) {
      await repo.set(_primaryCurrencyKey, currency);
    }
    state = AsyncData(state.value!.copyWith(
      onboardingCompleted: true,
      primaryCurrency: currency ?? state.value!.primaryCurrency,
    ));
  }

  /// Persists the preset ids selected during onboarding. Presets never create
  /// subscriptions — they only pre-fill the add form (spec §6).
  Future<void> setOnboardingPresets(List<String> ids) async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    await repo.set(_onboardingPresetsKey, ids.join(','));
    state = AsyncData(state.value!.copyWith(onboardingPresets: List.of(ids)));
  }

  /// Sets the app language. [code] is 'en' / 'vi'; null → follow device.
  /// User-entered data (names/notes) is never touched (spec §localization).
  Future<void> setLocale(String? code) async {
    final repo = await ref.read(settingsRepositoryProvider.future);
    if (code == null) {
      await repo.set(_localeKey, 'system');
    } else {
      await repo.set(_localeKey, code);
    }
    state = AsyncData(state.value!.copyWith(
      localeCode: code,
      clearLocale: code == null,
    ));
  }

  /// Estimates the primary currency from the device locale, falling back to
  /// USD when the locale's currency cannot be determined (spec M1 onboarding).
  static String defaultCurrencyFromLocale(String locale) {
    final normalized = locale.replaceAll('-', '_');
    final currency = _localeCurrencyMap[normalized] ??
        _localeCurrencyMap[normalized.split('_').first];
    return currency ?? _fallbackCurrency;
  }

  static const _localeCurrencyMap = <String, String>{
    'vi': 'VND',
    'vi_VN': 'VND',
    'ja': 'JPY',
    'ja_JP': 'JPY',
    'ko': 'KRW',
    'ko_KR': 'KRW',
    'en_GB': 'GBP',
    'de': 'EUR',
    'de_DE': 'EUR',
    'fr': 'EUR',
    'fr_FR': 'EUR',
  };
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
  SettingsController.new,
);
