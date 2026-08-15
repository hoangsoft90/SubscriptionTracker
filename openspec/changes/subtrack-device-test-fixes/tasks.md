> Retrospective change: the implementation below is already shipped (2026-08-15). Tasks are recorded as completed against the live codebase; verification numbers reflect the final state.

## 1. Device test — create expiring subscription + verify dialog & notification

- [x] 1.1 Confirmed device: Pixel 3a (sargo), Android 13, wireless adb, package `com.hoangsoft.subtrack` installed and running; existing data: "YouTube" 25.00 USD MONTHLY renewing 08-15 (today); `app_settings` had no `dueAlertLastShown` yet; `notifScheduledIds=[]`
- [x] 1.2 Added a real subscription via the actual add form driven over adb (FAB → name "Netflix" → amount "15.49" → Save; next billing defaulted to today 08-15) — list showed "Netflix · Next: 08/15 · 15.49 USD · Active" immediately
- [x] 1.3 Force-stopped + relaunched the app → **due-alert dialog appeared** with title "Subscriptions due soon", items "📦 Netflix — Netflix renews today" + "📦 YouTube — YouTube renews today", buttons OK / View all / Dismiss (screenshot `/tmp/due_alert_dialog.png`); after OK, `dueAlertLastShown=2026-08-15` persisted (once-per-day gate)
- [x] 1.4 Edited Netflix next billing → 08-16 (tomorrow) via detail → Edit → date picker → Save; reconcile fired → `notifScheduledIds=[1537038242]` and `dumpsys alarm` showed `RTC_WAKEUP origWhen=2026-08-16 09:00:00 → com.hoangsoft.subtrack/com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver` — full scheduling pipeline verified end-to-end
- [x] 1.5 Documented by-design behavior: a due-today sub whose 09:00 has passed schedules nothing (skip past trigger; next occurrence outside 14-day horizon) — verified via scheduler code, not a bug

## 2. Today-card fix (bug found during device test)

- [x] 2.1 Root cause: `TodayBriefService` — `clear = nextRenewal == null && trialEnding == null` ignored due-today events; `dueToday` was only aggregated into the `hasEventToday` bool and the card never rendered today's renewals (nextRenewal is strictly after today)
- [x] 2.2 `lib/features/decision/today_brief.dart`: added `dueToday: List<Subscription>` field; `clear` now = `nextRenewal == null && trialEnding == null && !hasEventToday`
- [x] 2.3 `lib/features/dashboard/presentation/home_screen.dart` `_TodayCard`: renders `_NextRenewalRow(days: 0)` ("Next: {name} — in today ({date})" + amount) per `dueToday` entry, above the next-renewal row
- [x] 2.4 Tests: `test/decision_engine_test.dart` — "billing today" test extended (clear=false, `dueToday` contains the today sub, excludes a later-due sub); `test/decision_engine_widget_test.dart` — new widget test "renewal today → shows the sub, never the clear message" (pumps `SubTrackApp`, asserts "Next: Netflix" present and "You're clear" absent). Note: first draft had a Dart syntax error from an apostrophe in the single-quoted test name — renamed to drop the apostrophe

## 3. Verification

- [x] 3.1 `flutter analyze` — **No issues found**
- [x] 3.2 `flutter test` — **258/258 pass** (257 prior + 1 new widget test)
- [x] 3.3 No secrets in the diff before commit (grep for ghp_/api key/password — clean)
- [x] 3.4 Commit `cae8c8e` pushed to `main` (6 files: 2 lib, 2 test, 2 `.project/`) — GH Actions "Build Debug APK" run triggered for the new head (`in_progress` at time of writing); reminder for Netflix left scheduled at 2026-08-16 09:00 to confirm on the device
- [x] 3.5 `openspec validate --changes` — this change + prior changes pass
- [x] 3.6 Updated `.project/state.md` (test count 258/258, session note, todo #3 marked done for dialog/notification verification) and `.project/working.md` (new "Device test notification + dialog → Today-card fix" section) per project conventions
