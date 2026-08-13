// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'SubTrack';

  @override
  String get featureNew => 'New';

  @override
  String get guidanceSkip => 'Skip';

  @override
  String get guidanceNext => 'Next';

  @override
  String get guidanceDone => 'Done';

  @override
  String guidanceStepCounter(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get guidanceHomeCostTitle => 'Your monthly cost at a glance';

  @override
  String get guidanceHomeCostBody =>
      'This is everything you pay for subscriptions every month — including projected savings from ones you cancelled.';

  @override
  String get guidanceHomeCalendarTitle => 'Every charge, on one calendar';

  @override
  String get guidanceHomeCalendarBody =>
      'Tap View calendar to see exactly which day each recurring charge lands — and how much is due that day.';

  @override
  String get disabledFreeLimitTitle => 'Free limit reached';

  @override
  String get disabledFreeLimitBody =>
      'You\'ve used all 10 free slots. Cancel or archive a subscription, or upgrade to Pro to keep adding.';

  @override
  String get disabledFreeLimitUnlock => 'Unlock Pro';

  @override
  String get onboardingPrivacyTitle => 'Private by design';

  @override
  String get onboardingPrivacyBody =>
      'Subscription data is stored locally on your device. The app does not require a backend or account.';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingCurrencyTitle => 'Choose your primary currency';

  @override
  String get onboardingCurrencyBody =>
      'You can change this anytime in Settings. Existing amounts keep their own currency.';

  @override
  String get onboardingPresetsTitle => 'Pick your subscriptions';

  @override
  String get onboardingPresetsBody =>
      'Start fast with presets — prices and billing cycles are never pre-filled.';

  @override
  String get onboardingSkip => 'Skip, start empty';

  @override
  String get onboardingDone => 'Start tracking';

  @override
  String onboardingPresetsSelected(int count) {
    return '$count selected — they will pre-fill your add form';
  }

  @override
  String get tabHome => 'Home';

  @override
  String get tabSubscriptions => 'Subscriptions';

  @override
  String get tabMore => 'More';

  @override
  String get dashboardMonthly => 'Monthly';

  @override
  String get dashboardYearly => 'Yearly';

  @override
  String get dashboardFiveYear => '5-Year Cost at Current Prices';

  @override
  String get dashboardUpcoming => 'Upcoming (7 days)';

  @override
  String get dashboardToday => 'Today';

  @override
  String get todayClear =>
      'You\'re clear. No renewals or trials need attention today.';

  @override
  String get todayNothingDue => 'Nothing due today';

  @override
  String get todayToday => 'today';

  @override
  String todayNext(String name, String days, String date) {
    return 'Next: $name — in $days day(s) ($date)';
  }

  @override
  String trialEndingToday(String name) {
    return 'Trial ending today — $name';
  }

  @override
  String trialEndingIn(String name, int days) {
    return 'Trial ending in $days day(s) — $name';
  }

  @override
  String trialAfterPrice(String name, String price) {
    return '$name — $price after trial';
  }

  @override
  String needsAttention(int count) {
    return 'Needs attention ($count)';
  }

  @override
  String reviewAll(int count) {
    return 'Review all ($count)';
  }

  @override
  String queueTrialEnding(int days) {
    return 'Trial ends in $days day(s)';
  }

  @override
  String queueRenewalDue(int day) {
    return 'Renews on day $day';
  }

  @override
  String get queuePriceChanged => 'Price changed — review it';

  @override
  String queueStale(String name) {
    return 'Haven\'t reviewed $name in a while. Still worth it?';
  }

  @override
  String reviewTitle(String name) {
    return 'Review $name';
  }

  @override
  String get reviewQuestion => 'Do you still need this subscription?';

  @override
  String get reviewLater => 'Later';

  @override
  String get reviewCancelAction => 'Cancel it';

  @override
  String get reviewKeep => 'Keep';

  @override
  String get savingsProjectedLabel => 'Projected monthly savings';

  @override
  String get savingsRealizedLabel => 'Realized this month';

  @override
  String get savingsEstimatedNote =>
      'Estimated — from cancelled / pending-cancellation subscriptions';

  @override
  String get calendarMonthCharges => 'recurring charges';

  @override
  String get calendarView => 'View calendar';

  @override
  String get calendarTitle => 'Money calendar';

  @override
  String get calendarPrevMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get calendarDayEmpty => 'No charges on this day';

  @override
  String get calendarOneRenewal => '1 renewal';

  @override
  String calendarRenewals(int count) {
    return '$count renewals';
  }

  @override
  String get calendarTotal => 'Total';

  @override
  String get filterPendingCancellation => 'Pending cancellation';

  @override
  String get priceChangedTitle => 'Price changed';

  @override
  String priceChangedSummary(String delta, String percent) {
    return '$delta / month · $percent%';
  }

  @override
  String priceChangedYearly(String newYearly, String oldYearly) {
    return 'New yearly cost: $newYearly (was $oldYearly)';
  }

  @override
  String priceChangedNewYearly(Object newYearly) {
    return 'New yearly cost: $newYearly';
  }

  @override
  String get priceChangedSave => 'Save new price';

  @override
  String get defaultLabel => 'Default';

  @override
  String dueLabel(String date) {
    return 'Due $date';
  }

  @override
  String get dashboardUpcomingEmpty => 'Nothing due in the next 7 days';

  @override
  String get dashboardTopThree => 'Top 3 most expensive';

  @override
  String get dashboardEmptyTitle => 'Nothing tracked yet';

  @override
  String get dashboardEmptyBody =>
      'Add your first subscription to see your recurring costs — privately, on your device.';

  @override
  String get dashboardEmptyCta => 'Add subscription';

  @override
  String get trialBadge => 'Trial';

  @override
  String get subscriptionsTitle => 'Subscriptions';

  @override
  String get subscriptionsAdd => 'Add subscription';

  @override
  String get subscriptionsSearchHint => 'Search subscriptions';

  @override
  String get subscriptionsEmptyTitle => 'No subscriptions yet';

  @override
  String get subscriptionsEmptyBody =>
      'Tap + to add your first one — it takes under 25 seconds.';

  @override
  String get subscriptionsNoResults => 'No matches';

  @override
  String get sortName => 'Name';

  @override
  String get sortAmount => 'Amount';

  @override
  String get sortNextBilling => 'Next billing';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterCancelled => 'Cancelled';

  @override
  String get filterArchived => 'Archived';

  @override
  String get addTitle => 'Add subscription';

  @override
  String get editTitle => 'Edit subscription';

  @override
  String get fieldName => 'Name';

  @override
  String get fieldAmount => 'Amount';

  @override
  String get fieldCurrency => 'Currency';

  @override
  String get fieldCycle => 'Billing cycle';

  @override
  String get fieldStartDate => 'Start date';

  @override
  String get fieldNextBilling => 'Next billing date';

  @override
  String get fieldTrialToggle => 'Free trial?';

  @override
  String get fieldTrialEnd => 'Trial end date';

  @override
  String get fieldTrialSuggestion => 'Suggested, please verify';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldCancellationUrl => 'Cancellation URL (optional)';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationInvalidAmount => 'Enter a valid amount';

  @override
  String get validationInvalidUrl => 'Enter a valid URL (https://…)';

  @override
  String get cycleWeekly => 'Weekly';

  @override
  String get cycleMonthly => 'Monthly';

  @override
  String get cycleQuarterly => 'Quarterly';

  @override
  String get cycleYearly => 'Yearly';

  @override
  String get cycleCustom => 'Custom';

  @override
  String get customIntervalDays => 'Interval (days)';

  @override
  String get detailNextBilling => 'Next billing';

  @override
  String get detailTrialEnd => 'Trial ends';

  @override
  String get detailStatus => 'Status';

  @override
  String get detailCancellationUrl => 'Cancellation link';

  @override
  String get actionCancel => 'Cancel subscription';

  @override
  String get actionArchive => 'Archive';

  @override
  String get actionActivate => 'Activate';

  @override
  String get actionUnarchive => 'Unarchive';

  @override
  String get deleteConfirmTitle => 'Delete subscription?';

  @override
  String get deleteConfirmBody => 'This removes the subscription permanently.';

  @override
  String get detailNotFound => 'Not found';

  @override
  String get tooltipEdit => 'Edit';

  @override
  String get tooltipSort => 'Sort';

  @override
  String nextBillingLabel(String date) {
    return 'Next: $date';
  }

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesAdd => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryDeleteDefaultBlocked =>
      'Default categories cannot be deleted';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get moreTitle => 'More';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsCurrency => 'Primary currency';

  @override
  String get settingsCurrencyHint =>
      'Changing it regroups totals; existing amounts keep their own currency.';

  @override
  String get settingsTheme => 'Appearance';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsCategories => 'Categories';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageVietnamese => 'Tiếng Việt';

  @override
  String get aboutPrivacyLine =>
      'No in-app analytics or tracking SDK. Non-personalized ads are served by Google AdMob on the free plan — upgrade to Pro to remove them. Subscription data is stored locally on your device.';

  @override
  String get presetPackGlobal => 'Global';

  @override
  String get presetPackVn => 'VN';

  @override
  String freeSlotsBanner(int count) {
    return 'You have $count free slots left';
  }

  @override
  String get paywallTitle => 'SubTrack Pro';

  @override
  String get paywallBody =>
      'Remove the 10-subscription free limit and all ads with a single one-time purchase. No recurring billing, no account.';

  @override
  String get paywallBuy => 'Unlock Pro';

  @override
  String get paywallRestore => 'Restore Purchase';

  @override
  String get paywallPurchased =>
      'You\'re Pro — thanks for supporting private software!';

  @override
  String paywallSlotsUsed(int used) {
    return '$used of 10 slots used';
  }

  @override
  String get backupTitle => 'Backup & Transfer';

  @override
  String get backupExport => 'Export backup';

  @override
  String get backupExportBody =>
      'Share a JSON backup file with your subscriptions, categories and settings — no cloud.';

  @override
  String get backupImport => 'Import backup';

  @override
  String get backupImportBody =>
      'Restore data from a backup file on this device.';

  @override
  String backupPreview(int subscriptions, int categories) {
    return 'Found $subscriptions subscriptions, $categories categories';
  }

  @override
  String backupSettingsSummary(String currency) {
    return 'Settings: primary currency $currency';
  }

  @override
  String get backupMerge => 'Merge';

  @override
  String get backupMergeBody =>
      'Keep existing data; items with new IDs are added. Nothing is removed.';

  @override
  String get backupReplace => 'Replace All';

  @override
  String get backupReplaceConfirmTitle => 'Replace all data?';

  @override
  String get backupReplaceConfirmBody =>
      'Existing categories, subscriptions and settings will be removed and replaced by the backup.';

  @override
  String get backupExported => 'Backup exported';

  @override
  String get backupImported => 'Backup imported';

  @override
  String get backupErrorInvalidFile => 'This file is not a SubTrack backup.';

  @override
  String get backupErrorFutureSchema =>
      'This backup was made by a newer version of SubTrack and cannot be imported.';

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
  String get errorTitle => 'Page not found';

  @override
  String errorBody(String path) {
    return '\"$path\" is not a valid page in SubTrack.';
  }
}
