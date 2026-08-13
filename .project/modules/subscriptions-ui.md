# Module: Subscriptions UI (CRUD)

**Files**: `lib/features/subscriptions/presentation/` · **Spec**: M1 subscriptions
capability · **Milestone**: M1

## Screens

### `SubscriptionListScreen`
- AppBar title, search TextField (case-insensitive query), status filter chips
  (All/Active/Cancelled/Archived), sort menu (name/amount/next billing).
- Cards: emoji avatar, name + TrialBadge nếu active trial, next date, MoneyText,
  StatusChip. FAB → `/subscriptions/add`.
- Empty state (không kết quả → "No matches"; chưa có → CTA add).
- Exports `isTrialActive`, `formatDate`, `TrialBadge`, `StatusChip` (dùng lại ở
  detail/dashboard).

### `SubscriptionAddEditScreen` (add + edit chung)
- Fields: name, amount (Money.parse theo decimals, validator), cycle dropdown
  (+ custom interval), start/next billing dates, "Free trial?" toggle (trialEnd
  độc lập với nextBilling), cancellation URL (validate scheme), notes.
- Edit mode: prefill, giữ created_at/status, `billingAnchorDay = startDate.day`.
- Save → `notifier.add` / `updateSubscription` → `context.pop()`.

### `SubscriptionDetailScreen`
- Toàn bộ fields, status actions (cancel/archive/activate/unarchive),
  delete với confirm dialog (cancel giữ nguyên; confirm xóa + pop).
- Edit icon → `/subscriptions/:id/edit`.

## Pattern

- Navigation bằng path literals (`context.push(...)`); route names trong `AppRoutes`.
- All user-facing text qua `AppStrings`; user data không localize.

## Test

`test/m1_crud_widget_test.dart`: add flow (FAB→form→save→list), edit preserves
untouched fields, delete confirm (cancel giữ / confirm xóa → empty), search
case-insensitive. `test/subscription_list_controller_test.dart`: logic-level.
