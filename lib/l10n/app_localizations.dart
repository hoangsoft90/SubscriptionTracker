import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'SubTrack'**
  String get appName;

  /// No description provided for @featureNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get featureNew;

  /// No description provided for @guidanceSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get guidanceSkip;

  /// No description provided for @guidanceNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guidanceNext;

  /// No description provided for @guidanceDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get guidanceDone;

  /// No description provided for @guidanceStepCounter.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String guidanceStepCounter(int current, int total);

  /// No description provided for @guidanceHomeCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Your monthly cost at a glance'**
  String get guidanceHomeCostTitle;

  /// No description provided for @guidanceHomeCostBody.
  ///
  /// In en, this message translates to:
  /// **'This is everything you pay for subscriptions every month — including projected savings from ones you cancelled.'**
  String get guidanceHomeCostBody;

  /// No description provided for @guidanceHomeCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Every charge, on one calendar'**
  String get guidanceHomeCalendarTitle;

  /// No description provided for @guidanceHomeCalendarBody.
  ///
  /// In en, this message translates to:
  /// **'Tap View calendar to see exactly which day each recurring charge lands — and how much is due that day.'**
  String get guidanceHomeCalendarBody;

  /// No description provided for @disabledFreeLimitTitle.
  ///
  /// In en, this message translates to:
  /// **'Free limit reached'**
  String get disabledFreeLimitTitle;

  /// No description provided for @disabledFreeLimitBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used all 10 free slots. Cancel or archive a subscription, or upgrade to Pro to keep adding.'**
  String get disabledFreeLimitBody;

  /// No description provided for @disabledFreeLimitUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro'**
  String get disabledFreeLimitUnlock;

  /// No description provided for @onboardingPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Private by design'**
  String get onboardingPrivacyTitle;

  /// No description provided for @onboardingPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'Subscription data is stored locally on your device. The app does not require a backend or account.'**
  String get onboardingPrivacyBody;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your primary currency'**
  String get onboardingCurrencyTitle;

  /// No description provided for @onboardingCurrencyBody.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings. Existing amounts keep their own currency.'**
  String get onboardingCurrencyBody;

  /// No description provided for @onboardingPresetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your subscriptions'**
  String get onboardingPresetsTitle;

  /// No description provided for @onboardingPresetsBody.
  ///
  /// In en, this message translates to:
  /// **'Start fast with presets — prices and billing cycles are never pre-filled.'**
  String get onboardingPresetsBody;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip, start empty'**
  String get onboardingSkip;

  /// No description provided for @onboardingDone.
  ///
  /// In en, this message translates to:
  /// **'Start tracking'**
  String get onboardingDone;

  /// No description provided for @onboardingPresetsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected — they will pre-fill your add form'**
  String onboardingPresetsSelected(int count);

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get tabSubscriptions;

  /// No description provided for @tabMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get tabMore;

  /// No description provided for @dashboardMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get dashboardMonthly;

  /// No description provided for @dashboardYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get dashboardYearly;

  /// No description provided for @dashboardConvertedNote.
  ///
  /// In en, this message translates to:
  /// **'≈ converted to your primary currency at current exchange rates'**
  String get dashboardConvertedNote;

  /// No description provided for @dashboardFiveYear.
  ///
  /// In en, this message translates to:
  /// **'5-Year Cost at Current Prices'**
  String get dashboardFiveYear;

  /// No description provided for @dashboardUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming (7 days)'**
  String get dashboardUpcoming;

  /// No description provided for @dashboardToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dashboardToday;

  /// No description provided for @todayClear.
  ///
  /// In en, this message translates to:
  /// **'You\'re clear. No renewals or trials need attention today.'**
  String get todayClear;

  /// No description provided for @todayNothingDue.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get todayNothingDue;

  /// No description provided for @todayToday.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get todayToday;

  /// No description provided for @todayNext.
  ///
  /// In en, this message translates to:
  /// **'Next: {name} — in {days} day(s) ({date})'**
  String todayNext(String name, String days, String date);

  /// No description provided for @trialEndingToday.
  ///
  /// In en, this message translates to:
  /// **'Trial ending today — {name}'**
  String trialEndingToday(String name);

  /// No description provided for @trialEndingIn.
  ///
  /// In en, this message translates to:
  /// **'Trial ending in {days} day(s) — {name}'**
  String trialEndingIn(String name, int days);

  /// No description provided for @trialAfterPrice.
  ///
  /// In en, this message translates to:
  /// **'{name} — {price} after trial'**
  String trialAfterPrice(String name, String price);

  /// No description provided for @needsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention ({count})'**
  String needsAttention(int count);

  /// No description provided for @reviewAll.
  ///
  /// In en, this message translates to:
  /// **'Review all ({count})'**
  String reviewAll(int count);

  /// No description provided for @queueTrialEnding.
  ///
  /// In en, this message translates to:
  /// **'Trial ends in {days} day(s)'**
  String queueTrialEnding(int days);

  /// No description provided for @queueRenewalDue.
  ///
  /// In en, this message translates to:
  /// **'Renews on day {day}'**
  String queueRenewalDue(int day);

  /// No description provided for @queuePriceChanged.
  ///
  /// In en, this message translates to:
  /// **'Price changed — review it'**
  String get queuePriceChanged;

  /// No description provided for @queueStale.
  ///
  /// In en, this message translates to:
  /// **'Haven\'t reviewed {name} in a while. Still worth it?'**
  String queueStale(String name);

  /// No description provided for @dueAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions due soon'**
  String get dueAlertTitle;

  /// No description provided for @dueAlertBody.
  ///
  /// In en, this message translates to:
  /// **'Some of your subscriptions renew soon or have a trial ending:'**
  String get dueAlertBody;

  /// No description provided for @dueAlertRenewalToday.
  ///
  /// In en, this message translates to:
  /// **'{name} renews today'**
  String dueAlertRenewalToday(String name);

  /// No description provided for @dueAlertRenewalTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{name} renews tomorrow'**
  String dueAlertRenewalTomorrow(String name);

  /// No description provided for @dueAlertTrialEnding.
  ///
  /// In en, this message translates to:
  /// **'{name} — trial ends in {days} day(s)'**
  String dueAlertTrialEnding(String name, int days);

  /// No description provided for @dueAlertViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get dueAlertViewAll;

  /// No description provided for @dueAlertDismiss.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get dueAlertDismiss;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review {name}'**
  String reviewTitle(String name);

  /// No description provided for @reviewQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you still need this subscription?'**
  String get reviewQuestion;

  /// No description provided for @reviewLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get reviewLater;

  /// No description provided for @reviewCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel it'**
  String get reviewCancelAction;

  /// No description provided for @reviewKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get reviewKeep;

  /// No description provided for @savingsProjectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Projected monthly savings'**
  String get savingsProjectedLabel;

  /// No description provided for @savingsRealizedLabel.
  ///
  /// In en, this message translates to:
  /// **'Realized this month'**
  String get savingsRealizedLabel;

  /// No description provided for @savingsEstimatedNote.
  ///
  /// In en, this message translates to:
  /// **'Estimated — from cancelled / pending-cancellation subscriptions'**
  String get savingsEstimatedNote;

  /// No description provided for @calendarMonthCharges.
  ///
  /// In en, this message translates to:
  /// **'recurring charges'**
  String get calendarMonthCharges;

  /// No description provided for @calendarView.
  ///
  /// In en, this message translates to:
  /// **'View calendar'**
  String get calendarView;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Money calendar'**
  String get calendarTitle;

  /// No description provided for @calendarPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get calendarPrevMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get calendarNextMonth;

  /// No description provided for @calendarDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'No charges on this day'**
  String get calendarDayEmpty;

  /// No description provided for @calendarOneRenewal.
  ///
  /// In en, this message translates to:
  /// **'1 renewal'**
  String get calendarOneRenewal;

  /// No description provided for @calendarRenewals.
  ///
  /// In en, this message translates to:
  /// **'{count} renewals'**
  String calendarRenewals(int count);

  /// No description provided for @calendarTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get calendarTotal;

  /// No description provided for @filterPendingCancellation.
  ///
  /// In en, this message translates to:
  /// **'Pending cancellation'**
  String get filterPendingCancellation;

  /// No description provided for @priceChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Price changed'**
  String get priceChangedTitle;

  /// No description provided for @priceChangedSummary.
  ///
  /// In en, this message translates to:
  /// **'{delta} / month · {percent}%'**
  String priceChangedSummary(String delta, String percent);

  /// No description provided for @priceChangedYearly.
  ///
  /// In en, this message translates to:
  /// **'New yearly cost: {newYearly} (was {oldYearly})'**
  String priceChangedYearly(String newYearly, String oldYearly);

  /// No description provided for @priceChangedNewYearly.
  ///
  /// In en, this message translates to:
  /// **'New yearly cost: {newYearly}'**
  String priceChangedNewYearly(Object newYearly);

  /// No description provided for @priceChangedSave.
  ///
  /// In en, this message translates to:
  /// **'Save new price'**
  String get priceChangedSave;

  /// No description provided for @defaultLabel.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get defaultLabel;

  /// No description provided for @dueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String dueLabel(String date);

  /// No description provided for @dashboardUpcomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing due in the next 7 days'**
  String get dashboardUpcomingEmpty;

  /// No description provided for @dashboardTopThree.
  ///
  /// In en, this message translates to:
  /// **'Top 3 most expensive'**
  String get dashboardTopThree;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing tracked yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first subscription to see your recurring costs — privately, on your device.'**
  String get dashboardEmptyBody;

  /// No description provided for @dashboardEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get dashboardEmptyCta;

  /// No description provided for @trialBadge.
  ///
  /// In en, this message translates to:
  /// **'Trial'**
  String get trialBadge;

  /// No description provided for @subscriptionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get subscriptionsTitle;

  /// No description provided for @subscriptionsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get subscriptionsAdd;

  /// No description provided for @subscriptionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search subscriptions'**
  String get subscriptionsSearchHint;

  /// No description provided for @subscriptionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet'**
  String get subscriptionsEmptyTitle;

  /// No description provided for @subscriptionsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first one — it takes under 25 seconds.'**
  String get subscriptionsEmptyBody;

  /// No description provided for @subscriptionsNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get subscriptionsNoResults;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get sortAmount;

  /// No description provided for @sortNextBilling.
  ///
  /// In en, this message translates to:
  /// **'Next billing'**
  String get sortNextBilling;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// No description provided for @filterCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get filterCancelled;

  /// No description provided for @filterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get filterArchived;

  /// No description provided for @addTitle.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get addTitle;

  /// No description provided for @editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit subscription'**
  String get editTitle;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fieldAmount;

  /// No description provided for @fieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldCurrency;

  /// No description provided for @fieldCycle.
  ///
  /// In en, this message translates to:
  /// **'Billing cycle'**
  String get fieldCycle;

  /// No description provided for @fieldStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get fieldStartDate;

  /// No description provided for @fieldNextBilling.
  ///
  /// In en, this message translates to:
  /// **'Next billing date'**
  String get fieldNextBilling;

  /// No description provided for @fieldTrialToggle.
  ///
  /// In en, this message translates to:
  /// **'Free trial?'**
  String get fieldTrialToggle;

  /// No description provided for @fieldTrialEnd.
  ///
  /// In en, this message translates to:
  /// **'Trial end date'**
  String get fieldTrialEnd;

  /// No description provided for @fieldTrialSuggestion.
  ///
  /// In en, this message translates to:
  /// **'Suggested, please verify'**
  String get fieldTrialSuggestion;

  /// No description provided for @fieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// No description provided for @fieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldNotes;

  /// No description provided for @fieldCancellationUrl.
  ///
  /// In en, this message translates to:
  /// **'Cancellation URL (optional)'**
  String get fieldCancellationUrl;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// No description provided for @validationInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get validationInvalidAmount;

  /// No description provided for @validationInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid URL (https://…)'**
  String get validationInvalidUrl;

  /// No description provided for @cycleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get cycleWeekly;

  /// No description provided for @cycleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get cycleMonthly;

  /// No description provided for @cycleQuarterly.
  ///
  /// In en, this message translates to:
  /// **'Quarterly'**
  String get cycleQuarterly;

  /// No description provided for @cycleYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get cycleYearly;

  /// No description provided for @cycleCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get cycleCustom;

  /// No description provided for @customIntervalDays.
  ///
  /// In en, this message translates to:
  /// **'Interval (days)'**
  String get customIntervalDays;

  /// No description provided for @detailNextBilling.
  ///
  /// In en, this message translates to:
  /// **'Next billing'**
  String get detailNextBilling;

  /// No description provided for @detailTrialEnd.
  ///
  /// In en, this message translates to:
  /// **'Trial ends'**
  String get detailTrialEnd;

  /// No description provided for @detailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detailStatus;

  /// No description provided for @detailCancellationUrl.
  ///
  /// In en, this message translates to:
  /// **'Cancellation link'**
  String get detailCancellationUrl;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel subscription'**
  String get actionCancel;

  /// No description provided for @actionArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get actionArchive;

  /// No description provided for @actionActivate.
  ///
  /// In en, this message translates to:
  /// **'Activate'**
  String get actionActivate;

  /// No description provided for @actionUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get actionUnarchive;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete subscription?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This removes the subscription permanently.'**
  String get deleteConfirmBody;

  /// No description provided for @detailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get detailNotFound;

  /// No description provided for @tooltipEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get tooltipEdit;

  /// No description provided for @tooltipSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get tooltipSort;

  /// No description provided for @nextBillingLabel.
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String nextBillingLabel(String date);

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesAdd.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoriesAdd;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @categoryDeleteDefaultBlocked.
  ///
  /// In en, this message translates to:
  /// **'Default categories cannot be deleted'**
  String get categoryDeleteDefaultBlocked;

  /// No description provided for @uncategorized.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get uncategorized;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Primary currency'**
  String get settingsCurrency;

  /// No description provided for @settingsCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Changing it regroups totals; existing amounts keep their own currency.'**
  String get settingsCurrencyHint;

  /// No description provided for @settingsExchangeRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates (fallback)'**
  String get settingsExchangeRatesTitle;

  /// No description provided for @settingsExchangeRatesHint.
  ///
  /// In en, this message translates to:
  /// **'Used when offline. Live rates from the free API update automatically when online.'**
  String get settingsExchangeRatesHint;

  /// No description provided for @settingsExchangeRatesSave.
  ///
  /// In en, this message translates to:
  /// **'Save rates'**
  String get settingsExchangeRatesSave;

  /// No description provided for @settingsExchangeRatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid rate greater than 0 for {currency}'**
  String settingsExchangeRatesInvalid(String currency);

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settingsCategories;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'Renewal and trial-end reminders are scheduled locally on this device.'**
  String get settingsNotificationsHint;

  /// No description provided for @settingsNotificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get settingsNotificationsEnabled;

  /// No description provided for @settingsNotificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsNotificationsDisabled;

  /// No description provided for @settingsNotificationsEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get settingsNotificationsEnable;

  /// No description provided for @settingsNotificationsOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get settingsNotificationsOpenSettings;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageVietnamese.
  ///
  /// In en, this message translates to:
  /// **'Tiếng Việt'**
  String get languageVietnamese;

  /// No description provided for @aboutPrivacyLine.
  ///
  /// In en, this message translates to:
  /// **'No in-app analytics or tracking SDK. Non-personalized ads are served by Google AdMob on the free plan — upgrade to Pro to remove them. Subscription data is stored locally on your device.'**
  String get aboutPrivacyLine;

  /// No description provided for @presetPackGlobal.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get presetPackGlobal;

  /// No description provided for @presetPackVn.
  ///
  /// In en, this message translates to:
  /// **'VN'**
  String get presetPackVn;

  /// No description provided for @freeSlotsBanner.
  ///
  /// In en, this message translates to:
  /// **'You have {count} free slots left'**
  String freeSlotsBanner(int count);

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'SubTrack Pro'**
  String get paywallTitle;

  /// No description provided for @paywallBody.
  ///
  /// In en, this message translates to:
  /// **'Remove the 10-subscription free limit and all ads with a single one-time purchase. No recurring billing, no account.'**
  String get paywallBody;

  /// No description provided for @paywallBuy.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro'**
  String get paywallBuy;

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get paywallRestore;

  /// No description provided for @paywallPurchased.
  ///
  /// In en, this message translates to:
  /// **'You\'re Pro — thanks for supporting private software!'**
  String get paywallPurchased;

  /// No description provided for @paywallError.
  ///
  /// In en, this message translates to:
  /// **'Purchase couldn\'t be completed. Please try again.'**
  String get paywallError;

  /// No description provided for @paywallSlotsUsed.
  ///
  /// In en, this message translates to:
  /// **'{used} of 10 slots used'**
  String paywallSlotsUsed(int used);

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & Transfer'**
  String get backupTitle;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backupExport;

  /// No description provided for @backupExportBody.
  ///
  /// In en, this message translates to:
  /// **'Share a JSON backup file with your subscriptions, categories and settings — no cloud.'**
  String get backupExportBody;

  /// No description provided for @backupImport.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get backupImport;

  /// No description provided for @backupImportBody.
  ///
  /// In en, this message translates to:
  /// **'Restore data from a backup file on this device.'**
  String get backupImportBody;

  /// No description provided for @backupPreview.
  ///
  /// In en, this message translates to:
  /// **'Found {subscriptions} subscriptions, {categories} categories'**
  String backupPreview(int subscriptions, int categories);

  /// No description provided for @backupSettingsSummary.
  ///
  /// In en, this message translates to:
  /// **'Settings: primary currency {currency}'**
  String backupSettingsSummary(String currency);

  /// No description provided for @backupMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get backupMerge;

  /// No description provided for @backupMergeBody.
  ///
  /// In en, this message translates to:
  /// **'Keep existing data; items with new IDs are added. Nothing is removed.'**
  String get backupMergeBody;

  /// No description provided for @backupReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace All'**
  String get backupReplace;

  /// No description provided for @backupReplaceConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data?'**
  String get backupReplaceConfirmTitle;

  /// No description provided for @backupReplaceConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Existing categories, subscriptions and settings will be removed and replaced by the backup.'**
  String get backupReplaceConfirmBody;

  /// No description provided for @backupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup exported'**
  String get backupExported;

  /// No description provided for @backupImported.
  ///
  /// In en, this message translates to:
  /// **'Backup imported'**
  String get backupImported;

  /// No description provided for @backupErrorInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'This file is not a SubTrack backup.'**
  String get backupErrorInvalidFile;

  /// No description provided for @backupErrorFutureSchema.
  ///
  /// In en, this message translates to:
  /// **'This backup was made by a newer version of SubTrack and cannot be imported.'**
  String get backupErrorFutureSchema;

  /// No description provided for @presetNetflix.
  ///
  /// In en, this message translates to:
  /// **'Netflix'**
  String get presetNetflix;

  /// No description provided for @presetSpotify.
  ///
  /// In en, this message translates to:
  /// **'Spotify'**
  String get presetSpotify;

  /// No description provided for @presetYoutubePremium.
  ///
  /// In en, this message translates to:
  /// **'YouTube Premium'**
  String get presetYoutubePremium;

  /// No description provided for @presetAppleMusic.
  ///
  /// In en, this message translates to:
  /// **'Apple Music'**
  String get presetAppleMusic;

  /// No description provided for @presetIcloudPlus.
  ///
  /// In en, this message translates to:
  /// **'iCloud+'**
  String get presetIcloudPlus;

  /// No description provided for @presetGoogleOne.
  ///
  /// In en, this message translates to:
  /// **'Google One'**
  String get presetGoogleOne;

  /// No description provided for @presetAmazonPrime.
  ///
  /// In en, this message translates to:
  /// **'Amazon Prime'**
  String get presetAmazonPrime;

  /// No description provided for @presetDisneyPlus.
  ///
  /// In en, this message translates to:
  /// **'Disney+'**
  String get presetDisneyPlus;

  /// No description provided for @presetChatgptPlus.
  ///
  /// In en, this message translates to:
  /// **'ChatGPT Plus'**
  String get presetChatgptPlus;

  /// No description provided for @presetAdobeCc.
  ///
  /// In en, this message translates to:
  /// **'Adobe Creative Cloud'**
  String get presetAdobeCc;

  /// No description provided for @presetNotion.
  ///
  /// In en, this message translates to:
  /// **'Notion'**
  String get presetNotion;

  /// No description provided for @presetGithubPro.
  ///
  /// In en, this message translates to:
  /// **'GitHub Pro'**
  String get presetGithubPro;

  /// No description provided for @presetFptPlay.
  ///
  /// In en, this message translates to:
  /// **'FPT Play'**
  String get presetFptPlay;

  /// No description provided for @presetGalaxyPlay.
  ///
  /// In en, this message translates to:
  /// **'Galaxy Play'**
  String get presetGalaxyPlay;

  /// No description provided for @presetVieon.
  ///
  /// In en, this message translates to:
  /// **'VieON'**
  String get presetVieon;

  /// No description provided for @presetZingMp3.
  ///
  /// In en, this message translates to:
  /// **'Zing MP3'**
  String get presetZingMp3;

  /// No description provided for @presetNhaccuatui.
  ///
  /// In en, this message translates to:
  /// **'NhacCuaTui'**
  String get presetNhaccuatui;

  /// No description provided for @presetKg.
  ///
  /// In en, this message translates to:
  /// **'K+'**
  String get presetKg;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get errorTitle;

  /// No description provided for @errorBody.
  ///
  /// In en, this message translates to:
  /// **'\"{path}\" is not a valid page in SubTrack.'**
  String errorBody(String path);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
