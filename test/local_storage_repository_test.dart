import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/core/storage/local_storage_seeder.dart';
import 'package:subtrack/core/storage/local_storage_store.dart';
import 'package:subtrack/features/categories/data/local_storage_category_repository.dart';
import 'package:subtrack/features/categories/domain/category.dart';
import 'package:subtrack/features/settings/data/local_storage_settings_repository.dart';
import 'package:subtrack/features/subscriptions/data/local_storage_subscription_repository.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/price_history.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

/// In-memory [KeyValueStorage] so the whole localStorage layer is testable on
/// the VM without a browser (mirrors BrowserLocalStorage's semantics).
class MemoryKeyValueStorage implements KeyValueStorage {
  final Map<String, String> _data = {};

  @override
  String? getItem(String key) => _data[key];

  @override
  void setItem(String key, String value) => _data[key] = value;

  @override
  void removeItem(String key) => _data.remove(key);
}

LocalStorageStore _newStore() => LocalStorageStore(MemoryKeyValueStorage());

void main() {
  group('LocalStorageSeeder', () {
    test('seeds 11 default categories + primaryCurrency idempotently', () {
      final store = _newStore();
      LocalStorageSeeder(store).seed();
      LocalStorageSeeder(store).seed(); // second run must not duplicate

      final rows = store.readRows(LocalStorageStore.categoriesKey);
      expect(rows.length, 11);
      expect(rows.where((r) => (r['is_default'] as int) == 1).length, 11);
      expect(store.getSetting('primaryCurrency'), 'USD');
    });
  });

  group('LocalStorageCategoryRepository', () {
    test('CRUD round-trip', () async {
      final repo = LocalStorageCategoryRepository(_newStore());
      const category = Category(
          id: 'cat-1', name: 'Streaming', iconEmoji: '📺', colorHex: '#000000');
      await repo.insert(category);

      final all = await repo.getAll();
      expect(all.length, 1);
      expect(all.first.id, 'cat-1');
      expect(all.first.name, 'Streaming');
      expect(all.first.iconEmoji, '📺');
      expect(all.first.colorHex, '#000000');
      expect(all.first.isDefault, isFalse);

      await repo.update(category.copyWith(name: 'Streaming+'));
      final updated = (await repo.getAll()).first;
      expect(updated.name, 'Streaming+');

      await repo.delete('cat-1');
      expect(await repo.getAll(), isEmpty);
    });

    test('getAll orders defaults first, then by name', () async {
      final repo = LocalStorageCategoryRepository(_newStore());
      await repo.insert(const Category(id: 'z', name: 'Zeta'));
      await repo.insert(
          const Category(id: 'def', name: 'Apple', isDefault: true));
      await repo.insert(const Category(id: 'a', name: 'Alpha'));

      final all = await repo.getAll();
      expect(all.map((c) => c.id).toList(), ['def', 'a', 'z']);
    });

    test('default category cannot be deleted', () async {
      final repo = LocalStorageCategoryRepository(_newStore());
      await repo
          .insert(const Category(id: 'def', name: 'Default', isDefault: true));
      expect(() => repo.delete('def'), throwsArgumentError);
    });

    test('deleting an in-use custom category unassigns subscriptions',
        () async {
      final store = _newStore();
      final catRepo = LocalStorageCategoryRepository(store);
      final subRepo = LocalStorageSubscriptionRepository(store);
      await catRepo.insert(const Category(id: 'cat-x', name: 'Custom'));
      await subRepo.insert(_sampleSubscription(categoryId: 'cat-x'));

      await catRepo.delete('cat-x');

      final restored = await subRepo.getById('sub-1');
      expect(restored, isNotNull);
      expect(restored!.categoryId, isNull); // unassigned, row not lost
      expect(await catRepo.getAll(), isEmpty);
    });
  });

  group('LocalStorageSettingsRepository', () {
    test('set and get round-trip with upsert', () async {
      final repo = LocalStorageSettingsRepository(_newStore());
      expect(await repo.get('primaryCurrency'), isNull);
      await repo.set('primaryCurrency', 'USD');
      expect(await repo.get('primaryCurrency'), 'USD');
      await repo.set('primaryCurrency', 'VND');
      expect(await repo.get('primaryCurrency'), 'VND');
    });
  });

  group('LocalStorageSubscriptionRepository', () {
    test('CRUD round-trip preserves all fields incl. dates', () async {
      final store = _newStore();
      final repo = LocalStorageSubscriptionRepository(store);
      final categoryRepo = LocalStorageCategoryRepository(store);
      await categoryRepo.insert(const Category(id: 'cat-a', name: 'Cat A'));

      final sub = _sampleSubscription(categoryId: 'cat-a');
      await repo.insert(sub);

      final restored = await repo.getById(sub.id);
      expect(restored, isNotNull);
      expect(restored!.name, 'Netflix');
      expect(restored.amountMinor, 1499);
      expect(restored.currency, 'USD');
      expect(restored.billingCycle, BillingCycle.monthly);
      expect(restored.startDate, DateTime(2026, 8, 1));
      expect(restored.nextBillingDate, DateTime(2026, 8, 31));
      expect(restored.billingAnchorDay, 31);
      expect(restored.isTrial, isTrue);
      expect(restored.trialEndDate, DateTime(2026, 9, 15));
      expect(restored.cancellationUrl, 'https://example.com/cancel');
      expect(restored.status, SubscriptionStatus.active);
      expect(restored.categoryId, 'cat-a');
      expect(restored.reminderDaysBefore, [3, 1]);
      expect(restored.notes, 'Family plan');
      expect(restored.reviewIntervalDays, 90);
    });

    test('update modifies row', () async {
      final repo = LocalStorageSubscriptionRepository(_newStore());
      final sub = _sampleSubscription();
      await repo.insert(sub);

      final updated = sub.copyWith(
        amountMinor: 1999,
        status: SubscriptionStatus.cancelled,
        updatedAt: DateTime(2026, 8, 2),
      );
      await repo.update(updated);

      final restored = await repo.getById(sub.id);
      expect(restored!.amountMinor, 1999);
      expect(restored.status, SubscriptionStatus.cancelled);
    });

    test('delete removes row', () async {
      final repo = LocalStorageSubscriptionRepository(_newStore());
      final sub = _sampleSubscription();
      await repo.insert(sub);
      await repo.delete(sub.id);
      expect(await repo.getById(sub.id), isNull);
    });

    test('countByStatus', () async {
      final repo = LocalStorageSubscriptionRepository(_newStore());
      await repo.insert(_sampleSubscription());
      await repo.insert(_sampleSubscription(
          id: 's2', status: SubscriptionStatus.cancelled));
      expect(await repo.countByStatus(SubscriptionStatus.active), 1);
      expect(await repo.countByStatus(SubscriptionStatus.cancelled), 1);
    });
  });

  group('LocalStorage price history (plan2_final §7)', () {
    test('insertPriceHistory persists; getPriceHistory returns oldest first',
        () async {
      final repo = LocalStorageSubscriptionRepository(_newStore());
      final sub = _sampleSubscription();
      await repo.insert(sub);

      await repo.insertPriceHistory(PriceHistoryEntry(
        id: 'h1',
        subscriptionId: sub.id,
        amountMinor: 1499,
        currency: 'USD',
        effectiveFrom: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 7, 1),
      ));
      await repo.insertPriceHistory(PriceHistoryEntry(
        id: 'h2',
        subscriptionId: sub.id,
        amountMinor: 1999,
        currency: 'USD',
        effectiveFrom: DateTime(2026, 8, 1),
        createdAt: DateTime(2026, 8, 1),
      ));

      final history = await repo.getPriceHistory(sub.id);
      expect(history.length, 2);
      expect(history.first.id, 'h1');
      expect(history.first.amountMinor, 1499);
      expect(history.last.amountMinor, 1999);
    });

    test('deleting a subscription cascades its price history', () async {
      final repo = LocalStorageSubscriptionRepository(_newStore());
      final sub = _sampleSubscription();
      await repo.insert(sub);
      await repo.insertPriceHistory(PriceHistoryEntry(
        id: 'h1',
        subscriptionId: sub.id,
        amountMinor: 1499,
        currency: 'USD',
        effectiveFrom: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 7, 1),
      ));

      await repo.delete(sub.id);
      expect(await repo.getPriceHistory(sub.id), isEmpty);
    });
  });
}

Subscription _sampleSubscription({
  String id = 'sub-1',
  SubscriptionStatus status = SubscriptionStatus.active,
  String? categoryId,
}) {
  return Subscription(
    id: id,
    name: 'Netflix',
    amountMinor: 1499,
    currency: 'USD',
    billingCycle: BillingCycle.monthly,
    startDate: DateTime(2026, 8, 1),
    nextBillingDate: DateTime(2026, 8, 31),
    billingAnchorDay: 31,
    isTrial: true,
    trialEndDate: DateTime(2026, 9, 15),
    cancellationUrl: 'https://example.com/cancel',
    status: status,
    categoryId: categoryId,
    color: 0xFFE50914,
    iconEmoji: '📺',
    reminderDaysBefore: const [3, 1],
    notes: 'Family plan',
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );
}
