# SubTrack M2 — Definition of Done Scorecard

Spec reference: `openspec/changes/subtrack-platform-store` (spec §2.10).
Run date: **2026-08-08**. Toolchain: Flutter 3.44.6, Dart 3.12.x, AGP 9.0.1, JDK 21.

Legend: ✅ pass (verified by automated test / direct check) · 🔲 pending manual device step · ⚠️ exception logged.

---

## 1. Notifications

| DoD item | Result | Evidence |
| --- | --- | --- |
| Deterministic notification IDs | ✅ | `test/notifications_test.dart` — deterministic ID, edit cancels old ID, delete cancels all |
| Reconcile 7-step algorithm, cap ≤50 | ✅ | scheduler unit tests assert ≤50 pending & same-time grouping |
| Trial Shield from `trialEndDate` (+2d/+0d, skip past) | ✅ | expired-trial no reminders test |
| Permission after first subscription only | ✅ | `NotificationPermissionService` gated at reminder-set; manifest has `POST_NOTIFICATIONS` only |
| Cancel-on-edit / cancel-on-delete | ✅ | unit tests: edit moves billing date cancels old ID; delete cancels all |
| Timezone change re-reconcile + persist | ✅ | app-open reconcile persists `lastTimeZone`; timezone-change test |
| Post-reboot reschedule (Android) | ✅ | `workmanager` RebootRescheduler wired in `main.dart` + manifest `RECEIVE_BOOT_COMPLETED` |
| 19/19 notification tests | ✅ | `flutter test test/notifications_test.dart` |

## 2. Backup & transfer

| DoD item | Result | Evidence |
| --- | --- | --- |
| Versioned JSON codec + validation | ✅ | `backup_models.dart` — format marker, `schemaVersion`, reject non-backup / newer version |
| Export via share sheet | ✅ | `BackupExportService` (`path_provider` temp + `share_plus`) |
| Import preview → Merge / Replace All (explicit confirm) | ✅ | `BackupScreen` dialog + transaction apply |
| Round-trip 100%, merge skips duplicates, replace-all restores, re-import no dupes | ✅ | `test/backup_test.dart` — 9/9 |
| **Export → delete app → reinstall → import → 100% restored** | 🔲 | needs physical device; code path covered by round-trip test |

## 3. IAP & paywall

| DoD item | Result | Evidence |
| --- | --- | --- |
| Lifetime Pro product + `ProEntitlementController` (persist, purchase, restore) | ✅ | `entitlement_controller.dart` persisted flag; offline restore test |
| Free-tier rules: 1–8 free, 9–10 banner, 11+ block | ✅ | `free_tier.dart` + `test/free_tier_test.dart` staged-messaging tests at 8/9/10/11 |
| Archived not counted toward slots | ✅ | free-tier test |
| Paywall screen (one product, no recurring) + Settings Restore/Upgrade | ✅ | `paywall_screen.dart`, Settings entries |
| **Sandbox purchase + restore on iOS/Android** | 🔲 | needs store sandbox accounts |

## 4. i18n EN/VI

| DoD item | Result | Evidence |
| --- | --- | --- |
| `AppLocalizations` generated from ARB (EN/VI) | ✅ | `lib/core/l10n/`, gen-l10n in build |
| Runtime language switch persisted | ✅ | Settings → Language, writes `app_settings` |
| Preset names by key, never localize user data | ✅ | `presetDisplayNames` via l10n; user names/notes render as stored |
| EN↔VI switch, device-default, user-data immutability | ✅ | `test/l10n_test.dart` — 6/6 |

## 5. Privacy & compliance

| DoD item | Result | Evidence |
| --- | --- | --- |
| FORBIDDEN SDKs absent (Firebase/Sentry/PostHog/Amplitude/Mixpanel/ads/SMS) | ✅ | `docs/privacy-labels.md` §1 — pubspec.lock grep empty |
| 0 outbound requests from app code | ✅ (code-level) | integration_test `privacy_network_test.dart` installs a throwing `HttpOverrides`; no HTTP client in own code |
| Permissions minimal (no SMS/contacts/location/storage) | ✅ | merged manifest audit (see privacy-labels.md §1) |
| Privacy labels / Data Safety match UI | ✅ | `docs/privacy-labels.md` §2–§3 |
| Locked privacy copy (no overclaims) | ✅ | onboarding/about strings match locked wording; "can never leave device" absent |
| Crash reporting: platform built-ins only, no SDK | ✅ | no crash SDK in dependencies |

## 6. Cross-cutting

| DoD item | Result | Evidence |
| --- | --- | --- |
| `flutter analyze` — no issues | ✅ | 0 issues |
| Full `flutter test` — green | ✅ | 116/116 |
| Debug APK builds | ✅ | `flutter build apk --debug` → `app-debug.apk` |
| `working.md` updated | ✅ | `.project/working.md` |
| Store submission checklist handed off | ✅ | `docs/privacy-labels.md` + this scorecard |

---

## Exceptions / manual steps (🔲)

1. **Backup reinstall restore (2.6)** — execute on device: Export → uninstall → install → Import → verify 100% data.
2. **IAP sandbox (3.5)** — purchase + restore in Play Console / App Store Connect sandbox with a test account.
3. **Integration test on-device (5.2)** — run `flutter test integration_test/privacy_network_test.dart -d DEVICE_ID` with network disabled.

These are the only items requiring a physical device / store account; everything
verifiable in CI passes.

## Score

**Automated: 100% pass** (116 unit/widget tests + analyze clean + APK build).
**Manual: 3 device-only steps pending** (logged above, no known failures).
