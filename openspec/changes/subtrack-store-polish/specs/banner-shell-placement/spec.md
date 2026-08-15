## Purpose

The AdMob banner renders flush against the app's bottom navigation buttons on every tab — one instance in the app shell, not per-tab — with no SafeArea gap and no overlap with the FAB.

## ADDED Requirements

### Requirement: Banner lives in the app shell, directly above the NavigationBar
The banner SHALL be rendered once in the shell Scaffold's `bottomNavigationBar` as a Column whose children are the banner and the `NavigationBar` (in that order), so the banner touches the top edge of the nav bar on every tab (Home, Subscriptions, More). The per-tab Scaffolds (Home, Subscriptions) SHALL NOT render the banner themselves.

#### Scenario: Banner is flush with the nav buttons
- **WHEN** the app shell is displayed with ads enabled
- **THEN** the banner's bottom edge touches the NavigationBar's top edge — there is no visible gap between them, on every tab

#### Scenario: Banner appears on all tabs
- **WHEN** the user switches between Home, Subscriptions and More
- **THEN** the banner remains in the same shell position above the NavigationBar

### Requirement: No bottom SafeArea on the banner
The banner widget SHALL NOT apply its own bottom SafeArea — the NavigationBar below already consumes the system bottom inset, so a SafeArea on the banner would create a visible gap between the banner and the nav buttons.

#### Scenario: Gesture-nav devices
- **WHEN** the device has a gesture navigation bar (system bottom inset)
- **THEN** the inset is consumed by the NavigationBar and the banner sits directly on it, with no extra padding

### Requirement: FAB stays above the banner
The FAB on the Subscriptions screen SHALL float above the shell's bottomNavigationBar column (banner + nav bar), never overlapping the banner.

#### Scenario: Subscriptions FAB with a loaded banner
- **WHEN** the Subscriptions screen shows its FAB and a banner is loaded in the shell
- **THEN** the FAB is positioned above the banner (regression: `banner_layout_test.dart` layout invariant)
