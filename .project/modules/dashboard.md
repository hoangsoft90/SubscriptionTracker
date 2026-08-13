# Module: Dashboard (Home)

**Files**: `lib/features/dashboard/` · **Spec**: M1 dashboard capability · **Milestone**: M1

## Trách nhiệm

"Cost Shock" màn hình chính — cho user thấy chi phí recurring thực tế, ngay lập
tức (chống lý do uninstall #1: "app chỉ CRUD").

## `DashboardController` (application)

`DashboardState{active, upcoming, topThree}`:

- `active` = status active (exclude cancelled/archived).
- `upcoming` = renewal trong 7 ngày tới (>= now, < now+7d), sort theo ngày.
- `topThree` = top 3 active theo amount trong **primary currency**; fallback USD
  khi settings chưa load (`ref.watch` → rebuild khi resolve).
- `monthlyTotal(currency)` — chỉ monthly cycle; `yearlyTotal` — projection theo
  cycle (int-exact); `fiveYearTotal` = yearly×5; `monthlyByCurrency()` group.

## `HomeScreen` (presentation)

- AppBar "SubTrack"; empty state (chưa có sub) với CTA → add.
- `_CostCard`: Monthly headline (displaySmall, primary), Yearly, "5-Year Cost at
  Current Prices" (secondary).
- `_SectionHeader` Upcoming (7 days) + danh sách `_UpcomingTile`; "Top 3 most
  expensive" + `_TopThreeTile` (trial badge nếu active trial).
- RefreshIndicator.

## ⚠️ Bug đã fix (2026-08-08)

- `_TopThreeTile` từng gọi `subscription.billingCycle.name` → runtime crash
  (BillingCycle không có getter `name`). Đã sửa thành `dbValue` và đổi
  `dynamic subscription` → `Subscription` type (để analyze bắt lỗi tương tự).

## Test

`test/dashboard_controller_test.dart` (5): totals exclude cancelled/archived,
monthly/yearly int-exact, 5-year, upcoming 7d, top-3 ranking. Widget render:
`m1_widget_test.dart` (empty state) — có thể bổ sung widget test chi tiết hơn.
