import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/guidance_controller.dart';
import '../domain/guidance_step.dart';
import 'spotlight_overlay.dart';

/// Runs a sequential in-app guidance tour over elements registered with
/// [targetKeys].
///
/// Behavior (requirement: sequential steps with Skip/Done, shown once):
/// - On mount, checks `shouldShowTour`; if the tour was already completed or
///   skipped (persisted in app_settings), nothing is shown — no spam.
/// - Step 1 → Step 2 → … → Finish, driven by the Next button (or by tapping
///   the dimmed backdrop). Each step highlights its target element.
/// - Skip aborts immediately and marks the tour seen; finishing the last step
///   marks it seen too — it never reappears.
/// - Step completion persists through [GuidanceController] (`app_settings`).
///
/// Usage:
/// ```dart
/// GuidanceHost(
///   tourId: 'firstRunHome',
///   steps: [GuidanceStep(id: 'cost', targetKey: 'costCard', ...)],
///   targetKeys: {'costCard': _costKey, 'calendarCard': _calendarKey},
///   child: HomeScreen(),
/// )
/// ```
class GuidanceHost extends ConsumerStatefulWidget {
  const GuidanceHost({
    super.key,
    required this.tourId,
    required this.steps,
    required this.targetKeys,
    required this.child,
    this.l10n,
  });

  final String tourId;
  final List<GuidanceStep> steps;
  final Map<String, GlobalKey> targetKeys;
  final Widget child;

  /// Localized labels; if null, the host uses the caller's defaults and the
  /// step text must already be localized (callers typically pass context.l10n
  /// strings here).
  final GuidanceLabels? l10n;

  @override
  ConsumerState<GuidanceHost> createState() => _GuidanceHostState();
}

/// Pre-localized UI strings for the tour chrome.
class GuidanceLabels {
  const GuidanceLabels({
    required this.skip,
    required this.next,
    required this.done,
    required this.stepCounter,
  });

  final String skip;
  final String next;
  final String done;

  /// Builds "Step {current} of {total}" for a 1-based step.
  final String Function(int current, int total) stepCounter;
}

class _GuidanceHostState extends ConsumerState<GuidanceHost> {
  OverlayEntry? _entry;
  int _stepIndex = 0;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Wait for the first frame so target GlobalKeys are laid out and can be
    // measured before we insert the overlay.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStart());
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  Future<void> _maybeStart() async {
    if (_started || !mounted) return;
    _started = true;
    final shouldShow =
        await ref.read(guidanceControllerProvider.notifier).shouldShowTour(widget.tourId);
    if (!shouldShow || !mounted || widget.steps.isEmpty) return;
    _showStep(0);
  }

  /// Measures the target element's global rect from its GlobalKey.
  Rect? _targetRect(String targetKey) {
    final key = widget.targetKeys[targetKey];
    final ctx = key?.currentContext;
    final box = ctx?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _showStep(int index) {
    if (!mounted) return;
    if (index >= widget.steps.length) {
      _finish();
      return;
    }
    final step = widget.steps[index];
    final rect = _targetRect(step.targetKey);
    // Keep the last good measurement as a fallback if the element scrolls
    // away mid-tour (the overlay then still points at its last position).
    if (rect != null) _lastRect = rect;

    if (rect == null) {
      // Target not found (e.g. empty state hides the card) — skip the step
      // rather than showing a spotlight over nothing.
      if (index >= widget.steps.length - 1) {
        _finish();
      } else {
        _showStep(index + 1);
      }
      return;
    }

    setState(() => _stepIndex = index);
    final existing = _entry;
    if (existing == null) {
      final entry = OverlayEntry(builder: (_) => _buildOverlay());
      _entry = entry;
      Overlay.of(context).insert(entry);
    } else {
      // Reuse the live entry — just rebuild it with the new step.
      existing.markNeedsBuild();
    }
  }

  Widget _buildOverlay() {
    final step = widget.steps[_stepIndex];
    final rect = _targetRect(step.targetKey);
    // Fallback: keep last measured rect if the element scrolled off.
    final target = rect ??
        _lastRect ??
        const Rect.fromLTWH(0, 0, 1, 1);

    return Directionality(
      textDirection: Directionality.of(context),
      child: SpotlightOverlay(
        targetRect: target,
        screenSize: MediaQuery.sizeOf(context),
        step: step,
        stepIndex: _stepIndex,
        totalSteps: widget.steps.length,
        skipLabel: widget.l10n?.skip ?? 'Skip',
        nextLabel: widget.l10n?.next ?? 'Next',
        doneLabel: widget.l10n?.done ?? 'Done',
        stepCounter: widget.l10n?.stepCounter(_stepIndex + 1, widget.steps.length) ??
            '${_stepIndex + 1} / ${widget.steps.length}',
        onSkip: _skip,
        onNext: _next,
      ),
    );
  }

  Rect? _lastRect;

  Future<void> _next() async {
    final step = widget.steps[_stepIndex];
    final rect = _targetRect(step.targetKey);
    if (rect != null) _lastRect = rect;
    await ref.read(guidanceControllerProvider.notifier).completeStep(
          step.id,
          tourId: widget.tourId,
          tourStepIds: widget.steps.map((s) => s.id).toList(),
        );
    if (!mounted) return;
    _showStep(_stepIndex + 1);
  }

  Future<void> _skip() async {
    // Skip = acknowledge every step (so per-step badges like FeatureBadge
    // disappear — they key off completedStepIds) AND mark the tour seen. The
    // last completeStep call auto-marks the tour seen via allTourStepsDone.
    final notifier = ref.read(guidanceControllerProvider.notifier);
    final stepIds = widget.steps.map((s) => s.id).toList();
    for (final step in widget.steps) {
      await notifier.completeStep(
        step.id,
        tourId: widget.tourId,
        tourStepIds: stepIds,
      );
    }
    if (!mounted) return;
    _finish();
  }

  void _finish() {
    _entry?.remove();
    _entry = null;
    setState(() => _started = false);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
