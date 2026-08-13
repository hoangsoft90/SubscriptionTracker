# Privacy Policy — SubTrack

**Effective date:** 2026-08-13

_English · [Tiếng Việt](#chính-sách-quyền-riêng-tư-subtrack)_

SubTrack is a subscription tracker for iOS and Android. It is built around
one promise: **your subscription data stays on your device**. This policy
describes exactly what the app collects, stores, and shares.

---

## 1. Data we collect

**We do not collect any personal data.**

- No account, no login, no email, no phone number, no profile.
- No backend server, no cloud sync, no analytics SDK, no crash-reporting SDK.
- SubTrack never transmits your subscription data anywhere. All subscription
  records, categories, and settings are stored **locally on your device**
  (SQLite on iOS/Android, browser localStorage on web).

## 2. Data stored on your device

The app stores only what you enter:

- Subscription details (name, amount, billing cycle, dates, notes).
- Categories, your app settings (theme, language, currency), and in-app
  guidance state (e.g. which onboarding tour you have seen).
- Notifications you schedule are created and delivered locally by your
  operating system. SubTrack has no servers that could see them.

Deleting a subscription (or uninstalling the app) removes it from your
device. You can also export or import all of your data at any time from
**More → Backup** as a JSON file — that file is yours, created on your
device, and SubTrack never sees or uploads it.

## 3. Ads (Google AdMob)

The free plan is supported by **non-personalized ads** served by Google
AdMob — the only third-party network SDK in the app.

- Ads are **non-personalized** (`npa=1`): no interest profiles, no cross-app
  tracking, no ATT/IDFA prompt on iOS.
- AdMob may use a device identifier to deliver ads and cap frequency.
- Ads appear as a banner on the free plan and an occasional interstitial —
  **removed entirely with the Lifetime Pro purchase**.

For Google's own privacy practices, see
<https://policies.google.com/privacy>.

## 4. In-app purchases

Lifetime Pro is a one-time, non-consumable purchase processed entirely by
the **Apple App Store** or **Google Play** (your platform's billing system).
SubTrack itself does not process payments or see your payment details.

## 5. Notifications

With your permission (requested only after you add your first
subscription), the app schedules local reminders for upcoming renewals and
trial end dates. Reminders are created and fired on your device; no data
about them leaves your device.

## 6. Permissions

| Permission | Purpose |
| --- | --- |
| Notifications (`POST_NOTIFICATIONS`) | Local renewal/trial reminders (Android 13+) |
| Internet / Network state | AdMob ads and in-app purchases |
| Billing (`com.android.vending.BILLING`) | Lifetime Pro purchase (Android) |

The app never requests SMS, contacts, location, camera, microphone, or
storage access.

## 7. Third-party services

The only external services involved are:

1. **Google AdMob** — serving non-personalized ads on the free plan.
2. **Apple App Store / Google Play** — processing your Lifetime Pro
   purchase.

Both are governed by their own privacy policies.

## 8. Children's privacy

The app does not knowingly collect any personal information from anyone,
including children. If you believe a child has provided personal
information through a store purchase flow, contact us and we will remove it
where possible (store purchases are managed by the store, not by us).

## 9. Data deletion

Because SubTrack stores no personal data on any server, there is nothing
for us to delete on your behalf. To remove your data:

- Delete individual subscriptions inside the app, **or**
- Uninstall the app (on iOS/Android), or clear site data (web).

## 10. Changes to this policy

If this policy changes, the updated version will be published on this page
with a new effective date. Material changes will be reflected in the app's
About screen as well.

## 11. Contact

Questions about this policy: please open an issue at
<https://github.com/hoangsoft90/SubscriptionTracker> or contact us via the
app's GitHub repository.

---

# Chính sách Quyền riêng tư — SubTrack

**Ngày hiệu lực:** 13/08/2026

SubTrack là ứng dụng theo dõi đăng ký (subscription) cho iOS và Android,
được xây dựng quanh một cam kết: **dữ liệu đăng ký của bạn nằm trên thiết
bị của bạn**. Chính sách này mô tả chính xác ứng dụng thu thập, lưu trữ và
chia sẻ những gì.

## 1. Dữ liệu chúng tôi thu thập

**Chúng tôi không thu thập bất kỳ dữ liệu cá nhân nào.**

- Không tài khoản, không đăng nhập, không email, không số điện thoại.
- Không máy chủ backend, không đồng bộ đám mây, không SDK phân tích, không
  SDK báo cáo sự cố.
- SubTrack không bao giờ truyền dữ liệu đăng ký của bạn đi đâu. Toàn bộ bản
  ghi đăng ký, danh mục và cài đặt được lưu **cục bộ trên thiết bị** (SQLite
  trên iOS/Android, localStorage của trình duyệt trên web).

## 2. Dữ liệu lưu trên thiết bị

Ứng dụng chỉ lưu những gì bạn nhập vào:

- Chi tiết đăng ký (tên, số tiền, chu kỳ thanh toán, ngày, ghi chú).
- Danh mục, cài đặt ứng dụng (giao diện, ngôn ngữ, tiền tệ), trạng thái
  hướng dẫn trong ứng dụng.
- Thông báo bạn lên lịch được hệ điều hành tạo và gửi cục bộ. SubTrack
  không có máy chủ nào có thể nhìn thấy chúng.

Xóa một đăng ký (hoặc gỡ cài đặt ứng dụng) sẽ xóa nó khỏi thiết bị. Bạn có
thể xuất/nhập toàn bộ dữ liệu bất cứ lúc nào từ **Thêm → Sao lưu** dưới
dạng tệp JSON — tệp đó thuộc về bạn, được tạo trên thiết bị, và SubTrack
không bao giờ nhìn thấy hay tải lên.

## 3. Quảng cáo (Google AdMob)

Gói miễn phí được hỗ trợ bởi **quảng cáo không cá nhân hóa** từ Google
AdMob — SDK mạng bên thứ ba duy nhất trong ứng dụng.

- Quảng cáo **không cá nhân hóa** (`npa=1`): không hồ sơ sở thích, không
  theo dõi liên ứng dụng, không nhắc ATT/IDFA trên iOS.
- AdMob có thể dùng định danh thiết bị để phân phát quảng cáo và giới hạn
  tần suất.
- Quảng cáo xuất hiện dưới dạng banner ở gói miễn phí và thỉnh thoảng một
  interstitial — **bị gỡ hoàn toàn khi mua Lifetime Pro**.

Xem chính sách riêng tư của Google tại <https://policies.google.com/privacy>.

## 4. Mua hàng trong ứng dụng

Lifetime Pro là giao dịch mua một lần, không tiêu hao, được xử lý hoàn
toàn bởi **Apple App Store** hoặc **Google Play** (hệ thống thanh toán của
nền tảng bạn). SubTrack không xử lý thanh toán và không nhìn thấy thông tin
thanh toán của bạn.

## 5. Thông báo

Với sự cho phép của bạn (chỉ được yêu cầu sau khi bạn thêm đăng ký đầu
tiên), ứng dụng lên lịch nhắc nhở cục bộ cho các lần gia hạn sắp tới và
ngày kết thúc dùng thử. Nhắc nhở được tạo và gửi trên thiết bị; không dữ
liệu nào về chúng rời khỏi thiết bị.

## 6. Quyền hạn

| Quyền | Mục đích |
| --- | --- |
| Thông báo (`POST_NOTIFICATIONS`) | Nhắc nhở gia hạn/dùng thử cục bộ (Android 13+) |
| Internet / Trạng thái mạng | Quảng cáo AdMob và mua trong ứng dụng |
| Thanh toán (`com.android.vending.BILLING`) | Mua Lifetime Pro (Android) |

Ứng dụng không bao giờ yêu cầu quyền SMS, danh bạ, vị trí, camera,
microphone hay bộ nhớ.

## 7. Dịch vụ bên thứ ba

Các dịch vụ bên ngoài duy nhất liên quan:

1. **Google AdMob** — phân phát quảng cáo không cá nhân hóa ở gói miễn phí.
2. **Apple App Store / Google Play** — xử lý giao dịch mua Lifetime Pro.

Cả hai đều chịu sự điều chỉnh của chính sách quyền riêng tư riêng của họ.

## 8. Quyền riêng tư của trẻ em

Ứng dụng không cố ý thu thập thông tin cá nhân của bất kỳ ai, kể cả trẻ em.
Nếu bạn tin rằng trẻ em đã cung cấp thông tin cá nhân qua luồng mua hàng
trong cửa hàng, hãy liên hệ với chúng tôi và chúng tôi sẽ xóa nếu có thể
(giao dịch mua trong cửa hàng do cửa hàng quản lý, không phải chúng tôi).

## 9. Xóa dữ liệu

Vì SubTrack không lưu dữ liệu cá nhân trên bất kỳ máy chủ nào, không có gì
để chúng tôi xóa thay bạn. Để xóa dữ liệu của bạn:

- Xóa từng đăng ký trong ứng dụng, **hoặc**
- Gỡ cài đặt ứng dụng (iOS/Android), hoặc xóa dữ liệu trang (web).

## 10. Thay đổi chính sách

Nếu chính sách này thay đổi, bản cập nhật sẽ được đăng trên trang này với
ngày hiệu lực mới. Các thay đổi quan trọng cũng được phản ánh trong màn
hình Giới thiệu của ứng dụng.

## 11. Liên hệ

Câu hỏi về chính sách này: vui lòng mở issue tại
<https://github.com/hoangsoft90/SubscriptionTracker> hoặc liên hệ qua kho
GitHub của ứng dụng.
