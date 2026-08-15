## Purpose

The user-visible app name across platforms is now "Subscription Tracker", and the developer has a single copy-paste document (`chplay.md`) with the entire Google Play Console listing, plus temporary public links to share the icon + feature graphic and the listing doc.

## ADDED Requirements

### Requirement: Launcher label is "Subscription Tracker"
The Android launcher label (`android:label`), the iOS home-screen display name (`CFBundleDisplayName`) and the web title / PWA manifest SHALL read "Subscription Tracker".

#### Scenario: Launcher shows the app name
- **WHEN** the user installs the Android APK / AAB and looks at the launcher icon
- **THEN** the label under the icon reads "Subscription Tracker" (previously the internal name `subtrack`)

#### Scenario: iOS home screen + web title
- **WHEN** the user adds the iOS app to the home screen or opens the web build
- **THEN** the display name / browser tab title reads "Subscription Tracker"

### Requirement: Internal identifiers stay stable
The rename SHALL NOT touch internal identifiers whose change would break existing installs or store linkage: the in-app brand strings ("SubTrack", "SubTrack Pro", backup messages), the IAP product id `subtrack_lifetime_pro`, the database file `subtrack.db`, the storage key prefix `subtrack_`, and the notification channel id.

#### Scenario: Existing install keeps its data
- **WHEN** a user updates the app after the label rename
- **THEN** their existing subscriptions and settings remain intact (db file, storage keys and notification channel unchanged)

### Requirement: Play Console listing doc
The repository SHALL contain `chplay.md` at the root with copy-paste Play Console content: App Name (≤30 chars), Short Description (≤80 chars, EN + VI), Full Description (EN + VI, ASO bullet style, ≤4000 chars), Store Settings (Finance category + 5 tags), Graphics & Assets guidance (4 screenshots with EN/VI overlay text, feature graphic 1024×500, icon 512×512), and an App Content checklist (privacy policy URL, data safety, content rating, app access, IAP product, AdMob app id, target API 36).

#### Scenario: Developer copies the listing into Play Console
- **WHEN** the developer opens `chplay.md`
- **THEN** every Play Console field (name, short/full description EN+VI, category, tags, graphics specs, content checklist) is present in a Markdown code block ready to copy
