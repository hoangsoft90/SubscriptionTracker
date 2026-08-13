# Module: Calendar dates

**File**: `lib/core/calendar/date_utils.dart` · **Spec**: §2.5 · **Milestone**: M0

## Trách nhiệm

Xử lý ngày theo **calendar date local** (không UTC, không timezone shift) —
đảm bảo ngày billing không trôi do múi giờ.

## API chính

- `DateTime localMidnight(DateTime d)` — chuẩn hoá về local midnight.
- `String toIsoDate(DateTime)` / `DateTime? parse(String)` — `YYYY-MM-DD`;
  parse **validate range** ngày hợp lệ (trả null nếu sai).
- `DateTime addMonthsClamped(DateTime date, int months, {int? anchorDay})` —
  giữ anchor day, clamp cuối tháng (31/01 → 28/02 → 31/03; leap 2028 đúng).

## Lưu ý

- **Conflict tên**: Flutter material cũng export `DateUtils` — trong UI import
  alias: `import '.../date_utils.dart' as cal;`.
- Format hiển thị ngắn (`MM/DD`) nằm ở `subscription_list_screen.dart` (`formatDate`)
  — dùng cho list/detail/dashboard.

## Test

`test/billing_calculator_test.dart` + `test/data_storage_test.dart`: round-trip
không shift, clamp tháng 2, leap year, Dec→Jan.
