import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/calendar/date_utils.dart';
import '../../../core/providers.dart';
import '../data/subscription_repository.dart';
import '../domain/price_history.dart';
import '../domain/subscription.dart';
import '../domain/subscription_status.dart';

/// Sort key for the subscriptions list.
enum SubscriptionSort { name, amount, nextBilling }

/// Filter state for the list (status + optional category).
class SubscriptionFilter {
  const SubscriptionFilter({this.status, this.categoryId});

  final SubscriptionStatus? status;
  final String? categoryId;

  SubscriptionFilter copyWith({SubscriptionStatus? status, String? categoryId}) {
    return SubscriptionFilter(
      status: status ?? this.status,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

class SubscriptionListState {
  const SubscriptionListState({
    required this.subscriptions,
    required this.query,
    required this.sort,
    required this.filter,
  });

  final List<Subscription> subscriptions;
  final String query;
  final SubscriptionSort sort;
  final SubscriptionFilter filter;

  /// Filtered, searched and sorted view of [subscriptions].
  List<Subscription> get visible {
    var list = subscriptions.where((s) {
      if (filter.status != null && s.status != filter.status) return false;
      if (filter.categoryId != null && s.categoryId != filter.categoryId) {
        return false;
      }
      return true;
    }).toList();

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      list = list.where((s) => s.name.toLowerCase().contains(q)).toList();
    }

    switch (sort) {
      case SubscriptionSort.name:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case SubscriptionSort.amount:
        list.sort((a, b) => a.amountMinor.compareTo(b.amountMinor));
      case SubscriptionSort.nextBilling:
        list.sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    }
    return list;
  }

  SubscriptionListState copyWith({
    List<Subscription>? subscriptions,
    String? query,
    SubscriptionSort? sort,
    SubscriptionFilter? filter,
  }) {
    return SubscriptionListState(
      subscriptions: subscriptions ?? this.subscriptions,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      filter: filter ?? this.filter,
    );
  }
}

class SubscriptionListController extends AsyncNotifier<SubscriptionListState> {
  @override
  Future<SubscriptionListState> build() async {
    final repo = await ref.watch(subscriptionRepositoryProvider.future);
    final all = await repo.getAll();
    return SubscriptionListState(
      subscriptions: all,
      query: '',
      sort: SubscriptionSort.nextBilling,
      filter: const SubscriptionFilter(),
    );
  }

  Future<void> reload() async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final all = await repo.getAll();
    state = AsyncData(state.value!.copyWith(subscriptions: all));
  }

  void setQuery(String query) {
    state = AsyncData(state.value!.copyWith(query: query));
  }

  void setSort(SubscriptionSort sort) {
    state = AsyncData(state.value!.copyWith(sort: sort));
  }

  void setStatusFilter(SubscriptionStatus? status) {
    state = AsyncData(state.value!.copyWith(
      filter: SubscriptionFilter(
        status: status,
        categoryId: state.value!.filter.categoryId,
      ),
    ));
  }

  Future<String> add(Subscription subscription) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final id = await repo.insert(subscription);
    // Re-subscribe rule (plan2_final §4.2): a new ACTIVE subscription matching
    // a CANCELLED one by name (case-insensitive) supersedes the old record so
    // its Realized Savings stops accumulating.
    if (subscription.status == SubscriptionStatus.active) {
      await _supersedeSameNameCancelled(repo, subscription.name, DateTime.now());
    }
    await reload();
    return id;
  }

  /// Marks any CANCELLED subscription with the same [name] (case-insensitive)
  /// as superseded as of [now] — stops its savings, hides it from the active
  /// list (plan2_final §4.2).
  Future<void> _supersedeSameNameCancelled(
    SubscriptionRepository repo,
    String name,
    DateTime now,
  ) async {
    final all = await repo.getAll();
    for (final sub in all) {
      if (sub.status != SubscriptionStatus.cancelled) continue;
      if (sub.supersededAt != null) continue;
      if (sub.name.toLowerCase() != name.toLowerCase()) continue;
      await repo.update(sub.copyWith(supersededAt: now, updatedAt: now));
    }
  }

  /// Review action "Keep" (plan2_final §3.4): records today as reviewed and
  /// clears any unacknowledged price-change marker.
  Future<void> markReviewed(String id) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final existing = await repo.getById(id);
    if (existing == null) return;
    final now = DateTime.now();
    await repo.update(existing.copyWith(
      lastReviewedAt: now,
      previousAmountMinor: null,
      updatedAt: now,
    ));
    await reload();
  }

  /// Review action "Cancel" (plan2_final §3.4/§5): moves to
  /// PENDING_CANCELLATION (auto-transitions to CANCELLED at the next billing
  /// date via reconcile()).
  Future<void> cancelSubscription(String id) async {
    await setStatus(id, SubscriptionStatus.pendingCancellation);
  }

  Future<void> updateSubscription(Subscription subscription) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    await repo.update(subscription);
    await reload();
  }

  /// Writes a `subscription_price_history` row for the subscription's current
  /// price (plan2_final §7), effective today. Called by the edit form when an
  /// amount change was confirmed.
  Future<void> recordPriceChange(String subscriptionId, Subscription current) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final now = DateTime.now();
    await repo.insertPriceHistory(PriceHistoryEntry(
      id: const Uuid().v4(),
      subscriptionId: subscriptionId,
      amountMinor: current.amountMinor,
      currency: current.currency,
      effectiveFrom: DateUtils.localMidnight(now),
      createdAt: now,
    ));
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    await repo.delete(id);
    await reload();
  }

  Future<void> setStatus(String id, SubscriptionStatus status) async {
    final repo = await ref.read(subscriptionRepositoryProvider.future);
    final existing = await repo.getById(id);
    if (existing == null) return;
    await repo.update(
      existing.copyWith(status: status, updatedAt: DateTime.now()),
    );
    await reload();
  }
}

final subscriptionListControllerProvider =
    AsyncNotifierProvider<SubscriptionListController, SubscriptionListState>(
  SubscriptionListController.new,
);
