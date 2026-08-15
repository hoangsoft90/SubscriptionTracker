// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'SubTrack';

  @override
  String get featureNew => 'Mới';

  @override
  String get guidanceSkip => 'Bỏ qua';

  @override
  String get guidanceNext => 'Tiếp theo';

  @override
  String get guidanceDone => 'Xong';

  @override
  String guidanceStepCounter(int current, int total) {
    return 'Bước $current trên $total';
  }

  @override
  String get guidanceHomeCostTitle => 'Chi phí hàng tháng trong một cái nhìn';

  @override
  String get guidanceHomeCostBody =>
      'Đây là tổng chi phí đăng ký của bạn mỗi tháng — bao gồm cả khoản tiết kiệm dự kiến từ những đăng ký đã hủy.';

  @override
  String get guidanceHomeCalendarTitle => 'Mọi khoản phí, trên một lịch';

  @override
  String get guidanceHomeCalendarBody =>
      'Chạm Xem lịch để biết chính xác ngày nào mỗi khoản phí định kỳ đến hạn — và số tiền phải trả ngày đó.';

  @override
  String get disabledFreeLimitTitle => 'Đã đạt giới hạn miễn phí';

  @override
  String get disabledFreeLimitBody =>
      'Bạn đã dùng hết 10 chỗ miễn phí. Hãy hủy hoặc lưu trữ một đăng ký, hoặc nâng cấp Pro để tiếp tục thêm.';

  @override
  String get disabledFreeLimitUnlock => 'Mở khóa Pro';

  @override
  String get onboardingPrivacyTitle => 'Riêng tư bởi thiết kế';

  @override
  String get onboardingPrivacyBody =>
      'Dữ liệu đăng ký được lưu trữ cục bộ trên thiết bị của bạn. Ứng dụng không cần máy chủ hoặc tài khoản.';

  @override
  String get onboardingContinue => 'Tiếp tục';

  @override
  String get onboardingCurrencyTitle => 'Chọn đơn vị tiền tệ chính';

  @override
  String get onboardingCurrencyBody =>
      'Bạn có thể đổi bất cứ lúc nào trong Cài đặt. Số tiền hiện có giữ nguyên đơn vị tiền tệ của chúng.';

  @override
  String get onboardingPresetsTitle => 'Chọn các đăng ký của bạn';

  @override
  String get onboardingPresetsBody =>
      'Bắt đầu nhanh với gợi ý — giá và chu kỳ thanh toán không bao giờ được điền sẵn.';

  @override
  String get onboardingSkip => 'Bỏ qua, bắt đầu trống';

  @override
  String get onboardingDone => 'Bắt đầu theo dõi';

  @override
  String onboardingPresetsSelected(int count) {
    return 'Đã chọn $count — sẽ điền sẵn vào form thêm của bạn';
  }

  @override
  String get tabHome => 'Trang chủ';

  @override
  String get tabSubscriptions => 'Đăng ký';

  @override
  String get tabMore => 'Thêm';

  @override
  String get dashboardMonthly => 'Hàng tháng';

  @override
  String get dashboardYearly => 'Hàng năm';

  @override
  String get dashboardConvertedNote =>
      '≈ quy đổi sang tiền tệ chính theo tỷ giá hiện tại';

  @override
  String get dashboardFiveYear => 'Chi phí 5 năm theo giá hiện tại';

  @override
  String get dashboardUpcoming => 'Sắp tới (7 ngày)';

  @override
  String get dashboardToday => 'Hôm nay';

  @override
  String get todayClear =>
      'Bạn không có gì cần lưu ý hôm nay. Không có khoản gia hạn hay dùng thử nào.';

  @override
  String get todayNothingDue => 'Không có khoản nào đến hạn hôm nay';

  @override
  String get todayToday => 'hôm nay';

  @override
  String todayNext(String name, String days, String date) {
    return 'Tiếp theo: $name — trong $days ngày ($date)';
  }

  @override
  String trialEndingToday(String name) {
    return 'Dùng thử kết thúc hôm nay — $name';
  }

  @override
  String trialEndingIn(String name, int days) {
    return 'Dùng thử kết thúc trong $days ngày — $name';
  }

  @override
  String trialAfterPrice(String name, String price) {
    return '$name — $price sau khi dùng thử';
  }

  @override
  String needsAttention(int count) {
    return 'Cần lưu ý ($count)';
  }

  @override
  String reviewAll(int count) {
    return 'Xem tất cả ($count)';
  }

  @override
  String queueTrialEnding(int days) {
    return 'Dùng thử kết thúc trong $days ngày';
  }

  @override
  String queueRenewalDue(int day) {
    return 'Gia hạn vào ngày $day';
  }

  @override
  String get queuePriceChanged => 'Giá đã thay đổi — hãy xem lại';

  @override
  String queueStale(String name) {
    return 'Đã lâu chưa xem lại $name. Bạn vẫn cần nó chứ?';
  }

  @override
  String reviewTitle(String name) {
    return 'Xem lại $name';
  }

  @override
  String get reviewQuestion => 'Bạn vẫn cần đăng ký này chứ?';

  @override
  String get reviewLater => 'Để sau';

  @override
  String get reviewCancelAction => 'Hủy nó';

  @override
  String get reviewKeep => 'Giữ lại';

  @override
  String get savingsProjectedLabel => 'Tiết kiệm dự kiến hàng tháng';

  @override
  String get savingsRealizedLabel => 'Đã tiết kiệm tháng này';

  @override
  String get savingsEstimatedNote =>
      'Ước tính — từ các đăng ký đã hủy / đang chờ hủy';

  @override
  String get calendarMonthCharges => 'khoản phí định kỳ';

  @override
  String get calendarView => 'Xem lịch';

  @override
  String get calendarTitle => 'Lịch chi tiêu';

  @override
  String get calendarPrevMonth => 'Tháng trước';

  @override
  String get calendarNextMonth => 'Tháng sau';

  @override
  String get calendarDayEmpty => 'Không có khoản phí nào vào ngày này';

  @override
  String get calendarOneRenewal => '1 khoản gia hạn';

  @override
  String calendarRenewals(int count) {
    return '$count khoản gia hạn';
  }

  @override
  String get calendarTotal => 'Tổng';

  @override
  String get filterPendingCancellation => 'Đang chờ hủy';

  @override
  String get priceChangedTitle => 'Giá đã thay đổi';

  @override
  String priceChangedSummary(String delta, String percent) {
    return '$delta / tháng · $percent%';
  }

  @override
  String priceChangedYearly(String newYearly, String oldYearly) {
    return 'Chi phí năm mới: $newYearly (trước: $oldYearly)';
  }

  @override
  String priceChangedNewYearly(Object newYearly) {
    return 'Chi phí năm mới: $newYearly';
  }

  @override
  String get priceChangedSave => 'Lưu giá mới';

  @override
  String get defaultLabel => 'Mặc định';

  @override
  String dueLabel(String date) {
    return 'Đến hạn: $date';
  }

  @override
  String get dashboardUpcomingEmpty =>
      'Không có khoản nào đến hạn trong 7 ngày tới';

  @override
  String get dashboardTopThree => '3 đắt nhất';

  @override
  String get dashboardEmptyTitle => 'Chưa có gì để theo dõi';

  @override
  String get dashboardEmptyBody =>
      'Thêm đăng ký đầu tiên để xem chi phí định kỳ của bạn — riêng tư, ngay trên thiết bị.';

  @override
  String get dashboardEmptyCta => 'Thêm đăng ký';

  @override
  String get trialBadge => 'Dùng thử';

  @override
  String get subscriptionsTitle => 'Đăng ký';

  @override
  String get subscriptionsAdd => 'Thêm đăng ký';

  @override
  String get subscriptionsSearchHint => 'Tìm kiếm đăng ký';

  @override
  String get subscriptionsEmptyTitle => 'Chưa có đăng ký nào';

  @override
  String get subscriptionsEmptyBody =>
      'Chạm + để thêm đăng ký đầu tiên — chỉ mất dưới 25 giây.';

  @override
  String get subscriptionsNoResults => 'Không có kết quả';

  @override
  String get sortName => 'Tên';

  @override
  String get sortAmount => 'Số tiền';

  @override
  String get sortNextBilling => 'Kỳ thanh toán tới';

  @override
  String get filterAll => 'Tất cả';

  @override
  String get filterActive => 'Hoạt động';

  @override
  String get filterCancelled => 'Đã hủy';

  @override
  String get filterArchived => 'Đã lưu trữ';

  @override
  String get addTitle => 'Thêm đăng ký';

  @override
  String get editTitle => 'Sửa đăng ký';

  @override
  String get fieldName => 'Tên';

  @override
  String get fieldAmount => 'Số tiền';

  @override
  String get fieldCurrency => 'Tiền tệ';

  @override
  String get fieldCycle => 'Chu kỳ thanh toán';

  @override
  String get fieldStartDate => 'Ngày bắt đầu';

  @override
  String get fieldNextBilling => 'Ngày thanh toán tới';

  @override
  String get fieldTrialToggle => 'Dùng thử miễn phí?';

  @override
  String get fieldTrialEnd => 'Ngày kết thúc dùng thử';

  @override
  String get fieldTrialSuggestion => 'Đề xuất, vui lòng kiểm tra lại';

  @override
  String get fieldCategory => 'Danh mục';

  @override
  String get fieldNotes => 'Ghi chú';

  @override
  String get fieldCancellationUrl => 'Đường dẫn hủy (không bắt buộc)';

  @override
  String get save => 'Lưu';

  @override
  String get cancel => 'Hủy';

  @override
  String get delete => 'Xóa';

  @override
  String get validationRequired => 'Bắt buộc';

  @override
  String get validationInvalidAmount => 'Nhập số tiền hợp lệ';

  @override
  String get validationInvalidUrl => 'Nhập URL hợp lệ (https://…)';

  @override
  String get cycleWeekly => 'Hàng tuần';

  @override
  String get cycleMonthly => 'Hàng tháng';

  @override
  String get cycleQuarterly => 'Hàng quý';

  @override
  String get cycleYearly => 'Hàng năm';

  @override
  String get cycleCustom => 'Tùy chỉnh';

  @override
  String get customIntervalDays => 'Khoảng cách (ngày)';

  @override
  String get detailNextBilling => 'Thanh toán tới';

  @override
  String get detailTrialEnd => 'Kết thúc dùng thử';

  @override
  String get detailStatus => 'Trạng thái';

  @override
  String get detailCancellationUrl => 'Đường dẫn hủy';

  @override
  String get actionCancel => 'Hủy đăng ký';

  @override
  String get actionArchive => 'Lưu trữ';

  @override
  String get actionActivate => 'Kích hoạt';

  @override
  String get actionUnarchive => 'Bỏ lưu trữ';

  @override
  String get deleteConfirmTitle => 'Xóa đăng ký?';

  @override
  String get deleteConfirmBody => 'Thao tác này sẽ xóa vĩnh viễn đăng ký.';

  @override
  String get detailNotFound => 'Không tìm thấy';

  @override
  String get tooltipEdit => 'Chỉnh sửa';

  @override
  String get tooltipSort => 'Sắp xếp';

  @override
  String nextBillingLabel(String date) {
    return 'Tới: $date';
  }

  @override
  String get categoriesTitle => 'Danh mục';

  @override
  String get categoriesAdd => 'Danh mục mới';

  @override
  String get editCategory => 'Sửa danh mục';

  @override
  String get categoryName => 'Tên danh mục';

  @override
  String get categoryDeleteDefaultBlocked => 'Không thể xóa danh mục mặc định';

  @override
  String get uncategorized => 'Chưa phân loại';

  @override
  String get moreTitle => 'Thêm';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsCurrency => 'Tiền tệ chính';

  @override
  String get settingsCurrencyHint =>
      'Đổi sẽ nhóm lại tổng; số tiền hiện có giữ nguyên tiền tệ.';

  @override
  String get settingsExchangeRatesTitle => 'Tỷ giá hối đoái (dự phòng)';

  @override
  String get settingsExchangeRatesHint =>
      'Dùng khi ngoại tuyến. Tỷ giá trực tuyến từ API miễn phí tự cập nhật khi có mạng.';

  @override
  String get settingsExchangeRatesSave => 'Lưu tỷ giá';

  @override
  String settingsExchangeRatesInvalid(String currency) {
    return 'Nhập tỷ giá hợp lệ lớn hơn 0 cho $currency';
  }

  @override
  String get settingsTheme => 'Giao diện';

  @override
  String get settingsThemeSystem => 'Hệ thống';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsCategories => 'Danh mục';

  @override
  String get settingsNotificationsTitle => 'Thông báo';

  @override
  String get settingsNotificationsHint =>
      'Nhắc nhở gia hạn và kết thúc dùng thử được lên lịch cục bộ trên thiết bị này.';

  @override
  String get settingsNotificationsEnabled => 'Bật';

  @override
  String get settingsNotificationsDisabled => 'Tắt';

  @override
  String get settingsNotificationsEnable => 'Bật thông báo';

  @override
  String get settingsNotificationsOpenSettings => 'Mở cài đặt';

  @override
  String get settingsAbout => 'Giới thiệu';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get languageSystem => 'Theo hệ thống';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get aboutPrivacyLine =>
      'Không có SDK phân tích hoặc theo dõi trong ứng dụng. Quảng cáo không cá nhân hóa được phân phối bởi Google AdMob ở gói miễn phí — nâng cấp Pro để tắt. Dữ liệu đăng ký được lưu trữ cục bộ trên thiết bị của bạn.';

  @override
  String get presetPackGlobal => 'Toàn cầu';

  @override
  String get presetPackVn => 'VN';

  @override
  String freeSlotsBanner(int count) {
    return 'Bạn còn $count chỗ trống miễn phí';
  }

  @override
  String get paywallTitle => 'SubTrack Pro';

  @override
  String get paywallBody =>
      'Xóa giới hạn 10 đăng ký miễn phí và toàn bộ quảng cáo chỉ với một lần mua duy nhất. Không phí định kỳ, không tài khoản.';

  @override
  String get paywallBuy => 'Mở khóa Pro';

  @override
  String get paywallRestore => 'Khôi phục giao dịch mua';

  @override
  String get paywallPurchased =>
      'Bạn đã là Pro — cảm ơn đã ủng hộ phần mềm riêng tư!';

  @override
  String get paywallError =>
      'Không thể hoàn tất giao dịch mua. Vui lòng thử lại.';

  @override
  String paywallSlotsUsed(int used) {
    return '$used trên 10 chỗ đã dùng';
  }

  @override
  String get backupTitle => 'Sao lưu & chuyển';

  @override
  String get backupExport => 'Xuất sao lưu';

  @override
  String get backupExportBody =>
      'Chia sẻ tệp JSON sao lưu gồm đăng ký, danh mục và cài đặt — không cần đám mây.';

  @override
  String get backupImport => 'Nhập sao lưu';

  @override
  String get backupImportBody =>
      'Khôi phục dữ liệu từ tệp sao lưu trên thiết bị này.';

  @override
  String backupPreview(int subscriptions, int categories) {
    return 'Tìm thấy $subscriptions đăng ký, $categories danh mục';
  }

  @override
  String backupSettingsSummary(String currency) {
    return 'Cài đặt: tiền tệ chính $currency';
  }

  @override
  String get backupMerge => 'Gộp';

  @override
  String get backupMergeBody =>
      'Giữ dữ liệu hiện có; các mục có ID mới được thêm vào. Không xóa gì.';

  @override
  String get backupReplace => 'Thay thế tất cả';

  @override
  String get backupReplaceConfirmTitle => 'Thay thế toàn bộ dữ liệu?';

  @override
  String get backupReplaceConfirmBody =>
      'Danh mục, đăng ký và cài đặt hiện có sẽ bị xóa và thay bằng dữ liệu sao lưu.';

  @override
  String get backupExported => 'Đã xuất sao lưu';

  @override
  String get backupImported => 'Đã nhập sao lưu';

  @override
  String get backupErrorInvalidFile => 'Tệp này không phải sao lưu SubTrack.';

  @override
  String get backupErrorFutureSchema =>
      'Tệp sao lưu này được tạo bởi phiên bản SubTrack mới hơn và không thể nhập.';

  @override
  String get presetNetflix => 'Netflix';

  @override
  String get presetSpotify => 'Spotify';

  @override
  String get presetYoutubePremium => 'YouTube Premium';

  @override
  String get presetAppleMusic => 'Apple Music';

  @override
  String get presetIcloudPlus => 'iCloud+';

  @override
  String get presetGoogleOne => 'Google One';

  @override
  String get presetAmazonPrime => 'Amazon Prime';

  @override
  String get presetDisneyPlus => 'Disney+';

  @override
  String get presetChatgptPlus => 'ChatGPT Plus';

  @override
  String get presetAdobeCc => 'Adobe Creative Cloud';

  @override
  String get presetNotion => 'Notion';

  @override
  String get presetGithubPro => 'GitHub Pro';

  @override
  String get presetFptPlay => 'FPT Play';

  @override
  String get presetGalaxyPlay => 'Galaxy Play';

  @override
  String get presetVieon => 'VieON';

  @override
  String get presetZingMp3 => 'Zing MP3';

  @override
  String get presetNhaccuatui => 'NhacCuaTui';

  @override
  String get presetKg => 'K+';

  @override
  String get errorTitle => 'Không tìm thấy trang';

  @override
  String errorBody(String path) {
    return '\"$path\" không phải là một trang hợp lệ trong SubTrack.';
  }
}
