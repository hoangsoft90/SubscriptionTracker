# Store Privacy Disclosures — SubTrack

Status: **AMENDED 2026-08-09 — AdMob added** (user-approved privacy override; see `.project/overview.md` decision #8 and the `privacy-compliance` spec amendment). Re-verify answers after any dependency change.

App identity: **SubTrack** — subscription tracker, local-first, no account, no backend.

---

## 1. Dependency & permission audit (verified 2026-08-08)

### FORBIDDEN SDK list — absent from `pubspec.yaml` / `pubspec.lock` / `android/`
Firebase Analytics, Firebase Crashlytics, Sentry, PostHog, Amplitude, Mixpanel,
Google Analytics, Facebook SDK, AppsFlyer → **none present**.

> **AMENDED:** AdMob (`google_mobile_ads ^9.0.0`) is now an **intentional**
> exception — the ONLY third-party network SDK. Ads are non-personalized
> (`npa=1`), free tier only, removed by Lifetime Pro. `pubspec.lock` audit must
> expect `google_mobile_ads` (+ its `webview_flutter` dependency) and reject
> everything else on the forbidden list.

Command used:
```
grep -iE 'firebase|sentry|posthog|amplitude|mixpanel|google_analytics|facebook|admob|appsflyer|crashlytics' pubspec.lock   # empty
```

### Android permissions — merged manifest (debug build, AGP 9)
Only these appear in `build/app/intermediates/merged_manifest/debug/.../AndroidManifest.xml`:

| Permission | Source | Needed for |
| --- | --- | --- |
| `POST_NOTIFICATIONS` | app | subscription reminders (Android 13+) |
| `VIBRATE`, `WAKE_LOCK` | flutter_local_notifications | notification delivery |
| `RECEIVE_BOOT_COMPLETED` | flutter_local_notifications / workmanager | reschedule reminders after reboot |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SHORT_SERVICE` | flutter_local_notifications | scheduled notification transport |
| `INTERNET`, `ACCESS_NETWORK_STATE` | IAP (Play Billing) + file sharing plugins | store purchase/restore, share sheet |
| `com.android.vending.BILLING` | in_app_purchase | Pro lifetime purchase |

**Absent:** SMS, contacts, location, storage (READ/WRITE_EXTERNAL_STORAGE),
camera, microphone, phone → **none present**.

---

## 2. Apple App Store — Privacy Nutrition Label

| Section | Answer | Rationale |
| --- | --- | --- |
| Data Used to Track You | **No** | no ATT prompt, no IDFA; AdMob serves non-personalized ads (`npa=1`) |
| Data Linked to You | **No** | app has no account, no login, no server |
| Data Not Linked to You | **Yes — Identifiers (Device ID)** | AdMob SDK uses device identifiers for ad delivery/frequency capping |

With AdMob present, the long form is no longer fully "No Data Collected": tick
**Identifiers → Device ID** under "Data Not Linked to You" (non-personalized
ads). Do **not** tick "Data Used to Track You" (no IDFA usage), "User ID", or
"Diagnostics → Crash Data".

**Required privacy-policy URL:** none strictly required when no data is
collected, but publish a short policy at submission time pointing to the
locked copy below (many stores ask anyway).

---

## 3. Google Play — Data Safety form

| Question | Answer |
| --- | --- |
| Does your app collect or share any of the required user data types? | **Yes — Device or other IDs (advertising ID via AdMob)** |
| Is all user data encrypted in transit? | Yes (ad traffic via AdMob SDK) |
| Do you provide a way for users to request data deletion? | N/A — no user account data is stored off-device |
| Permissions declared | `POST_NOTIFICATIONS` only (runtime, requested after first subscription); `INTERNET`/`ACCESS_NETWORK_STATE` (AdMob + IAP) |
| Ads | **Yes — AdMob, non-personalized, free tier only; removed by Pro** |
| Analytics | No |

Data safety section can be left empty — the app transmits nothing.

---

## 4. Locked privacy copy (must match UI)

UI strings in `lib/core/l10n/app_en.arb` / `app_vi.arb`:

- EN: `"Subscription data is stored locally on your device. The app does not require a backend or account."`
- EN (About, amended): `"No in-app analytics or tracking SDK. Non-personalized ads are served by Google AdMob on the free plan — upgrade to Pro to remove them. Subscription data is stored locally on your device."`
- VI (About, amended): `"Không có SDK phân tích hoặc theo dõi trong ứng dụng. Quảng cáo không cá nhân hóa được phân phối bởi Google AdMob ở gói miễn phí — nâng cấp Pro để tắt. Dữ liệu đăng ký được lưu trữ cục bộ trên thiết bị của bạn."`

Rules (per spec privacy-compliance, amended):
- ✅ Allowed wording: "No in-app analytics or tracking SDK", "Non-personalized ads
  are served by Google AdMob on the free plan — upgrade to Pro to remove them",
  "Subscription data is stored locally on your device", "The app does not require
  a backend or account".
- 🚫 **Forbidden overclaims**: "data can never leave your device", "100% private",
  "zero data ever", "no ads" (now false on the free tier) — do not add these
  anywhere (marketing, store description, UI).

If a marketing line is added later, run it past this list first.

---

## 5. Store description alignment

Play Store / App Store description should say:

> SubTrack keeps your subscription data **on your device**. No account, no
> cloud sync, no tracking. Non-personalized ads on the free plan — removed
> with Lifetime Pro. Your list, your device.

(Matches the locked wording; avoid absolute impossibility claims.)
