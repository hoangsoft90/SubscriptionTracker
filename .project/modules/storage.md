# Module: Storage & Repositories

**Files**: `lib/core/storage/{app_database, migrations, seeder}.dart`,
`lib/features/{subscriptions,categories,settings}/data/*.dart`
· **Spec**: §2.6/§6 · **Milestone**: M0

## Trách nhiệm

SQLite versioned storage + typed repository layer.

## Migration

- `DatabaseMigrationRunner(migrations)` — chạy tuần tự theo `PRAGMA user_version`;
  mỗi migration trong transaction riêng, bump version sau khi xong.
- `_validate()` assert list **contiguous từ 1** (fail-fast nếu thiếu version —
  tránh schema lệch user_version).
- `AppDatabase.migrations` hiện chỉ có `Migration(1, _migrationV1)`.

## Schema v1

- `categories(id TEXT PK, name, icon_emoji, color_hex, is_default)`
- `subscriptions(id TEXT PK, name, amount_minor INT, currency, billing_cycle,
  custom_interval_days, start_date, next_billing_date, billing_anchor_day INT,
  is_trial INT, trial_end_date, cancellation_url, status, category_id FK→categories,
  color, icon_emoji, reminder_days_before, notes, created_at, updated_at)`
  + indexes `next_billing_date`, `status`, `category_id`.
- `app_settings(key TEXT PK, value)`
- `PRAGMA foreign_keys = ON` ở `open()`.
- ⚠️ `reminder_days_before` có trong schema nhưng plan SQL gốc thiếu — đã ghi
  chú lệch trong design.md + spec; cột chưa được UI dùng.

## Seeder

- Idempotent (`conflictAlgorithm: ignore`): 11 categories mặc định (streaming,
  music, cloud-storage, productivity, fitness, news, gaming, design,
  developer-tools, shopping, other) + `app_settings.primaryCurrency = 'USD'`.
- Wire vào `AppDatabase.open()` — seed mỗi lần mở, không đụng dữ liệu có.

## Repositories

- Interface (`SubscriptionRepository`, `CategoryRepository`,
  `SettingsRepository`) + impl `Sqflite*` (toMap/fromMap snake_case).
- `CategoryRepository.delete` — **unassign subscriptions trước khi xóa**
  (trong transaction, đúng spec M1 "one defined behavior").
- `SubscriptionRepository.countByStatus(SubscriptionStatus)` — nhận enum
  (không raw string).

## Test

`test/data_storage_test.dart`: CRUD round-trip, FK, migration 1→2 runner,
seed idempotency, category-delete-unassign.
