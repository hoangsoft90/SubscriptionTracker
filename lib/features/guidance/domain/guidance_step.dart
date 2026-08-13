/// Preferred side for the guidance tooltip relative to its target element.
///
/// `auto` lets the overlay pick the side with the most free space (bottom
/// first, then top) so the popup never clips off-screen on small devices.
enum GuidancePlacement { auto, top, bottom, left, right }

/// A single in-app guidance step: which element to highlight, what to say.
///
/// Pure domain model — no Flutter/Riverpod imports. UI strings are resolved
/// by the caller (via `AppLocalizations`) before constructing a step, so the
/// model stays locale-agnostic and trivially testable.
class GuidanceStep {
  const GuidanceStep({
    required this.id,
    required this.targetKey,
    required this.title,
    required this.body,
    this.placement = GuidancePlacement.auto,
  });

  /// Stable id used for "has this step been seen" persistence
  /// (`guidance.step.<id>` in app_settings).
  final String id;

  /// Matches a `GlobalKey` registered by `GuidanceHost.targetKeys`.
  final String targetKey;

  /// Tooltip headline (already localized).
  final String title;

  /// Tooltip explanation body (already localized).
  final String body;

  /// Side hint for tooltip placement; `auto` resolves at layout time.
  final GuidancePlacement placement;
}
