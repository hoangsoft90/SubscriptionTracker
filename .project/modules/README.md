# Modules — chi tiết từng module

Index các module của SubTrack. Mỗi file mô tả: trách nhiệm, API chính,
file quan trọng, pattern, test liên quan.

| Module | Đường dẫn | Trạng thái |
| --- | --- | --- |
| [Money](money.md) | `lib/core/money/money.dart` | ✅ M0 |
| [Calendar dates](calendar.md) | `lib/core/calendar/date_utils.dart` | ✅ M0 |
| [Billing engine](billing.md) | `lib/features/subscriptions/domain/billing_calculator.dart` | ✅ M0 |
| [Storage & repos](storage.md) | `lib/core/storage/`, `lib/features/*/data/` | ✅ M0 |
| [Providers & state](state-providers.md) | `lib/core/providers.dart`, `lib/features/*/application/` | ✅ M0/M1 |
| [App shell & routing](app-shell.md) | `lib/app/`, `lib/main.dart` | ✅ M1 |
| [Onboarding](onboarding.md) | `lib/features/onboarding/` | ✅ M1 |
| [Subscriptions UI](subscriptions-ui.md) | `lib/features/subscriptions/presentation/` | ✅ M1 |
| [Dashboard](dashboard.md) | `lib/features/dashboard/` | ✅ M1 |
| [Categories](categories.md) | `lib/features/categories/` | ✅ M1 |
| [Settings](settings.md) | `lib/features/settings/` | ✅ M1 |
| [Shared widgets & l10n](shared-l10n.md) | `lib/shared/`, `lib/core/l10n/` | ✅ M1/M2 |
| [Test infrastructure](test-infra.md) | `test/` | ✅ M0/M1/M2.5 |
| [Guidance](guidance.md) | `lib/features/guidance/` | ✅ 2026-08-12 |

Module mới từ M2/M2.5 chưa có module doc riêng — xem chi tiết tại
`working.md` + `openspec/changes/` (platform-store, decision-engine):
Notifications (`lib/core/notifications/`), Backup (`lib/features/backup/`),
Paywall & ads (`lib/features/paywall/`, `lib/features/ads/`), Decision engine
(`lib/features/decision/`, `lib/features/calendar/`).
