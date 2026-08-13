import 'dart:ui';

import '../domain/guidance_step.dart';

/// Gap kept between the spotlight target and the tooltip card.
const double kTooltipGap = 12;

/// Horizontal margin from screen edges so the tooltip never clips.
const double kTooltipScreenMargin = 16;

/// Result of resolving a tooltip position.
class TooltipPlacement {
  const TooltipPlacement({required this.topLeft, required this.side, required this.arrowDx});

  /// Top-left corner of the tooltip card in global coordinates.
  final Offset topLeft;

  /// Which side of the target the card ended up on (for the arrow).
  final GuidancePlacement side;

  /// Horizontal center of the target in global coords — the arrow points at it.
  final double arrowDx;
}

/// Max vertical coordinate the tooltip's top edge may reach so it stays on
/// screen. Never below `margin` even on tiny screens.
double _maxTop(double screen, double tooltip, double margin) {
  return (screen - tooltip - margin).clamp(margin, double.infinity);
}

/// Computes the tooltip card's top-left corner so it stays **on screen** for
/// any target position/size (responsive requirement).
///
/// Strategy (requirement: auto position based on the target element):
/// 1. Prefer placing the card below the target (standard reading flow).
/// 2. If there is not enough room below, flip above the target.
/// 3. If even that fails (tiny screens), clamp into the viewport.
/// 4. Horizontally: center the card on the target, then clamp so neither edge
///    leaves the screen.
///
/// Pure function — unit-testable without a widget tree.
TooltipPlacement computeTooltipPlacement({
  required Rect target,
  required Size screenSize,
  required Size tooltipSize,
  GuidancePlacement placement = GuidancePlacement.auto,
}) {
  // Horizontal: center on target, clamped to the screen.
  var dx = target.center.dx - tooltipSize.width / 2;
  dx = dx.clamp(
    kTooltipScreenMargin,
    (screenSize.width - tooltipSize.width - kTooltipScreenMargin)
        .clamp(kTooltipScreenMargin, double.infinity),
  );

  // Resolve the side: explicit hint wins; auto prefers bottom.
  GuidancePlacement side;
  switch (placement) {
    case GuidancePlacement.top:
    case GuidancePlacement.left:
    case GuidancePlacement.right:
    case GuidancePlacement.bottom:
      side = placement;
    case GuidancePlacement.auto:
      final roomBelow = screenSize.height - target.bottom - kTooltipGap;
      side = roomBelow >= tooltipSize.height + kTooltipScreenMargin
          ? GuidancePlacement.bottom
          : GuidancePlacement.top;
  }

  final maxTop = _maxTop(screenSize.height, tooltipSize.height, kTooltipScreenMargin);

  double dy;
  // `side` was resolved above (auto → bottom/top), so only the concrete
  // placements remain — no dead branch.
  switch (side) {
    case GuidancePlacement.top:
      dy = (target.top - tooltipSize.height - kTooltipGap).clamp(kTooltipScreenMargin, maxTop);
    case GuidancePlacement.bottom:
      dy = (target.bottom + kTooltipGap).clamp(kTooltipScreenMargin, maxTop);
    case GuidancePlacement.left:
      dy = (target.center.dy - tooltipSize.height / 2).clamp(kTooltipScreenMargin, maxTop);
      dx = (target.left - tooltipSize.width - kTooltipGap)
          .clamp(kTooltipScreenMargin, (screenSize.width - tooltipSize.width - kTooltipScreenMargin).clamp(kTooltipScreenMargin, double.infinity));
    case GuidancePlacement.right:
      dy = (target.center.dy - tooltipSize.height / 2).clamp(kTooltipScreenMargin, maxTop);
      dx = (target.right + kTooltipGap)
          .clamp(kTooltipScreenMargin, (screenSize.width - tooltipSize.width - kTooltipScreenMargin).clamp(kTooltipScreenMargin, double.infinity));
    case GuidancePlacement.auto:
      // Unreachable (auto was resolved above); kept only for switch
      // exhaustiveness on the enum.
      dy = (target.bottom + kTooltipGap).clamp(kTooltipScreenMargin, maxTop);
  }

  return TooltipPlacement(
    topLeft: Offset(dx, dy),
    side: side,
    arrowDx: target.center.dx,
  );
}
