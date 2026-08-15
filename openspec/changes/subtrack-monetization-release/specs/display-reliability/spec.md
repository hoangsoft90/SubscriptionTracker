## Purpose

The subscriptions list and Home dashboard always reflect persisted data — no stale/empty states until restart — with pull-to-refresh on both tabs and a notification-permission entry point in Settings.

## ADDED Requirements

### Requirement: Reload is null-safe against a racing initial build
The system SHALL NOT use `state.value!` in `SubscriptionListController.reload()`; when a mutation races the initial provider build (state not yet loaded), it SHALL rebuild the full `SubscriptionListState` from fresh rows instead of crashing or keeping a stale list until app restart.

#### Scenario: Mutation lands while the list is still loading
- **WHEN** a subscription is added before the list's first build completes
- **THEN** no crash occurs and the list renders the fresh data once loaded (regression: `subscription_list_controller_test.dart`)

### Requirement: Home invalidates after every subscription mutation
The system SHALL invalidate `dashboardControllerProvider` after every mutation (add / edit / delete / status change / review), so the Home tab updates immediately instead of showing a stale empty state after the first add.

#### Scenario: First add updates Home immediately
- **WHEN** the user adds their first subscription from the Subscriptions tab
- **THEN** the Home dashboard reflects it without restarting the app

### Requirement: Both tabs support pull-to-refresh
Home SHALL keep a `RefreshIndicator` that re-fetches the dashboard. The subscriptions list SHALL have a `RefreshIndicator` whose `onRefresh` re-reads storage via `reload()`, so pulling down always reflects persisted data.

#### Scenario: Pull-down on the subscriptions list reloads storage
- **WHEN** the user pulls down on the subscriptions list
- **THEN** the list re-reads storage and the rows remain visible (regression: `subscription_display_test.dart`)

### Requirement: Settings exposes notification permission state and an enable path
Settings SHALL show the OS notification-permission state (On/Off) and a button to enable it: request the OS prompt on the first ask, open the OS app-notification settings after a previous ask (Android stops prompting after denial).

#### Scenario: Disabled state offers an enable button
- **WHEN** OS notifications are off
- **THEN** Settings shows an Off state with an enable button that opens the OS prompt or settings

#### Scenario: Enabled state is reflected
- **WHEN** OS notifications are on
- **THEN** Settings shows the On state and no enable button
