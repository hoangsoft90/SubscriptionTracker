# Module: Billing engine

**Files**: `lib/features/subscriptions/domain/` — `billing_calculator.dart`,
`billing_cycle.dart`, `subscription_status.dart`, `subscription.dart`
· **Spec**: §7 · **Milestone**: M0

## Trách nhiệm

Tính toán lịch billing theo chính sách "same day if possible, else last day of
month" — invariant-tested core.

## API chính

- `enum BillingCycle { weekly, monthly, quarterly, yearly, custom }` — có
  `dbValue` (UPPERCASE), `fromDb`; **không có getter `name`** (dùng `dbValue`).
- `enum SubscriptionStatus { active, cancelled, archived }` — 3 trạng thái MVP.
- `nextBillingDate(sub, from)` — anchor-day preserve:
  - MONTHLY/QUARTERLY/YEARLY: **cần `billingAnchorDay`** (throw khi thiếu —
    chống drift); clamp cuối tháng.
  - CUSTOM: `startDate + n × customIntervalDays`.
  - WEEKLY: bỏ anchor.
- Projections int-safe: `projectYearly(sub)` — weekly×52, monthly×12,
  quarterly×4, yearly×1, custom `(amount×365) ~/ days` (days ≤ 0 → ×12).

## Quyết định quan trọng

- **Anchor-day bắt buộc cho fixed cycles** — thiết kế chống drift ngày billing
  (review finding M0: guard `billingAnchorDay` throw khi thiếu).
- `isTrialActive(sub)` (trong `subscription_list_screen.dart`): trial còn hiệu
  lực khi `isTrial && trialEndDate != null && trialEndDate > now`.

## Test

`test/billing_calculator_test.dart`: 31/01→28/02→31/03, leap 2028, Dec→Jan,
custom 45d, clamp-restore, projections integer-exact.
