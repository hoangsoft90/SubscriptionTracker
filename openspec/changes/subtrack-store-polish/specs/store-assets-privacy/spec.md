## Purpose

The store-facing materials are submission-ready: the privacy policy never mentions the GitHub repository (store reviewers read it verbatim), it is hosted on gh-pages with a support-email contact, and the store listing assets (512×512 app icon, 1024×500 feature graphic) exist and match the app's brand.

## ADDED Requirements

### Requirement: Privacy policy contact uses an email, not the GitHub repository
The privacy policy SHALL NOT reference the GitHub repository or any issue tracker. The Contact section SHALL provide a support email address in both languages (EN + VI), in both the markdown source and the self-contained HTML, with the HTML using a `mailto:` link.

#### Scenario: Contact section in English
- **WHEN** a reader opens the English section of the privacy policy
- **THEN** the Contact section shows the support email `haibasoftware@gmail.com` (mailto link in HTML) and no GitHub repository URL

#### Scenario: Contact section in Vietnamese
- **WHEN** a reader opens the Vietnamese section of the privacy policy
- **THEN** the Contact section shows the same support email and no GitHub repository URL

### Requirement: Privacy policy stays live on gh-pages
The gh-pages branch SHALL host the current privacy policy as `index.html` (a copy of `docs/privacy-policy.html`), so the store-facing URL https://hoangsoft90.github.io/SubscriptionTracker/ always serves the latest policy.

#### Scenario: Redeploy after an edit
- **WHEN** the privacy policy HTML is edited in `docs/`
- **THEN** the updated file is copied to gh-pages `index.html` and pushed, and the public URL returns HTTP 200 with the updated content

### Requirement: Store listing assets exist at required sizes
The repository SHALL contain an app icon `icon.png` at exactly 512×512 pixels (RGB) and a feature graphic `feature-graphic.png` at exactly 1024×500 pixels, the feature graphic generated from the app's brand (teal gradient, white card with the app icon, "SubTrack" title, subtitle, tagline and feature bullets) with all text inside the image bounds.

#### Scenario: Listing upload
- **WHEN** the developer uploads store listing assets
- **THEN** `icon.png` (512×512) and `feature-graphic.png` (1024×500) are available at the repository root and match the app's icon design
