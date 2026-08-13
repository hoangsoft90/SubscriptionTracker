# State (trạng thái hiện tại)

> Cập nhật lần cuối: 2026-08-12 (phiên: Guidance feature + Review fixes + OpenSpec).
> File này đổi thường xuyên — dùng ISO date `YYYY-MM-DD` cho mọi mục.
> Chi tiết theo ngày ở `working.md`; quy tắc code ở `ai-rules.md`.

## Milestone status

| Milestone | Change | Tasks | Trạng thái |
| --- | --- | --- | --- |
| M0 | `subtrack-core-engine` | 23/23 | ✅ Hoàn thành, đã review |
| M1 | `subtrack-core-ux` | 30 tasks | ✅ Hoàn thành (UI + tests + review) |
| M2 | `subtrack-platform-store` | 116/116 tests | ✅ Hoàn thành (notifications, backup, IAP, i18n, privacy) |
| M2.5 | `subtrack-decision-engine` | 30 tasks | ✅ Hoàn thành (brief, queue, savings, calendar, price-history, lifecycle) |
| — | Storage platform split (web localStorage) | 175/175 tests | ✅ Hoàn thành (2026-08-10) |
| — | Guidance + Review fixes | `subtrack-guidance` (mới) | ✅ Hoàn thành (2026-08-12) |
| — | Platform config (targetSdk 36, network_security_config, package) | — | ✅ Hoàn thành (2026-08-11/12) |

## Test status (2026-08-13)

- **216/216 tests pass** ✓ (203 + 8 `ads_test` + 5 nav mới)
- `flutter analyze` — **No issues found** ✓
- GH Actions `build-apk.yml`: APK + AAB build success (run `31662555768`) — artifact `subtrack-release-apk` (32MB) + `subtrack-release-aab` (66.8MB).

Phân bổ tests (chính):
- Core: `money_test`, `billing_calculator_test`, `data_storage_test`, `local_storage_repository_test` (web storage), `backup_test`, `notifications_test`, `l10n_test`, `ads_test` (8: cooldown/frequency policy + test-ads mode)
- Nav: `navigation_deep_link_test` (10: not-found recovery, /calendar /paywall deep link Home, /more/categories, onboarding restore, **root path → Home, /more/settings /more/backup /subscriptions/add /subscriptions/:id/edit back**)
- Controller: `subscription_list_controller_test`, `dashboard_controller_test`, `free_tier_test`, `decision_engine_test`
- Widget: `m1_widget_test`, `m1_crud_widget_test`, `m1_support`/`widget_harness`/`fakes`, `decision_engine_widget_test`, `ux_bugfix_widget_test`, `navigation_deep_link_test`, `guidance_test` (19), `subscription_detail_test` (2)
- `integration_test/`: `device_ux_test`, `privacy_network_test`, `probe_test`

## Todo mở (next steps)

1. [x] **Commit** toàn bộ code M0→nay — **đã push 2026-08-13** lên
      `github.com/hoangsoft90/SubscriptionTracker` (commit `a746af6`, branch `main`).
2. [ ] Manual device tests còn lại (đã ghi trong platform-store tasks):
      backup reinstall restore (2.6), IAP sandbox (3.5), privacy network on-device (5.2).
3. [ ] Manual walkthrough M1 (task 7.3) — add <25s, dashboard totals khớp list.
4. [ ] OCR (open-code-review) đang lỗi 401 config — cần user sửa; fallback hiện
      dùng code-reviewer + review mặc định.
5. [ ] Sync/archive 4 OpenSpec change cũ (core-engine, core-ux, platform-store,
      decision-engine) vào `openspec/specs/` khi có nhu cầu.
6. [ ] Fix MEDIUM còn lại từ review (đã liệt kê, chưa làm): #8 monthlyByCurrency
      chưa dùng ở Home, #9 merge FK edge case, #10 interstitial preload hết hạn,
      #11 Money.parse VND "12.5" → 125 (behavior có chủ đích).
7. [ ] (nếu publish store) Thêm signing config release thật vào
      `android/app/build.gradle.kts` — hiện release dùng debug signing (APK CI để test nội bộ).

## Ghi chú phiên gần đây

- **2026-08-12**: In-app Guidance & User Onboarding — feature `lib/features/guidance/`
  (FeatureBadge, SpotlightOverlay + tooltip_geometry, DisabledStateHelper, GuidanceHost,
  GuidanceController persist `app_settings`), wire Home (tour 2 steps + "New" badge) +
  Subscriptions FAB (DisabledStateHelper khi free-tier hard block). L10n EN+VI.
  **Review toàn bộ code** (3 reviewer + verify trực tiếp, loại false positives) →
  fix 7 lỗi HIGH/MEDIUM: FK crash Replace All (real sqlite test), Monthly Cost
  monthly-equivalent, detail hiện tên category, formatDate locale-aware (VI dd/MM),
  import → notification reconcile, lifecycle transition → invalidate UI providers,
  StatusChip ellipsis. **203/203 tests pass**. Tạo OpenSpec change `subtrack-guidance`
  (retrospective, 2 capability: in-app-guidance + review-bugfixes) — validate 5/5.
  Xem `working.md` mục 2026-08-12.
- **2026-08-11**: Package `com.subguard.app` + AdMob ID thật (app
  `ca-app-pub-6917313063209470~5291822252`; banner/interstitial trong `ads_config.dart`,
  App ID AndroidManifest + Info.plist). Test device thật: init OK, banner "No fill"
  (device chưa đăng ký test device — không phải lỗi cấu hình).
- **2026-08-10**: Nav hardening (categories → GoRouter, error recovery page, deep-link
  Home nút, PopScope), HTTP cleartext release APK, SafeArea màn full-screen,
  web bootstrap `flutter_bootstrap.js` (semanticsEnabled). M2.5 decision-engine toàn
  bộ (migration v2 + lifecycle + queue + brief + savings + calendar + price-history)
  + storage platform split (web localStorage, 175/175).
- **2026-08-09**: Fix 4 bug UI + thêm AdMob (amendment privacy user duyệt) — banner đáy
  + interstitial hiếm, free tier, non-personalized, Pro xóa ads; thêm
  `test/ux_bugfix_widget_test.dart`.
- **2026-08-08**: Hoàn thành M2 platform-store (notifications, backup, IAP, i18n,
  privacy; 116/116) + M1 UI toàn bộ + fix 2 production bugs do widget tests phát hiện
  (`billingCycle.name` crash → `dbValue`; `dynamic subscription` → `Subscription`).
  Cài 22 skills `flutter/agent-plugins` vào `.agents/skills/`.
