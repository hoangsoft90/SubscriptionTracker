import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:subtrack/core/notifications/notification_platform.dart';
import 'package:subtrack/core/providers.dart';
import 'package:subtrack/features/categories/domain/category.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';

import 'fakes.dart';

/// Widget-test harness: overrides providers with in-memory fakes (no sqflite,
/// so it works inside the fake-async zone of `testWidgets`).
class WidgetHarness {
  WidgetHarness({
    List<Subscription> subscriptions = const [],
    List<Category> categories = const [],
    bool onboardingCompleted = true,
    String primaryCurrency = 'USD',
    String? themeMode,
    String? language,
  }) {
    _subRepo = FakeSubscriptionRepository(subscriptions);
    _catRepo = FakeCategoryRepository(categories);
    _notifPlatform = FakeNotificationPlatform();
    _settingsRepo = FakeSettingsRepository({
      if (onboardingCompleted) 'onboardingCompleted': 'true',
      if (onboardingCompleted) 'primaryCurrency': primaryCurrency,
      'themeMode': ?themeMode,
      'language': ?language,
    });
  }

  late final FakeSubscriptionRepository _subRepo;
  late final FakeCategoryRepository _catRepo;
  late final FakeSettingsRepository _settingsRepo;
  late final FakeNotificationPlatform _notifPlatform;

  FakeSubscriptionRepository get subscriptionRepo => _subRepo;
  FakeSettingsRepository get settingsRepo => _settingsRepo;
  FakeNotificationPlatform get notificationPlatform => _notifPlatform;

  ProviderScope scope({required Widget child}) {
    return ProviderScope(overrides: [
      subscriptionRepositoryProvider.overrideWith((ref) => _subRepo),
      categoryRepositoryProvider.overrideWith((ref) => _catRepo),
      settingsRepositoryProvider.overrideWith((ref) => _settingsRepo),
      notificationPlatformProvider
          .overrideWithValue(_notifPlatform as NotificationPlatform),
    ], child: child);
  }

  ProviderContainer container() {
    return ProviderContainer(overrides: [
      subscriptionRepositoryProvider.overrideWith((ref) => _subRepo),
      categoryRepositoryProvider.overrideWith((ref) => _catRepo),
      settingsRepositoryProvider.overrideWith((ref) => _settingsRepo),
      notificationPlatformProvider
          .overrideWithValue(_notifPlatform as NotificationPlatform),
    ]);
  }
}
