# Patterns & Conventions

Những pattern lặp lại trong repo — khi viết code mới, bám theo các pattern này.

## 1. Money (tiền — vùng loại trừ Ponytail: liên quan số/tiền)

- **Luôn `int` minor units** (`amountMinor`). KHÔNG bao giờ dùng `double` cho
  tiền trong tính toán.
- `Money(amountMinor, currency)`; decimals theo `currencyDecimals` (USD/EUR/GBP=2,
  VND/JPY/KRW=0).
- `Money.parse(input, currency)` — bỏ separator, truncate quá decimals, **reject
  số âm** (FormatException). Trả `int minor`.
- `Money + Money` **throw nếu khác currency** — nhóm theo currency trước
  (`sumByCurrency`).
- Format chỉ ở UI boundary qua `Money.format()` (intl). Lưu ý: format hiện tại
  **không có ký hiệu `$`/`₫`** (intl setup không locale symbols) — test assert
  `'14.99'` chứ không phải `'$14.99'`; detail screen append code thủ công
  (`'19.99 USD'`).

## 2. Calendar dates (ngày — spec §2.5)

- **Local calendar date, midnight**: `DateUtils.localMidnight(d)`; lưu `YYYY-MM-DD`.
- Không lưu UTC, không timezone shift.
- `addMonthsClamped(date, months, anchorDay)` — ngày cuối tháng clamp
  (31/01 → 28/02 → 31/03), leap year đúng.
- `DateUtils.parse` validate range ngày hợp lệ.
- **Conflict**: `lib/core/calendar/date_utils.dart` — trong UI phải import alias
  `as cal` vì Flutter material cũng có `DateUtils`.

## 3. Billing (spec §7)

- MONTHLY/QUARTERLY/YEARLY: `billingAnchorDay` **bắt buộc** (guard throw khi
  thiếu — chống drift ngày). Ngày tiếp theo = tháng tới + clamp theo anchor.
- CUSTOM: `startDate + n × customIntervalDays`.
- WEEKLY: không cần anchor.
- Projections int-safe: yearly = weekly×52 / monthly×12 / quarterly×4 /
  yearly×1 / custom `(amount×365) ~/ days` (days ≤ 0 → fallback ×12).

## 4. Domain models (data layer)

- `toMap()` / `fromMap()` cho SQLite (snake_case columns).
- `copyWith` nullable-safe: chỉ override field được truyền (không đặt null
  không chủ đích).
- Enums có `dbValue` (UPPERCASE) + `fromDb`; **KHÔNG dùng `.name`** để hiển thị
  (BillingCycle không có getter `name` — dùng `dbValue`). Bug thực tế từng xảy ra.

## 5. Repository pattern

- Interface trừu tượng (`SubscriptionRepository`, `CategoryRepository`,
  `SettingsRepository`) + impl `Sqflite*` (mobile) và `LocalStorage*` (web) —
  chọn qua `StorageBackend` factory (conditional import).
- Providers (`FutureProvider`) expose repo cho controllers.
- Test: Fake in-memory impl implements interface (`test/fakes.dart`).
- Lưu ý: xóa dữ liệu phải đúng thứ tự FK (child trước parent) khi
  `PRAGMA foreign_keys = ON` (bug thật từng xảy ra ở backup Replace All).

## 6. Controller (Riverpod AsyncNotifier)

```dart
class XController extends AsyncNotifier<XState> {
  @override
  Future<XState> build() async {
    final repo = await ref.watch(xRepositoryProvider.future);
    return XState(data: await repo.getAll());
  }
  Future<void> mutate() async {
    final repo = await ref.read(xRepositoryProvider.future);
    await repo.doSomething();
    state = AsyncData(await repo.getAll()); // hoặc reload()
  }
}
```

- Mutate state **sau** await; guard khi state đang loading (tránh `state.value!`).
- List controller: giữ full list + `visible` getter (filter/search/sort) — không
  cache list đã lọc.

## 7. Widget tests (fake-async zone)

- **Không dùng sqflite trong `testWidgets`** (ffi cần isolate thật, không resolve
  trong FakeAsync). Dùng `WidgetHarness` + `fakes.dart`.
- `ProviderScope(overrides: [...], child:)` — override repo providers bằng fakes.
- **Không dùng `pumpAndSettle`** nếu có async provider loading spinner (treo vô
  hạn). Dùng `pumpUntilFound(tester, finder)` (loop pump có timeout) + riêng
  `pumpUntilTheme` cho theme async.
- Form dài (add/edit): Save button dưới fold → set viewport cao
  (`tester.view.physicalSize = Size(800, 1600)`).
- Page transition: sau khi route mới xuất hiện, `pump(400ms)` trước khi tap
  widget trong AppBar (icon đang trượt từ ngoài viewport).
- Controller tests dùng `TestDb` (sqflite_common_ffi in-memory, `harness.container()`).

## 8. Navigation & l10n

- `context.push('/subscriptions/add')` — path literals; route names trong
  `AppRoutes` (camelCase).
- Mọi user-facing string qua ARB (`lib/core/l10n/app_{en,vi}.arb`) + gen-l10n;
  UI dùng `context.l10n.*`; user data (tên sub/category/notes) không localize.
- Format ngày ngắn: `formatDate(context, date)` locale-aware (vi → dd/MM,
  else MM/DD).
- Tooltip dùng cho semantics (FAB, icon buttons) — test a11y assert
  `find.byTooltip(...)`.

## 9. Naming & style

- Files: snake_case. Classes: PascalCase. Private helpers: `_`.
- Feature-First paths (đã mô tả ở architecture.md).
- `flutter analyze` phải sạch trước khi coi task xong (dựa vào flutter_lints).
- Tên OpenSpec change/spec không bắt đầu bằng số.

## 10. In-app guidance (overlay toolkit — `lib/features/guidance/`)

- **FeatureBadge**: bọc bất kỳ widget nào → dot/label "New" góc trên-phải;
  `visible` từ guidance state (step đã xem → tắt vĩnh viễn).
- **SpotlightOverlay + tooltip_geometry**: dim background + khoét lỗ spotlight
  quanh target (`CustomPaint` + `BlendMode.clear`); tooltip tự định vị — ưu tiên
  dưới target, flip trên khi thiếu chỗ, clamp vào màn hình (guard khi tooltip lớn
  hơn màn hình). Geometry là **pure function** trong `tooltip_geometry.dart`
  (unit-test được); arrow diamond đặt cùng Stack với card.
- **DisabledStateHelper**: wrap control disabled → tap hiện dialog lý do + điều
  kiện unlock + nút hành động; inert khi enabled (tap qua).
- **GuidanceHost**: orchestrator — nhận `GlobalKey` map targets, đo
  `RenderBox.localToGlobal`, chạy tuần tự steps, Skip/Next/Done, backdrop tap =
  next; `_skip()` completeStep từng step (clear badge) + mark tour seen.
- **GuidanceController**: AsyncNotifier persist **`app_settings`**
  (`guidance.steps`/`guidance.tours`, comma-joined — rule #8); tour show-once
  qua seen-tour-ids; `completeStep` tự mark tour seen khi đủ steps.
- Test: `test/guidance_test.dart` (geometry, persist/show-once, 3 components,
  tour flow, skip clears steps).
