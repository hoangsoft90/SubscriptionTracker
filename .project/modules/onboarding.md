# Module: Onboarding

**Files**: `lib/features/onboarding/` · **Spec**: M1 onboarding capability · **Milestone**: M1

## Trách nhiệm

Luồng chào mừng < 25s: Privacy Promise → primary currency → preset catalog.

## Screens & flow

`OnboardingScreen` (ConsumerStatefulWidget) 3 bước:

1. **Privacy Promise** — copy spec chính xác ("Subscription data is stored
   locally on your device. The app does not require a backend or account."),
   không xin quyền nào.
2. **Currency** — mặc định từ device locale (`defaultCurrencyFromLocale`:
   vi→VND, ja→JPY, en_GB→GBP, de/fr→EUR, fallback USD); đổi được.
3. **Preset catalog** — global + VN packs từ `preset_catalog.dart`; tên hiển thị
   qua `AppStrings.presetDisplayNames`; "Skip, start empty" hoặc "Start tracking".

## Data

- `Preset` model (`domain/preset.dart`): displayNameKey, category, icon,
  cancellationUrl?, trialDurationSuggestionDays?.
- `PresetCatalog` (`data/preset_catalog.dart`): const lists global + VN.
- Hoàn tất → `SettingsController.completeOnboarding({currency})` → persist
  `onboardingCompleted` + `primaryCurrency` vào `app_settings`.

## Gate

Router redirect: chưa onboard → `/onboarding`; xong → `/home` (xem app-shell.md).

## Test

`test/m1_widget_test.dart` — "shows onboarding when not completed" (harness với
`onboardingCompleted: false`).
