## Purpose

Money values are represented exactly as integer minor units plus an ISO 4217 currency code, so all arithmetic in the app is free of floating-point rounding errors.

## ADDED Requirements

### Requirement: Money stores minor units as integer

The system SHALL represent every monetary amount as a `Money` value holding an integer `amountMinor` (e.g. $9.99 → 999, ₫79,000 → 79000) and a currency code per ISO 4217 (e.g. `USD`, `VND`, `EUR`).

#### Scenario: Amount parsed from decimal string

- **WHEN** a user enters an amount of `9.99` in a 2-decimal currency (USD)
- **THEN** the system stores `amountMinor = 999` and `currency = "USD"`

#### Scenario: Zero-decimal currency amount

- **WHEN** a user enters an amount of `79000` in a 0-decimal currency (VND)
- **THEN** the system stores `amountMinor = 79000` and `currency = "VND"` with no fractional representation

### Requirement: Per-currency decimal precision

The system SHALL know the decimal places for at least `USD`, `EUR`, `GBP` (2) and `VND`, `JPY`, `KRW` (0), and SHALL use the correct decimals when parsing user input and formatting output.

#### Scenario: Format with currency decimals

- **WHEN** a Money value with `amountMinor = 1250` and `currency = "EUR"` is formatted
- **THEN** the formatted string is `12.50` (2 decimals), and `1250` VND formats as `1.250` (0 decimals)

### Requirement: Money arithmetic stays in integer domain

All arithmetic (sums, monthly/yearly/annualized projections, category totals) SHALL operate on integer `amountMinor` values; the system SHALL NOT perform monetary calculations with floating-point `double`.

#### Scenario: Summing several subscriptions

- **WHEN** summing three subscriptions of 999, 1299 and 499 USD minor units
- **THEN** the total is exactly `2797` minor units with no floating-point drift

### Requirement: Money addition validates currency compatibility

The system SHALL reject summing two `Money` values with different currency codes; the caller SHALL convert or group by currency first.

#### Scenario: Mixed-currency sum rejected

- **WHEN** attempting to add a USD Money to a VND Money directly
- **THEN** the operation is rejected with an error indicating currencies must match

### Requirement: Total-by-currency grouping

The system SHALL be able to produce per-currency totals from a heterogeneous collection of Money values (e.g. all USD grouped together, all VND grouped together), never a single cross-currency total.

#### Scenario: Dashboard totals grouped by primary currency

- **WHEN** subscriptions hold USD and VND amounts and the user views totals
- **THEN** the system returns separate totals per currency (USD total and VND total) and never mixes them
