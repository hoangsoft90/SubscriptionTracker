## Purpose

Lets users organize subscriptions into the 11 seeded default categories or their own custom categories, each with an icon and color, so list and dashboard views can group meaningfully.

## ADDED Requirements

### Requirement: Default categories available

The system SHALL expose the 11 seeded default categories (is_default) for assignment to subscriptions, without allowing them to be deleted.

#### Scenario: Default categories selectable

- **WHEN** the user assigns a category to a subscription
- **THEN** all 11 default categories are selectable

#### Scenario: Default category cannot be deleted

- **WHEN** the user attempts to delete a default category
- **THEN** the operation is blocked

### Requirement: Custom category CRUD

The system SHALL let the user create, edit and delete custom categories with a name, emoji icon and color; deleting a category SHALL unassign it from subscriptions (subscriptions become uncategorized) or prompt the user for a replacement — one defined behavior only.

#### Scenario: Create a custom category

- **WHEN** the user creates a category named "Streaming" with an emoji and color
- **THEN** it becomes available for assignment and appears in the category list

#### Scenario: Delete custom category reassigns safely

- **WHEN** the user deletes a custom category that is in use
- **THEN** the system either unassigns the category from affected subscriptions or asks the user to choose a replacement, and no subscription row is lost

### Requirement: Category assignment on subscriptions

The system SHALL persist `category_id` on subscriptions; the detail screen SHALL show the assigned category. Category assignment happens via the onboarding preset pre-fill (preset carries the category) and is preserved across edits.

> **Implementation note:** the M1 add/edit form has no standalone category
> picker — `category_id` is set by preset pre-fill and carried through edits.
> The detail screen shows the category id as text (no icon/color chip yet).

#### Scenario: Category shown on detail

- **WHEN** a subscription has an assigned category
- **THEN** its detail screen shows the assigned category
