## Purpose

A full codebase review (all 83 lib files) confirmed the app has no new UI/logic/crash paths, and fixed the three real issues it found: wrong paywall error copy, a paywall slot counter that disagreed with the add gate, and a hardcoded English error in the exchange-rate editor.

## ADDED Requirements

### Requirement: Paywall failure shows purchase copy, not backup copy
When a purchase or restore attempt fails (anything other than purchased/cancelled), the paywall SHALL show a localized purchase-error message (`paywallError`), never the backup-import error string ("This file is not a SubTrack backup.").

#### Scenario: Purchase fails
- **WHEN** `proEntitlementController.purchase()` returns `failed` or `notFound`
- **THEN** the paywall shows the localized `paywallError` message (e.g. "Purchase couldn't be completed. Please try again." / "Không thể hoàn tất giao dịch mua. Vui lòng thử lại.")

#### Scenario: Restore fails
- **WHEN** `proEntitlementController.restore()` returns `failed` or `notFound`
- **THEN** the paywall shows the same localized `paywallError` message

### Requirement: Paywall slots-used matches the add-form gate
The paywall's "N of 10 slots used" counter SHALL count paywall slots exactly like the add flow's hard-block gate — ACTIVE + PENDING_CANCELLATION (`paywallSlotCount`) — never ACTIVE only, so the displayed usage always agrees with whether adding is blocked.

#### Scenario: Active + pending-cancellation at the limit
- **WHEN** a user has 9 ACTIVE and 1 PENDING_CANCELLATION subscription (10 slots)
- **THEN** the paywall shows "10 of 10 slots used" and adding an 11th is hard-blocked (consistent gate)

### Requirement: Exchange-rate validation error is localized
The Settings exchange-rate editor SHALL show a localized validation message when a rate is empty, non-numeric or non-positive (`settingsExchangeRatesInvalid` with the currency code), never a hardcoded English string.

#### Scenario: Invalid rate entered
- **WHEN** the user enters an empty, non-numeric or zero/negative rate for a currency in Settings → Exchange rates
- **THEN** the editor shows the localized message naming the currency (e.g. "Enter a valid rate greater than 0 for EUR" / "Nhập tỷ giá hợp lệ lớn hơn 0 cho EUR")
