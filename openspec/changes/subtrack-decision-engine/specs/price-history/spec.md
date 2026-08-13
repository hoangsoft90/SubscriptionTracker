## Purpose

Detects when a subscription's price changes, records the full price history locally, and shows the user the impact (absolute and percentage change plus new yearly cost) so price increases are never silent.

## ADDED Requirements

### Requirement: Price change detection

The system SHALL detect when the amount of an active subscription is edited, and SHALL present the change to the user (absolute and percentage change, new vs. previous yearly cost) before confirming. Percentage change SHALL be computed only when the currency is unchanged.

#### Scenario: Price increase detected

- **WHEN** the user edits an active subscription's amount from 9.99 to 12.49 USD
- **THEN** the system shows the price change with the absolute (+$2.50) and percentage (+25%) change and the updated yearly cost

#### Scenario: Currency change excludes percentage

- **WHEN** the user edits a subscription changing both currency and amount at once
- **THEN** the system records the new price as history but does not compute or show a percentage comparison

### Requirement: Price history persistence

The system SHALL persist every amount change in a `subscription_price_history` table (subscription id, amount minor, currency, effective date, created at) that cascades on subscription deletion, and SHALL keep the previous amount on the subscription for comparison.

#### Scenario: History row written on price edit

- **WHEN** an active subscription's amount is edited
- **THEN** a history row records the new price with the edit date, and the subscription keeps the previous amount

#### Scenario: History deleted with subscription

- **WHEN** a subscription is deleted
- **THEN** its price history rows are removed as well
