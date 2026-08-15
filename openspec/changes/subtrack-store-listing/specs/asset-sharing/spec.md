## Purpose

Store-facing assets (listing doc + icon + feature graphic) were shared with the developer through temporary public links: `chplay.md` on JotBird and a zip of `icon.png` + `feature-graphic.png` on tmpfiles.org.

## ADDED Requirements

### Requirement: Listing doc published on JotBird
The `chplay.md` content SHALL be published to JotBird via the publish API, returning a shareable URL with a title.

#### Scenario: Publish succeeds
- **WHEN** the developer requests the listing link
- **THEN** the API returns a live share URL (HTTP 200 on GET) with the document title and a 90-day expiry (free account)

### Requirement: Icon + feature graphic zipped and shared
The `icon.png` (512×512) and `feature-graphic.png` (1024×500) SHALL be packed into a single zip and uploaded to tmpfiles.org, returning a direct-download link.

#### Scenario: Developer downloads the assets
- **WHEN** the developer opens the tmpfiles.org link
- **THEN** the zip downloads and contains exactly `icon.png` + `feature-graphic.png` (for upload into Play Console graphics assets)
