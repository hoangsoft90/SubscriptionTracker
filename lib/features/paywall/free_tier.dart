import '../subscriptions/domain/subscription.dart';

/// Free-tier state for the paywall gating (spec §2.8).
///
/// ACTIVE and PENDING_CANCELLATION subscriptions consume a slot (plan2_final
/// §5 — pending-cancellation is still an active charge); CANCELLED and
/// ARCHIVED rows do not count. Pro lifts the limit entirely.
enum FreeTierState {
  /// 1–8 active subscriptions (or Pro): the add flow proceeds with no
  /// paywall interference.
  noInterference,

  /// 9–10 active subscriptions: adding still works, with a light banner
  /// "You have N free slots left".
  slotsLeft,

  /// 11+ (i.e. 10 active and adding one more): adding is hard-blocked and
  /// the user is directed to the Lifetime Pro paywall.
  hardBlock,
}

/// The free limit on paywall-slot subscriptions.
const int freeTierLimit = 10;

/// Subscriptions consuming a free-tier slot: ACTIVE + PENDING_CANCELLATION
/// (plan2_final §5 — only CANCELLED/ARCHIVED free a slot).
int paywallSlotCount(Iterable<Subscription> subs) =>
    subs.where((s) => s.status.countsTowardPaywall).length;

/// Computes the free-tier state from the active subscription count.
FreeTierState freeTierState({required int activeCount, required bool isPro}) {
  if (isPro) return FreeTierState.noInterference;
  if (activeCount < freeTierLimit - 1) return FreeTierState.noInterference;
  if (activeCount == freeTierLimit - 1 || activeCount == freeTierLimit) {
    return FreeTierState.slotsLeft;
  }
  return FreeTierState.hardBlock;
}

/// Free slots remaining before the hard limit (1..10); 0 at the limit.
int freeSlotsLeft(int activeCount) =>
    (freeTierLimit - activeCount).clamp(0, freeTierLimit);
