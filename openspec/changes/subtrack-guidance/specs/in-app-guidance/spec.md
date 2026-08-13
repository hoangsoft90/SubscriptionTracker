## Purpose

Guides first-run users through SubTrack's key screens with one-time spotlight tours, "New" feature badges, and short explanations for disabled controls — informative on first contact, silent afterwards.

## ADDED Requirements

### Requirement: Feature badge signals an unseen feature
The system SHALL render a small "New" badge (label and/or dot) anchored to a designated UI element whenever its associated guidance step has not been completed. Once the step is completed, the badge SHALL disappear permanently and SHALL NOT reappear on later launches.

#### Scenario: Badge visible before the step is seen
- **WHEN** a user opens Home and the calendar guidance step is not yet completed
- **THEN** a "New" badge is shown anchored to the calendar card

#### Scenario: Badge disappears once the step is completed
- **WHEN** the user completes the calendar guidance step (via the tour)
- **THEN** the badge is no longer shown on the calendar card and stays hidden on every subsequent launch

### Requirement: Spotlight tour highlights a target with an auto-positioned tooltip
The system SHALL display a full-screen overlay that dims the background, cuts a transparent "spotlight" hole around the target element, and shows a tooltip card with a title, body text, and step counter. The tooltip position SHALL be computed from the target's on-screen geometry: preferred below the target, flipped above when there is no room, and clamped so the card stays fully within the screen bounds.

#### Scenario: Tooltip renders below the target when there is room
- **WHEN** the target sits in the upper half of the screen
- **THEN** the tooltip card is positioned below the target

#### Scenario: Tooltip flips above when there is no room below
- **WHEN** the target sits near the bottom of the screen
- **THEN** the tooltip card is positioned above the target instead of overflowing off-screen

#### Scenario: Tooltip never renders outside the screen
- **WHEN** the target is near any screen edge
- **THEN** the tooltip card is clamped so it remains fully within the visible screen

### Requirement: Tour advances sequentially with Skip, Next, Done and backdrop tap
A multi-step tour SHALL advance through its steps in order. The last step SHALL offer a "Done" action; earlier steps offer "Next". A "Skip" action SHALL be available on every step. Tapping the dimmed backdrop SHALL advance to the next step (or complete the tour on the last step). Skip SHALL mark every remaining step of the tour as completed so per-step badges clear.

#### Scenario: Next advances to the following step
- **WHEN** the user taps Next on step 1 of a 2-step tour
- **THEN** step 2 is shown with its own tooltip and the step counter updates

#### Scenario: Done completes the final step
- **WHEN** the user taps Done on the last step
- **THEN** the overlay closes and the tour is recorded as seen

#### Scenario: Backdrop tap advances
- **WHEN** the user taps the dimmed background (not the tooltip card)
- **THEN** the tour advances to the next step (or completes on the last step)

#### Scenario: Skip clears badges and marks the tour seen
- **WHEN** the user taps Skip on any step
- **THEN** all steps of the tour are recorded as completed and the tour is marked seen, so badges disappear and the tour never re-triggers

### Requirement: Tours and steps show only once per user
The system SHALL persist completion state and SHALL NOT start a tour whose id is already recorded as seen, nor show a step already recorded as completed.

#### Scenario: A seen tour does not re-trigger
- **WHEN** a user who completed the Home tour returns to Home on a later launch
- **THEN** the spotlight tour does not start again

#### Scenario: Guidance state survives an app restart
- **WHEN** the app is restarted after completing (or skipping) a tour
- **THEN** completed steps and seen tours remain recorded

### Requirement: Disabled controls explain why and how to unlock
The system SHALL allow any disabled control to be wrapped with a helper that, when tapped, shows a short dialog/tooltip stating why the control is disabled and what unlocks it, with an optional action button (e.g. open the paywall). When the control is enabled, the helper SHALL be inert (taps pass through to the control).

#### Scenario: Tapping a blocked control explains the reason
- **WHEN** the free tier is at its hard limit and the user taps the disabled add-subscription FAB
- **THEN** a dialog explains the limit and offers an "Unlock Pro" action

#### Scenario: The helper is inert for enabled controls
- **WHEN** the wrapped control is enabled
- **THEN** tapping it performs its normal action and never shows the explanation dialog
