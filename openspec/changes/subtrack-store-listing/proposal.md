## Why

With the app close to Play Store submission (release infra from `subtrack-monetization-release`, store polish from `subtrack-store-polish`), the developer prepared the final store submission artifacts:

1. **Launcher label** — the Android launcher label, iOS display name and web title all showed the internal short name `subtrack`; the developer wanted the user-visible app name to read "Subscription Tracker".
2. **Store listing doc** — there was no single document containing all the Google Play Console listing content (name, short/full descriptions, category/tags, graphics guidance, content checklist) ready to copy-paste into the Play Console.
3. **Asset sharing** — the developer wanted to share the icon + feature graphic (zip) and the listing document (markdown) via temporary public links (tmpfiles.org, JotBird).

## What Changes

- **Launcher label "Subscription Tracker"** — `android:label` in `AndroidManifest.xml`, iOS `CFBundleDisplayName`, and the web title / manifest (`web/index.html`, `web/manifest.json`) now read "Subscription Tracker". Internal identifiers are intentionally unchanged: in-app brand strings ("SubTrack", "SubTrack Pro", backup messages), `subtrack_lifetime_pro` (Play Console product id), `subtrack.db`, storage prefix `subtrack_`, and the notification channel — renaming any of those would break existing installs / store linkage.
- **`chplay.md`** — new root-level document with the complete Play Store listing content: App Name (≤30 chars, ASO), Short Description (≤80 chars, EN + VI), Full Description (EN + VI, ASO bullet style, ≤4000 chars), Store Settings (Finance category + 5 tags), Graphics & Assets guidance (4 screenshot ideas with EN/VI overlay text, feature graphic 1024×500, icon 512×512), and an App Content checklist (privacy policy URL, data safety, content rating, app access, IAP product, AdMob app id, target API 36).
- **Sharing** — `chplay.md` published to JotBird (free account, 90-day link) via the publish API; `icon.png` + `feature-graphic.png` zipped and uploaded to tmpfiles.org (temporary link) for the developer to download and upload into Play Console.

## Capabilities

### New Capabilities

- `store-listing-doc`: `chplay.md` contains all Play Console listing content (name, descriptions EN/VI, category/tags, screenshot/feature-graphic/icon guidance, content checklist) in copy-paste Markdown code blocks.
- `launcher-label`: the user-visible app name across Android/iOS/web is "Subscription Tracker"; internal identifiers (product id, db name, storage prefix, notification channel, in-app brand) unchanged to preserve data + store linkage.

### Modified Capabilities

- (none — `openspec/specs/` is empty in this repo; all delta specs live in change directories.)

## Impact

- **Code**: `android/app/src/main/AndroidManifest.xml` (`android:label`), `ios/Runner/Info.plist` (`CFBundleDisplayName`), `web/manifest.json` + `web/index.html` (title / apple-mobile-web-app-title), `chplay.md` (new).
- **Schema**: none.
- **Dependencies**: none.
- **Tests**: no Dart logic changed (config/doc only) — no test impact; `flutter analyze` / `flutter test` unaffected.
- **External**: `chplay.md` published at a JotBird share link (90-day TTL); `icon.png` + `feature-graphic.png` zipped and uploaded to tmpfiles.org (temporary). Both links were handed to the developer.
