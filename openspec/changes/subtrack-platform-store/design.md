## Context

M0 gave us the domain core and repositories; M1 gave us the app surface with key scaffolds and settings. M2 adds the platform-facing layer: local notifications, versioned backup/transfer, i18n, IAP and privacy compliance (see proposal.md — Why). All decisions must honor the locked spec's MUST FIX items (§2.4 notifications, §2.6 backup, §2.7/§2.8 IAP stance, §9 privacy).

## Goals / Non-Goals

**Goals:**
- Deterministic, reconcile-based notification scheduling with iOS ≤50 buffer, correct permission timing, Trial Shield on `trialEndDate`, timezone re-reconcile.
- Versioned JSON backup with preview, Merge/Replace, share-based transfer, validated schema.
- EN/VI localization with user data never localized.
- One-time Lifetime Pro IAP (purchase/restore/entitlement) with staged free-tier paywall, all offline-capable.
- Privacy compliance: zero outbound requests, no analytics/crash SDKs, store labels matching UI, DoD pass.

**Non-Goals:**
- No encrypted backup / app lock / PIN / biometric (P1).
- No CSV import/export, no OCR, no widget (P1).
- No cloud sync, no account, no server, no phone-to-phone protocol.
- No auto-renewing subscription product.

## Decisions

### D1: flutter_local_notifications + deterministic ID scheme
ID = `FNV-1a('$subscriptionId|${triggerAt.toIso8601String()}|${reminderType.name}') % 2147483647` — components joined with `|` separators; `triggerAt` is the scheduled delivery time (billing/trial date at the reminder hour). FNV-1a is used because Dart does not guarantee `String.hashCode` stability across VM versions. `NotificationScheduler` is a single class with `reconcile()` implementing the 7-step algorithm from the spec; state persisted in `app_settings` (e.g. `lastTimeZone`, scheduler state JSON).
- **Alternatives considered:** random IDs (rejected — cannot cancel reliably on edit/delete); per-row stored IDs (rejected — extra column, ID is derivable).
- **Rationale:** deterministic IDs make cancel/`cancel(id)` exact; reconcile() is idempotent and testable without the OS.

### D2: Reconcile triggers and reboot handling
Triggers: app open, subscription add/edit/delete, timezone change, post-reboot. Post-reboot on Android via `workmanager` (spec §13 lists it); iOS restores scheduled notifications automatically after reboot (no workmanager needed there).
- **Rationale:** background refresh is explicitly NOT relied upon (spec §2.4); OS delivers directly. Workmanager is Android-only, matching spec's dependency list.

### D3: Permission timing
Request notification permission only after the first subscription is added (at reminder-set moment) via a `NotificationPermissionService` gate. Never at launch/onboarding.
- **Rationale:** spec §2.4 — acceptance rate; also keeps the Privacy Promise step clean of permission prompts.

### D4: Trial Shield vs nextBillingDate decoupling
Trial reminders computed strictly from `trialEndDate` (+2 days / +0 days), guarded by `trialEndDate > now`; `cancellationUrl` is optional and non-gating. Badge rendering (M1) already uses the same rule.
- **Rationale:** spec §2.5 — the two dates are independent by design.

### D5: Backup format & flow
Export writes the §2.6 JSON (format marker, schemaVersion=1, exportedAt, appVersion, settings, categories, subscriptions) via `path_provider` + `share_plus` share sheet. Import: pick file → validate marker + schemaVersion (reject non-backup / newer version) → preview counts → choose Merge (skip existing IDs) or Replace All (with confirm) → apply inside a transaction. Backup `schemaVersion` is data-format versioning; internal SQLite versioning stays on `PRAGMA user_version` (M0) — two independent axes.
- **Alternatives considered:** importing directly without preview (rejected — spec mandates preview; prevents surprise wipes); replace-only (rejected — merge prevents duplicate-loss workflows like re-import).
- **Rationale:** matches §2.6 exactly; transaction guarantees atomicity; JSON keeps the file portable and shareable.

### D6: IAP with in_app_purchase plugin
`in_app_purchase` (StoreKit 2 iOS / Play Billing 6+ Android). A `ProEntitlement` persisted flag + `verifyPurchase` against the store. Restore = platform query; works offline per platform semantics. Free-tier rules: count slot-consuming subscriptions (ACTIVE + PENDING_CANCELLATION per plan2_final §5); 1–8 no UI, 9–10 banner "You have N free slots left", hard block once 11+ already exist + paywall route.
- **Alternatives considered:** revenuecat (rejected — server dependency + analytics; violates privacy posture); local-only unlock (rejected — no entitlement portability, breaks store review).
- **Rationale:** spec §2.8: store is source of truth, no server, restore must work offline. Sandbox testing is a required task.

### D7: i18n with intl + ARB
`flutter_localizations` + `intl`; `AppLocalizations` (EN/VI) generated from ARB files; runtime switch in Settings writes locale to `app_settings`; MaterialApp rebuilds with locale. Preset `displayNameKey` resolves through the same ARB. User-entered strings render as stored.
- **Alternatives considered:** third-party i18n packages (rejected — intl is in the locked stack; ARB is the Flutter-standard).
- **Rationale:** keys scaffolded in M1 slot straight in; generated delegates keep strings type-safe.

### D8: Privacy verification
A `NetworkMonitor`-style test asserts 0 outbound requests with network disabled (integration test on release build); dependency/`pubspec` audit rejects the FORBIDDEN SDK list; store compliance checklist (Apple Privacy Nutrition Label + Google Data Safety) itemized in tasks. Crash: platform built-ins only.
- **Rationale:** spec §9 + DoD — privacy is verifiable, not just claimed.

**Project layout (additions):**
```
lib/
  core/notifications/ (scheduler.dart, permission.dart, ids.dart)
  features/backup/ (export_service.dart, import_service.dart, preview.dart)
  features/paywall/ (paywall_screen.dart, entitlement_controller.dart)
  core/l10n/ (app_en.arb, app_vi.arb, app_localizations*)
android/app/src/main/AndroidManifest.xml (POST_NOTIFICATIONS)
ios/Runner/ (entitlements, notification capability)
test/ (scheduler_test, backup_test, iap_entitlement_test, l10n_test)
integration_test/ (privacy_network_test)
```

## Risks / Trade-offs

- [iOS 64-notification limit] → buffer cap at 50 in reconcile(); unit test asserts the cap.
- [Deterministic hash collisions] → `% 2147483647` per spec; collision risk negligible for realistic counts; cancel targets exact IDs.
- [Import corrupts data] → validate + preview + transaction; Replace All requires explicit confirm; merge skips duplicates (DoD covers re-import).
- [IAP sandbox/store-review friction] → sandbox purchase/restore test is a hard task; entitlement persisted so offline launch stays consistent.
- [Timezone change breaks times] → stored `lastTimeZone` + reconcile on change (spec §4).
- [Analytics SDK sneaks in] → dependency audit task + privacy integration test gate in DoD.

## Migration Plan

Internal schema: no new migrations expected for M2 (backup uses data-format versioning). If the scheduler needs persistence, it uses `app_settings` rows (no schema change). Any schema addition would be a new migration in the M0 runner — none anticipated.

## Open Questions

None — spec is locked. IAP product ID and price ($4.99–$9.99 band) is a store-metadata decision made at submission time, not a spec change.
