import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../settings/data/settings_repository.dart';

/// In-memory snapshot of which guidance steps/tours the user has already seen.
///
/// Persisted through the M0 `app_settings` table (project rule: no
/// shared_preferences) so seen-state survives relaunches but stays in the
/// same storage path as every other setting.
class GuidanceState {
  const GuidanceState({
    this.completedStepIds = const {},
    this.seenTourIds = const {},
  });

  /// Steps the user has completed/acknowledged (persisted, one-shot).
  final Set<String> completedStepIds;

  /// Tours fully completed or explicitly skipped — never shown again.
  final Set<String> seenTourIds;

  GuidanceState copyWith({
    Set<String>? completedStepIds,
    Set<String>? seenTourIds,
  }) {
    return GuidanceState(
      completedStepIds: completedStepIds ?? this.completedStepIds,
      seenTourIds: seenTourIds ?? this.seenTourIds,
    );
  }
}

/// Loads/persists in-app guidance state and decides **when** to show a tour.
///
/// Trigger rules (requirement: show once for new users, never spam):
/// 1. A tour shows only if its id is NOT in `seenTourIds` (once per tour).
/// 2. Completing the last step or pressing Skip marks the whole tour as seen.
/// 3. Individual steps are recorded so a re-opened app does not repeat the
///    same step, and so per-element badges can hide once acknowledged.
///
/// Storage layout (app_settings, comma-joined like `onboardingPresets`):
/// - `guidance.steps` → "step1,step2"
/// - `guidance.tours` → "tour1,tour2"
class GuidanceController extends AsyncNotifier<GuidanceState> {
  static const _stepsKey = 'guidance.steps';
  static const _toursKey = 'guidance.tours';

  @override
  Future<GuidanceState> build() async {
    final repo = await ref.watch(settingsRepositoryProvider.future);
    return GuidanceState(
      completedStepIds: await _parse(repo, _stepsKey),
      seenTourIds: await _parse(repo, _toursKey),
    );
  }

  Future<Set<String>> _parse(SettingsRepository repo, String key) async {
    final raw = await repo.get(key);
    if (raw == null || raw.isEmpty) return const <String>{};
    return raw.split(',').toSet();
  }

  /// True when [tourId] should be shown right now: not seen yet.
  Future<bool> shouldShowTour(String tourId) async {
    final seen = state.value?.seenTourIds ?? const <String>{};
    return !seen.contains(tourId);
  }

  /// True when a step is not yet acknowledged (e.g. to keep a "New" badge
  /// visible until the user actually saw the related guidance).
  bool hasCompletedStep(String stepId) {
    final done = state.value?.completedStepIds ?? const <String>{};
    return done.contains(stepId);
  }

  /// Marks one step as seen and persists it. If it was the last step of a
  /// tour, the tour is also marked seen (never shown again).
  ///
  /// [tourStepIds] is the full ordered step id list of the tour the step
  /// belongs to — the tour counts as "seen" only once ALL of its steps are
  /// acknowledged, so unrelated steps from other tours never trip the check.
  Future<void> completeStep(
    String stepId, {
    String? tourId,
    List<String>? tourStepIds,
  }) async {
    final current = state.value!;
    final repo = await ref.read(settingsRepositoryProvider.future);
    final newSteps = {...current.completedStepIds, stepId};
    await repo.set(_stepsKey, newSteps.join(','));

    var newTours = current.seenTourIds;
    final allTourStepsDone = tourStepIds != null &&
        tourStepIds.isNotEmpty &&
        tourStepIds.every(newSteps.contains);
    if (tourId != null && allTourStepsDone) {
      newTours = {...newTours, tourId};
      await repo.set(_toursKey, newTours.join(','));
    }
    state = AsyncData(
      current.copyWith(completedStepIds: newSteps, seenTourIds: newTours),
    );
  }

  /// Marks a whole tour as seen (Done or Skip) — it will never be shown again.
  Future<void> markTourSeen(String tourId) async {
    final current = state.value!;
    final repo = await ref.read(settingsRepositoryProvider.future);
    final newTours = {...current.seenTourIds, tourId};
    await repo.set(_toursKey, newTours.join(','));
    state = AsyncData(current.copyWith(seenTourIds: newTours));
  }
}

final guidanceControllerProvider =
    AsyncNotifierProvider<GuidanceController, GuidanceState>(
  GuidanceController.new,
);
