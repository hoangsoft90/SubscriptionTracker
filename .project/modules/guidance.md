# Module: In-app Guidance & User Onboarding

> Shipped 2026-08-12. OpenSpec change: `subtrack-guidance` (capability `in-app-guidance`).
> Quy tắc: persist qua bảng `app_settings` (rule #8), không shared_preferences.

## Trách nhiệm

Hướng dẫn user mới trên chính giao diện: badge "New" cho tính năng chưa xem,
tour spotlight từng bước (Step 1 → 2 → Finish), và giải thích ngắn khi một
control bị disabled (vì sao + cách unlock). Tất cả **show-once** — không spam.

## File quan trọng (`lib/features/guidance/`)

| Layer | File | Vai trò |
| --- | --- | --- |
| domain | `guidance_step.dart` | Pure Dart: `GuidanceStep`, `GuidancePlacement`, `GuidanceLabels`, `GuidanceState` — không import Flutter |
| application | `guidance_controller.dart` | `AsyncNotifier`: đọc/ghi `guidance.steps` + `guidance.tours` (comma-joined) qua `SettingsRepository` |
| presentation | `feature_badge.dart` | Dot/label "New" overlay góc trên-phải, `visible` từ state |
| presentation | `tooltip_geometry.dart` | Pure function vị trí tooltip (dưới → flip trên → clamp màn hình) |
| presentation | `spotlight_overlay.dart` | Dim + khoét lỗ spotlight (`CustomPaint`), tooltip card + arrow, Skip/Next/Done, backdrop tap |
| presentation | `disabled_state_helper.dart` | Wrap control disabled → dialog lý do + unlock + nút hành động |
| presentation | `guidance_host.dart` | Orchestrator: `GlobalKey` targets, đo rect, chạy tuần tự steps, lifecycle overlay |

## API chính (GuidanceController)

- `hasCompletedStep(stepId)` — badge ẩn khi step đã xem (sync).
- `shouldShowTour(tourId)` — tour chỉ chạy 1 lần (seen-tour-ids).
- `completeStep(stepId, {tourId, tourStepIds})` — ghi step; khi đủ steps của tour
  → tự mark tour seen (một đường ghi, badge + show-once cùng rơi ra).
- Skip = `completeStep` từng step còn lại → badge sạch + tour seen.

## Pattern quan trọng

- **Trigger show-once**: tour được render mặc định (GuidanceHost wrap body),
  controller quyết định hiển thị step theo state đã persist — không cần nút bật.
- **Positioning testable**: geometry tách thành pure function
  (`tooltip_geometry.dart`) — unit test không cần widget tree.
- **Overlay self-contained**: `SpotlightOverlay` tự bọc `Stack` (không phụ thuộc
  parent có Stack) — tái sử dụng ở mọi nơi; card + arrow cùng Stack để hit-test
  đúng, backdrop absorb tap để advance.
- **Wire demo**: Home — tour 2 steps (Cost card → View calendar) + FeatureBadge
  "New" trên calendar card; Subscriptions — FAB bọc `DisabledStateHelper` khi
  free-tier hard block (11+), nút Unlock Pro → `/paywall`.

## Test

- `test/guidance_test.dart` (19): tooltip geometry, controller persist/show-once,
  FeatureBadge, DisabledStateHelper dialog, SpotlightOverlay, tour flow,
  skip-clears-steps (badge hết dính).
- Lưu ý: tour Home chỉ chạy khi có ≥1 subscription active (target cards tồn tại);
  empty state không hiện tour, sẽ thử lại khi có data (intended).
