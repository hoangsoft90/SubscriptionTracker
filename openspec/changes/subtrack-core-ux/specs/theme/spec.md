## Purpose

Supports system-aware and manual dark mode plus consistent empty states, so the app looks polished and reinforces the privacy-first brand in both light and dark themes.

## ADDED Requirements

### Requirement: Dark mode

The system SHALL support dark mode following the system setting by default, with a manual override (light / dark / system) persisted across launches.

#### Scenario: System dark mode applied

- **WHEN** the device is in dark mode and the app setting is "system"
- **THEN** the app renders the dark theme

#### Scenario: Manual override persisted

- **WHEN** the user selects "dark" manually and relaunches
- **THEN** the app still renders dark until the user changes it

### Requirement: Theming applies to all screens

All screens (onboarding, tabs, list, detail, add/edit, settings) SHALL render correctly in both light and dark themes with sufficient contrast for accessibility.

#### Scenario: List readable in dark mode

- **WHEN** the Subscriptions list renders in dark mode
- **THEN** text and status chips meet accessible contrast ratios against the dark background

### Requirement: Empty states on all main screens

The system SHALL show a designed empty state (not raw blank space) for: dashboard with no subscriptions, subscription list filtered to zero results, and search with no matches.

#### Scenario: Zero search results

- **WHEN** a search matches no subscriptions
- **THEN** the list shows an empty state with a "no matches" message rather than an empty frame

### Requirement: Accessibility basics

The system SHALL provide semantic labels for icon-only buttons and screen-reader-announceable status changes on the main flows.

#### Scenario: Icon button has label

- **WHEN** a screen contains an icon-only action (e.g. add, delete)
- **THEN** the action has an accessibility label describing it
