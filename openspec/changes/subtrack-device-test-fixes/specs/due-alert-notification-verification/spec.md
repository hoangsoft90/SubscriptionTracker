## Purpose

Records the device-verified behavior of the once-per-day due-alert dialog and the local-notification scheduler (verified 2026-08-15 on a Pixel 3a running the debug APK built from the due-alert change), so future changes do not silently regress the delivery contract.

## ADDED Requirements

### Requirement: Due-alert dialog appears once per day with the right items
When the app launches and at least one ACTIVE subscription renews today or tomorrow, or has a trial ending within 3 days, the due-alert dialog SHALL appear exactly once per calendar day, listing those HIGH-priority subscriptions with their reason ("{name} renews today / tomorrow", "{name} — trial ends in N day(s)").

#### Scenario: First launch after adding a subscription due today
- **WHEN** a subscription is added with next billing date = today and the app is relaunched the same day (dialog never shown today)
- **THEN** the dialog appears with the subscription listed as "renews today", and after dismissal the `dueAlertLastShown` setting holds today's date so it will not reappear until tomorrow

#### Scenario: Multiple renewals today
- **WHEN** two ACTIVE subscriptions both renew today and the app is relaunched
- **THEN** the dialog lists both, each with a "renews today" reason (verified on-device with Netflix + YouTube)

### Requirement: Reminders are OS-alarm delivered on the billing day at 09:00
Every ACTIVE subscription with a billing occurrence inside the 14-day horizon SHALL have a scheduled local notification at 09:00 local time on its billing day, registered as an OS `RTC_WAKEUP` alarm targeting the flutter_local_notifications `ScheduledNotificationReceiver` — delivery does not depend on the app being open.

#### Scenario: Subscription due tomorrow schedules a reminder
- **WHEN** a subscription's next billing date is tomorrow and reconcile runs (app open / data change)
- **THEN** the scheduler state (`notifScheduledIds`) contains the reminder id and `dumpsys alarm` shows `RTC_WAKEUP origWhen=<billing day> 09:00:00` for `com.hoangsoft.subtrack/com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver` (verified on-device with Netflix → 2026-08-16 09:00, id `1537038242`)

### Requirement: No reminder is scheduled for an already-passed 09:00 today
A subscription whose billing day is today, after 09:00 has already passed, SHALL NOT schedule a reminder for that day (the trigger is skipped) and SHALL NOT schedule the next occurrence when it falls outside the 14-day horizon — no nagging after the fact.

#### Scenario: Renewal today after the reminder hour
- **WHEN** a subscription renews today at 14:00 local time (09:00 already passed) and reconcile runs
- **THEN** no reminder is scheduled for today; the next occurrence (next month) is outside the horizon so `notifScheduledIds` stays empty for that subscription
