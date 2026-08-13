## Why

M0/M1 give SubTrack a working local tracking app. M2 makes it a shippable, store-ready product: reliable renewal/trial notifications, safe backup & transfer, bilingual EN/VI, and a privacy-consistent one-time Pro purchase — plus the Definition-of-Done pass and store compliance that let it actually launch (see locked spec §2.10, §8, §9).

## What Changes

- Notification engine: deterministic IDs, `NotificationScheduler.reconcile()` (buffer ≤ 50 on iOS), permission requested only right after the first subscription is added, timezone-change re-reconcile on app open.
- Trial Shield: two notifications per trial (2 days before + on the day) scheduled by `trialEndDate` (independent of `nextBillingDate`), skipped when the trial is over.
- Backup & Transfer: versioned JSON export/import with schema validation, import preview, Merge (skip duplicate IDs) vs Replace All, share-sheet export for device transfer. SQLite internal migrations stay on `PRAGMA user_version`.
- i18n EN + VI (preset names by key; user-entered subscription names never translated).
- IAP: one-time Lifetime Pro via `in_app_purchase` (StoreKit 2 / Play Billing 6+), purchase + offline restore + entitlement check; free-tier slots counted from ACTIVE + PENDING_CANCELLATION (M2.5), banner at #9–10, hard block once 11+ exist (see iap spec amendment).
- Store compliance: no analytics/crash SDKs, network monitor shows 0 outbound requests, privacy labels match UI; Definition of Done checklist (spec §2.10) passes 100%.

## Capabilities

### New Capabilities

- `notifications`: deterministic scheduling, reconcile(), permission timing, Trial Shield events, timezone-change handling.
- `backup`: versioned JSON export/import, preview, Merge/Replace, transfer via share sheet, validation of schema version.
- `iap`: Lifetime Pro entitlement, purchase/restore offline, paywall gating by subscription count.
- `localization`: EN/VI language switching; user data never localized.
- `privacy-compliance`: no-tracking guarantee, zero outbound network behavior, store privacy labels aligned with UI.

### Modified Capabilities

- (none — no requirement changes to M0/M1 capabilities)

## Impact

- **Code**: new `lib/core/notifications/` (scheduler), `lib/features/backup/` (export/import/preview), `lib/features/paywall/`, `lib/core/l10n/` (EN/VI), platform config (Android manifest POST_NOTIFICATIONS, iOS entitlements).
- **Depends on**: M0 (repositories/schema/migrations), M1 (flows, keys scaffold, settings).
- **Dependencies**: `flutter_local_notifications`, `in_app_purchase`, `intl` (full), `path_provider`, `share_plus`, `timezone` (if needed by scheduler); `workmanager` on Android only for post-reboot reschedule.
- **Tests**: scheduler unit tests (deterministic ID, cancel-old-ID on edit/delete, ≤50 buffer), backup round-trip + merge/replace, IAP entitlement offline, i18n switch tests, privacy network test (0 outbound), full DoD checklist.
- **Privacy**: FORBIDDEN SDKs (Firebase Analytics/Crashlytics, Sentry, PostHog, Amplitude, Mixpanel, RECEIVE_SMS) must not appear — with the sole documented exception of Google AdMob (`google_mobile_ads`, non-personalized banner + rare interstitial, free tier only, Pro removes ads; user-approved amendment 2026-08-09, see `privacy-compliance` spec amendment); store wording "No in-app analytics or tracking SDK" (ads disclosed).
