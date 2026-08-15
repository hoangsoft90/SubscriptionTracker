# AI Rules (bắt buộc khi code trong repo này)

> Đây là phần RIÊNG của project SubTrack. Quy trình chung (Retrieval, Git &
> Kiểm thử, Code Review, Task Completion Hook) nằm trong [`AGENTS.md`](../AGENTS.md)
> — đọc cùng file này.

## Vùng loại trừ Ponytail (TẮT ponytail — hỏi user trước khi commit)

Code thuộc các nhóm sau **bắt buộc** dừng lại xác nhận user trước khi commit
(quy trình project):

1. **Liên quan số/tiền** — toàn bộ `Money`, `BillingCalculator`,
   `DashboardController` totals/projections. Sai lệch = thiệt hại thực tế.
2. **Ràng buộc cứng** — validation form (Money.parse, URL, ngày), guard
   billingAnchorDay, giới hạn min/max.
3. **Khó tái tạo để test** — migration chạy trên DB thật, seeder idempotency,
   FK cascade behavior.

## Quy tắc kỹ thuật cứng

1. **Tiền**: không bao giờ `double` cho tiền. Dùng `Money` (int minor units).
2. **Ngày**: calendar date local midnight; `YYYY-MM-DD` trong DB; không UTC.
3. **Billing**: fixed cycles PHẢI có `billingAnchorDay` (throw nếu thiếu —
   chống drift). CUSTOM = start + n×interval.
4. **Enums**: hiển thị qua `dbValue` (UPPERCASE), KHÔNG dùng `.name`
   (BillingCycle không có getter `name`).
5. **Currency mixing**: `Money + Money` khác currency → throw; luôn group
   theo currency trước khi cộng.
6. **User data không localize**: tên subscription/category/notes render nguyên văn.
7. **Feature-First layering**: domain/ không import Flutter/Riverpod/sqflite;
   presentation không gọi repo trực tiếp.
8. **Settings**: qua bảng `app_settings` (M0) — không thêm shared_preferences.
9. **No analytics/crash SDK** — privacy constraint tuyệt đối. Kiểm tra
   `pubspec.yaml` khi thêm dep. **Ngoại lệ duy nhất (amendment 2026-08-09):**
   `google_mobile_ads` (AdMob) — banner đáy + interstitial hiếm, free tier chỉ,
   non-personalized (`npa=1`), Pro xóa ads. MỌI SDK mạng khác vẫn cấm.
10. **Riverpod**: dùng plain `AsyncNotifier` (không codegen, không build_runner).
    Riverpod 3: `Override` type không public — test dùng inference.

## Quy tắc test

1. **Widget tests**: KHÔNG dùng sqflite trong `testWidgets` (fake-async zone) —
   dùng `WidgetHarness` + `fakes.dart`. Controller tests dùng `TestDb` (ffi).
2. **Không `pumpAndSettle`** với async provider loading spinner — dùng
   `pumpUntilFound` (timeout loop). Form dài → viewport cao (800×1600).
3. Page transition: `pump(~400ms)` sau khi route mới xuất hiện trước khi tap
   AppBar widget.
4. Assert tiền: format không có ký hiệu `$` — assert `'14.99'` (hoặc `'19.99 USD'`
   khi có currencyCode).
5. `flutter analyze` sạch + full tests xanh trước khi báo hoàn thành.

## Naming & workflow

- OpenSpec change/spec: tên không bắt đầu bằng số.
- Cập nhật `state.md` (này) sau mỗi task lớn; `working.md` theo quy trình AGENTS.md.
- Task lớn (≥3 file / schema / API / user yêu cầu): Git & Kiểm thử + Code Review
  bắt buộc; lưu ADR/memory qua Task Completion Hook.
- Commit: cần user xác nhận nếu code chạm vùng loại trừ Ponytail (tiền).

## Công cụ (PATH bắt buộc)

Mọi lệnh Flutter/Dart/node: `export PATH="/Users/hoang/.nvm/versions/node/v24.18.0/bin:/opt/miniconda3/bin:$PATH"`

Build Android (AGP 9 yêu cầu JDK 17+): `export JAVA_HOME="<path tới JDK 21 local>"`
(vd macOS: `/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home`).
`android/gradle.properties` KHÔNG hard-code đường dẫn JDK nữa (tránh break CI
runner Linux) — Gradle dùng `JAVA_HOME`. CI (GH Actions) set qua `actions/setup-java`.

## Known issues

- **OCR (open-code-review) lỗi 401 Invalid API key** — chưa dùng được; cần user
  sửa config. Fallback: review mặc định + code-reviewer.
- **AdMob**: đã dùng ID thật từ 2026-08-11 (app `ca-app-pub-6917313063209470~5291822252`, package ban đầu `com.subguard.app`) — banner/interstitial trong `ads_config.dart`, App ID trong AndroidManifest + Info.plist. **2026-08-15**: đổi package sang `com.hoangsoft.subtrack` → khi bật ads thật phải đăng ký AdMob app mới cho package mới + thay ID trong `ads_config.dart`. Rewarded ID lưu sẵn nhưng chưa wire flow. Lưu ý: ID thật chỉ trả ads khi ad unit đã active + có traffic hợp lệ; trong dev vẫn có thể gặp "No fill" — không phải lỗi cấu hình. Web không hỗ trợ
  AdMob → `AdConfig.supported=false` (no-op).
- `sqflite_common_ffi` không chạy trong widget tests (isolate) — đừng thử lại,
  dùng fakes.
- Dashboard Home: indexedStack giữ mọi branch alive — `find.text` có thể match
  nhiều nơi; dùng `findsWidgets` hoặc scope.
