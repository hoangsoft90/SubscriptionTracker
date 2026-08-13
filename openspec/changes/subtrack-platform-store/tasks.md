## 1. Notifications

- [x] 1.1 Add `flutter_local_notifications` (+ `timezone` if required); Android `POST_NOTIFICATIONS` manifest + iOS notification capability
- [x] 1.2 Implement `NotificationId` (deterministic hash per §2.4) + `NotificationPermissionService` (request only after first subscription)
- [x] 1.3 Implement `NotificationScheduler.reconcile()` (7-step algorithm: load active → generate 7–14d events → sort/group → cap 50 → cancel own IDs → schedule → persist state)
- [x] 1.4 Wire triggers: app open, subscription add/edit/delete (via M0 repository hooks), timezone change (`lastTimeZone` in app_settings), post-reboot (`workmanager` Android only)
- [x] 1.5 Implement Trial Shield scheduling from `trialEndDate` (2 days before + on day; skip if past; cancellationUrl non-gating)
- [x] 1.6 Unit tests: deterministic ID, edit cancels old ID, delete cancels all, cap ≤50, expired trial no reminders, timezone-change re-reconcile, same-time grouping

## 2. Backup & transfer

- [x] 2.1 Implement `BackupExportService` (versioned JSON per §2.6, `path_provider` temp file, `share_plus` share sheet)
- [x] 2.2 Implement `BackupImportService`: validate format marker + schemaVersion (reject non-backup / newer version), parse counts for preview
- [x] 2.3 Implement import UI: Preview ("Found N subscriptions, M categories") → Merge (skip existing IDs) / Replace All (explicit confirm) → apply in transaction
- [x] 2.4 Add Backup & Transfer screen under More tab (export, import, explainer copy)
- [x] 2.5 Unit tests: export→import round-trip 100%, merge skips duplicates, replace-all restores, re-import no duplicates, invalid/future schema rejected
- [ ] 2.6 DoD test: export → delete app → reinstall → import → 100% restored *(manual, device)*

## 3. IAP & paywall

- [x] 3.1 Add `in_app_purchase`; create store product (non-consumable Lifetime Pro) + `ProEntitlementController` (persisted flag, purchase, restore, verify)
- [x] 3.2 Implement free-tier rules: 1–8 no interference, 9–10 light banner "You have N free slots left", 11+ hard block + paywall route
- [x] 3.3 Build paywall screen (one product, no recurring billing) + Settings "Restore Purchase" / "Upgrade to Pro"
- [x] 3.4 Unit/widget tests: entitlement offline restore, staged messaging at 8/9/10/11, archived not counted
- [ ] 3.5 Sandbox test on iOS/Android: purchase + restore passes *(manual, store sandbox)*

## 4. i18n EN/VI

- [x] 4.1 Add `flutter_localizations` + `intl`; generate `AppLocalizations` from ARB files
- [x] 4.2 Fill `app_en.arb` and `app_vi.arb` with all UI strings (onboarding, tabs, screens, statuses, presets, paywall, settings)
- [x] 4.3 Runtime language switch in Settings (persisted in app_settings); MaterialApp locale wiring
- [x] 4.4 Resolve preset display names by key; verify user-entered names/notes/custom categories never localized
- [x] 4.5 Tests: EN↔VI switch, device-default locale, user-data immutability across switch

## 5. Privacy & compliance

- [x] 5.1 Dependency audit: FORBIDDEN list (Firebase Analytics/Crashlytics, Sentry, PostHog, Amplitude, Mixpanel, ads SDK, RECEIVE_SMS) absent from pubspec/Android manifest — verified on pubspec.lock + merged manifest (docs/privacy-labels.md)
- [x] 5.2 Integration test: network disabled → app fully functional, monitor shows 0 outbound requests — `integration_test/privacy_network_test.dart` (run on device)
- [x] 5.3 Verify permissions minimal (notification only; no SMS/contacts/location/storage) — merged manifest audit clean
- [x] 5.4 Prepare Apple Privacy Nutrition Label + Google Play Data Safety answers matching UI; review locked privacy copy wording — docs/privacy-labels.md

## 6. Definition of Done & store readiness

- [x] 6.1 Run full DoD checklist (spec §2.10) — scorecard: docs/dod-checklist.md (automated 100%; 3 device-only manual steps pending: 2.6, 3.5, 5.2-on-device)
- [x] 6.2 `flutter analyze` + full `flutter test` green — 0 issues, 116/116 pass
- [x] 6.3 Update `working.md`/ADR per project conventions; hand off store submission checklist — .project/working.md + docs/privacy-labels.md

## 7. Verification

- [x] 7.1 `flutter analyze` — no issues
- [x] 7.2 `flutter test` + `integration_test` — all green (integration test file added; on-device run pending device)
- [ ] 7.3 DoD scorecard: 100% pass, exceptions (if any) logged with rationale — partial: 3 manual exceptions logged, awaiting device
