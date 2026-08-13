# Module: Shared widgets & Localization

**Files**: `lib/shared/widgets/{empty_state, money_text}.dart`,
`lib/core/l10n/app_strings.dart` · **Milestone**: M1

## Shared widgets

- `EmptyState({icon, title, body, ctaLabel, onCta})` — dùng ở dashboard, list,
  search (reusable, spec 6.2).
- `MoneyText(money, {style, currencyCode})` — boundary duy nhất render tiền qua
  `Money.format()`; `currencyCode: true` append code ("19.99 USD"). Widgets không
  bao giờ chạm raw int.

## Localization

- `AppStrings` — abstract final class, EN strings key scaffold; UI chỉ tham
  chiếu key (không string literal).
- `presetDisplayNames` map key→tên (preset.netflix → "Netflix", ...).
- M2 sẽ wire EN/VI qua `intl`/ARB — thay accessor là đủ, không đổi string.
- **User-entered data không bao giờ localize** (spec §6).

## Test

MoneyText format được assert trong `m1_crud_widget_test.dart` ("14.99",
"19.99 USD"); EmptyState trong `m1_widget_test.dart`.
