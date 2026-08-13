import '../../features/categories/data/category_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/subscriptions/data/subscription_repository.dart';

/// Platform storage backend exposing the three typed repositories.
///
/// - Native (iOS/Android): SQLite via [AppDatabase] (sqflite).
/// - Web: browser localStorage via [LocalStorageStore].
///
/// Controllers and business logic depend only on this interface — they never
/// see SQL or localStorage keys, so the platform switch is invisible above
/// the data layer.
abstract class StorageBackend {
  SubscriptionRepository get subscriptions;
  CategoryRepository get categories;
  SettingsRepository get settings;
}
