# Overview

## Mục đích

**SubTrack** là app mobile theo dõi subscription, **privacy-focused**:

- Dữ liệu **100% local** (SQLite) — không backend, không tài khoản.
- **Không** analytics SDK, **không** crash SDK (ràng buộc privacy cốt lõi).
- UX mục tiêu: onboarding < 25s, "Cost Shock" dashboard, trial badge, search/filter.
- Nhắm người dùng VN + toàn cầu: preset catalog có cả pack VN (FPT Play, Galaxy
  Play, VieON, Zing MP3, NhacCuaTui, K+), hỗ trợ VND (0 decimals).

## Tech stack

| Thành phần | Lựa chọn | Ghi chú |
| --- | --- | --- |
| Framework | Flutter (Dart SDK ^3.12.2, Flutter 3.44.6) | Material 3; targetSdk 36 |
| State | `flutter_riverpod` ^3.4.2 | `AsyncNotifier` **plain** (không codegen) |
| Routing | `go_router` ^17.4.0 | StatefulShellRoute 3 tab + onboarding gate + deep-link |
| Storage | mobile: `sqflite` ^2.4.3 (v2 migrations); web: `web` localStorage | chung interface repository (`StorageBackend` split) |
| L10n | `flutter_localizations` + `intl` | ARB EN/VI, `flutter gen-l10n` |
| Notifications | `flutter_local_notifications` + `timezone` + `workmanager` | scheduler 7-bước, iOS cap 50 |
| Backup | `file_picker` + `share_plus` | JSON versioned export/import |
| IAP | `in_app_purchase` | Lifetime Pro (non-consumable) |
| Ads | `google_mobile_ads` ^9.0.0 | banner đáy + interstitial hiếm, free tier, npa=1 |
| Khác | `uuid`, `url_launcher`, `flutter_timezone` | — |
| Test | `flutter_test` + `sqflite_common_ffi` (dev) + `integration_test` | unit + widget + device |
| Lint | `flutter_lints` ^6.0.0 | `flutter analyze` sạch |

## Cấu trúc thư mục

```
lib/
├── main.dart                 # Entry: runApp(ProviderScope > SubTrackApp)
├── app/
│   ├── app.dart              # SubTrackApp (MaterialApp.router, themeMode/locale từ settings)
│   ├── router/app_router.dart# GoRouter: /onboarding + shell 3 branch + /calendar, /paywall, /more/*
│   └── theme/app_theme.dart  # AppTheme light/dark (Material 3, seed teal #00696D)
├── core/
│   ├── money/money.dart      # Money (int minor units) + sumByCurrency
│   ├── calendar/date_utils.dart # Local calendar dates, addMonthsClamped, parse
│   ├── storage/              # app_database + migrations (v2) + seeder + storage split
│   ├── notifications/        # scheduler, coordinator, permission, ids, reboot_rescheduler
│   ├── providers.dart        # DB + repository providers + notifications/coordinator/ads wiring
│   └── l10n/                 # ARB EN/VI (gen-l10n → lib/l10n/)
├── features/
│   ├── subscriptions/        # domain (Subscription, BillingCycle, BillingCalculator,
│   │                         #   SubscriptionStatus, Preset, price history) + data +
│   │                         #   application (list controller) + presentation (list/add-edit/detail)
│   ├── categories/           # data + application (controller) + presentation (screen)
│   ├── settings/             # data + application (controller) + presentation (more tab)
│   ├── onboarding/           # application (controller) + presentation (screen)
│   ├── dashboard/            # application (controller: brief/queue/savings/month) + presentation (home)
│   ├── decision/             # review_queue, today_brief, savings (pure domain)
│   ├── calendar/             # money_calendar (service + screen)
│   ├── guidance/             # FeatureBadge, SpotlightOverlay, DisabledStateHelper, GuidanceHost + controller
│   ├── backup/               # export/import services + backup screen
│   ├── paywall/              # entitlement controller, free_tier, purchase gateway, paywall screen
│   ├── ads/                  # ads_controller + ads_config + banner/interstitial
│   └── settings/…            # …
└── shared/widgets/           # empty_state, money_text
```

