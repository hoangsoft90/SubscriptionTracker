# SubTrack — Knowledge Item (KI)

> **Entry point** cho toàn bộ tri thức về project **SubTrack** — app mobile theo dõi
> subscription, privacy-focused, không backend, không analytics SDK.

Project này được phát triển theo workflow **OpenSpec spec-driven** (xem
[`openspec/`](../openspec/) và [`AGENTS.md`](../AGENTS.md)). File này là nơi bắt đầu
đọc: đọc theo thứ tự dưới đây.

## 📚 Tài liệu

| File | Nội dung |
| --- | --- |
| [`overview.md`](overview.md) | Tổng quan project: mục đích, tech stack, cấu trúc, roadmap |
| [`architecture.md`](architecture.md) | Kiến trúc: Feature-First, Riverpod, GoRouter, SQLite, data flow |
| [`patterns.md`](patterns.md) | Các pattern lặp lại: Money, Billing, Repository, Controller, Test |
| [`state.md`](state.md) | **Trạng thái hiện tại**: todo list, milestone đã xong, test status |
| [`ai-rules.md`](ai-rules.md) | Quy tắc bắt buộc khi AI (hoặc dev) code trong repo này |
| [`modules/`](modules/) | Chi tiết từng module/feature (domain, data, application, presentation) |

## 🚀 TL;DR

- **App**: Flutter mobile (Android + iOS + web), theo dõi subscription với lời hứa
  privacy — toàn bộ dữ liệu ở local (SQLite trên mobile, localStorage trên web),
  **không** analytics/crash SDK (ngoại lệ duy nhất: AdMob non-personalized, free tier).
- **Core invariant**: tiền luôn là **int minor units** (`Money`), ngày luôn là
  **calendar date local** (`DateUtils`), billing tính theo **anchor-day**.
- **State**: Riverpod 3 (`AsyncNotifier`, plain — không codegen).
- **Routing**: GoRouter, 3 tab (Home / Subscriptions / More) + onboarding gate +
  routes `/calendar`, `/paywall`, `/more/*`, error recovery page.
- **Storage**: mobile = sqflite (`PRAGMA user_version` migrations, v2), web =
  browser localStorage (cùng interface repository); seeder idempotent.
- **Milestone**: M0 ✅, M1 ✅, M2 ✅ (platform-store: notifications/backup/IAP),
  M2.5 ✅ (decision-engine: brief/queue/savings/calendar/price-history), Guidance ✅
  (in-app guidance + review fixes), platform config ✅ (targetSdk 36).
- **Tests**: 203/203 tests xanh, `flutter analyze` sạch (2026-08-12).

## 🔗 Liên kết nhanh

- Plan gốc (locked spec): [`.plan/plan1_final_1.md`](../.plan/plan1_final_1.md)
- OpenSpec changes: [`openspec/changes/`](../openspec/changes/) (5 change: core-engine,
  core-ux, platform-store, decision-engine, guidance)
- Workspace rules: [`AGENTS.md`](../AGENTS.md) (bắt buộc đọc, tiếng Việt)
