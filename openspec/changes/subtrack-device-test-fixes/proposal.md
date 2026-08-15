## Why

With the debug APK containing the due-alert dialog and `enable_ads=false` installed on a real device (Pixel 3a), the developer asked to verify the notification + due-alert dialog end-to-end: create a subscription that is about to expire and confirm the alert dialog appears and the reminder notification is scheduled.

Testing on the real device surfaced one genuine UI bug that unit/widget tests had not caught: the Home "Today" card displayed "You're clear" while two subscriptions were renewing **today** — the `clear` computation ignored due-today events, and the card had no way to render a renewal that happens today.

## What Changes

- **Device verification (no code change required)** — created a real "Netflix" subscription (15.49 USD, monthly, next billing = today, via the actual add form driven over adb). On app relaunch the **due-alert dialog** appeared listing Netflix + YouTube as "renews today" (title "Subscriptions due soon", OK / View all / Dismiss), and the once-per-day gate (`dueAlertLastShown`) was persisted. Verified the **notification pipeline**: editing Netflix's next billing to tomorrow (08-16) triggered reconcile → `notifScheduledIds=[1537038242]` + an OS `RTC_WAKEUP` alarm at 2026-08-16 09:00 → `ScheduledNotificationReceiver` (delivery fires tomorrow 09:00 with sound, independent of app open state).
- **Documented-by-design behavior** — a subscription due *today* whose 09:00 reminder already passed schedules nothing: the scheduler skips past trigger times and the next occurrence falls outside the 14-day horizon (no nagging after the fact).
- **Home Today card fix** — `TodayBriefService.clear` now includes `!hasEventToday`, a new `dueToday` field exposes subscriptions billing today, and the `_TodayCard` renders a "Next: {name} — in today ({date})" row per due-today subscription. A renewal today can no longer read "You're clear".

## Capabilities

### New Capabilities

- `due-alert-notification-verification`: device-proven behavior of the once-per-day due-alert dialog and the local-notification scheduler — dialog appears on relaunch for renewals today/tomorrow and trials ≤3 days; reminders are OS-alarm delivered at 09:00 on the billing day; due-today-after-9am subscriptions intentionally schedule nothing (skip past trigger, next occurrence outside 14-day horizon).
- `today-card-due-today`: the Home Today card surfaces subscriptions that renew today (per-row "renews today" line) and never shows "You're clear" while any charge/trial event happens today.

### Modified Capabilities

- (none — `openspec/specs/` is empty in this repo; all delta specs live in change directories.)

## Impact

- **Code**: `lib/features/decision/today_brief.dart` (`dueToday` field + `clear` includes `!hasEventToday`), `lib/features/dashboard/presentation/home_screen.dart` (`_TodayCard` renders due-today rows via `_NextRenewalRow(days: 0)`).
- **Schema**: none.
- **Dependencies**: none.
- **Tests**: `test/decision_engine_test.dart` (due-today → not clear + `dueToday` populated, excludes other-day subs), `test/decision_engine_widget_test.dart` (new widget test: renewal today shows the sub, never the clear message). `flutter analyze` 0 issues, `flutter test` **258/258 pass**.
- **External**: debug APK build triggered for commit `cae8c8e` (GH Actions "Build Debug APK"); notification for Netflix scheduled for 2026-08-16 09:00 to be confirmed on the device.