Test (mỗi nhóm tách file):
```
test/
├── money_test.dart                # Money.parse/format/+/sum — 13 tests
├── billing_calculator_test.dart   # anchor-day, clamp, projections
├── data_storage_test.dart         # repos CRUD, migration, seed idempotency
├── subscription_list_controller_test.dart  # controller unit (DB ffi thật)
├── dashboard_controller_test.dart # controller unit
├── m1_widget_test.dart            # onboarding gate, theme, empty, a11y
├── m1_crud_widget_test.dart       # add/edit/delete/search flows + categories
├── fakes.dart                     # Fake repositories (in-memory)
├── widget_harness.dart            # WidgetHarness (ProviderScope with fakes)
├── m1_support.dart                # TestDb (sqflite_common_ffi in-memory)
└── widget_test.dart               # smoke test
```

## Roadmap (OpenSpec changes)

| Milestone | Change | Trạng thái |
| --- | --- | --- |
| M0 | `subtrack-core-engine` (Money, Billing, storage, repos) | ✅ 23/23 tasks, đã review |
| M1 | `subtrack-core-ux` (onboarding, dashboard, CRUD UI, categories, theme) | ✅ Hoàn thành |
| M2 | `subtrack-platform-store` (notifications, backup, IAP, i18n, privacy) | ✅ Hoàn thành (116/116) |
| M2.5 | `subtrack-decision-engine` (brief, queue, savings, calendar, price-history, lifecycle) | ✅ Hoàn thành (159/159) |
| — | Storage platform split (web localStorage) | ✅ (2026-08-10) |
| — | `subtrack-guidance` (in-app guidance + review bugfixes) | ✅ (2026-08-12, retrospective) |
| — | Platform config (targetSdk 36, network_security_config, package `com.hoangsoft.subtrack`) | ✅ (2026-08-11/15) |

## Quyết định quan trọng (ADR-style tóm tắt)

1. **Tiền = int minor units, không bao giờ `double`** (spec §2.1) — mọi tính toán
   tiền chính xác tuyệt đối; format chỉ ở UI boundary.
2. **Ngày = calendar date local midnight, lưu `YYYY-MM-DD`** — không UTC, không
   shift múi giờ (spec §2.5).
3. **Billing theo anchor-day**: fixed cycles (MONTHLY/QUARTERLY/YEARLY) giữ
   `billingAnchorDay`, CUSTOM = start + n×interval; WEEKLY không cần anchor.
4. **Settings qua bảng `app_settings`** (M0) — **không** shared_preferences.
5. **Riverpod plain (`AsyncNotifier`) thay vì codegen** — tránh build_runner
   pipeline; vẫn đúng stack Riverpod + Feature-First.
6. **Widget tests dùng in-memory fakes** (không sqflite) — sqflite không chạy
   được trong fake-async zone của `testWidgets`; controller tests dùng ffi thật.
7. **`reminder_days_before` lệch so với SQL plan gốc** — column đã thêm vào schema
   (khớp Dart model); ghi chú lệch trong design.md + spec data-storage.
8. **AdMob là SDK mạng bên thứ ba DUY NHẤT (amendment 2026-08-09, user duyệt)** —
   banner adaptive đáy tab + interstitial hiếm (mỗi 5 lần thêm) ở **free tier**, quảng
   cáo **không cá nhân hóa** (`npa=1`, không ATT/IDFA); Pro (Lifetime) xóa toàn bộ ads.
   Spec privacy-compliance đã sửa theo; copy About + paywall + privacy labels đã cập nhật.
   2026-08-11: đã thay bằng ID AdMob thật (app `ca-app-pub-6917313063209470~5291822252`, package
   `com.hoangsoft.subtrack` từ 2026-08-15; ban đầu `com.subguard.app`) — AndroidManifest + Info.plist + ads_config.dart; rewarded ID lưu sẵn, chưa dùng.
9. **Guidance state persist qua bảng `app_settings`** (rule #8) — `guidance.steps`/`guidance.tours`
   comma-joined, không thêm shared_preferences; tour show-once theo seen-tour-ids (2026-08-12).
10. **Monthly Cost = monthly-equivalent mọi cycle** (`yearlyTotal ~/ 12`) — không chỉ cycle
    monthly (fix review 2026-08-12); formatDate locale-aware (VI dd/MM).
