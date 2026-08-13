# Module: Money

**File**: `lib/core/money/money.dart` · **Spec**: `subtrack-core-engine` §2.1 · **Milestone**: M0

## Trách nhiệm

Đại diện giá trị tiền **chính xác tuyệt đối** bằng integer minor units —
không bao giờ dùng `double` trong tính toán tiền (invariant cốt lõi của app).

## API chính

- `Money(this.amountMinor, this.currency)` — ctor const.
- `Money.parse(String input, String currency)` — parse user input → minor int:
  - 0-decimal currency (VND/JPY/KRW): strip mọi separator (`.,`).
  - 2-decimal: strip `,`, last `.` là decimal point; truncate quá decimals
    (12.345 → 12.34); reject số âm (FormatException).
- `Money operator +(Money other)` — int cộng chính xác; **throw ArgumentError
  nếu khác currency**.
- `String format({String locale})` — intl NumberFormat (chỉ ở UI boundary);
  không có ký hiệu tiền tệ trong setup hiện tại.
- `Map<String, int> sumByCurrency(Iterable<Money>)` — group + sum theo currency.
- `currencyDecimals` map (USD/EUR/GBP=2, VND/JPY/KRW=0).

## Quyết định

- **Thiếu decimals cho currency lạ → default 2**.
- Parse luôn trả về **non-negative** (subscription price không âm).
- Format chia cho 10^decimals qua `double` — chỉ tại UI boundary; tiền lớn
  (≥ 2^53 minor) có thể mất chính xác nhưng ngoài phạm vi MVP.

## Test

`test/money_test.dart` (13 tests): parse các định dạng (separators, VND, truncate,
negative reject), `+` currency check, sumByCurrency, format.
