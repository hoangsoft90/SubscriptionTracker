import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/guidance_step.dart';
import 'tooltip_geometry.dart';

/// Padding added around the highlighted element so the spotlight hole is a
/// little larger than the element itself.
const double kSpotlightPadding = 8;

/// Fixed tooltip width; height is capped so placement is deterministic
/// without measuring widgets (content scrolls if it ever exceeds the cap).
const double kTooltipWidth = 280;
const double kTooltipMaxHeight = 260;

/// Renders the full-screen spotlight: dims everything, cuts a transparent
/// "hole" around the target element, and shows an auto-positioned tooltip
/// card with Skip / Next / Done actions.
///
/// Used inside an `OverlayEntry` (or the root Stack) by [GuidanceHost].
/// All strings come pre-localized from the caller.
class SpotlightOverlay extends StatelessWidget {
  const SpotlightOverlay({
    super.key,
    required this.targetRect,
    required this.screenSize,
    required this.step,
    required this.stepIndex,
    required this.totalSteps,
    required this.onSkip,
    required this.onNext,
    required this.skipLabel,
    required this.nextLabel,
    required this.doneLabel,
    required this.stepCounter,
  });

  /// Global rect of the highlighted element (measured via GlobalKey).
  final Rect targetRect;

  /// Full overlay size (typically `MediaQuery.sizeOf`).
  final Size screenSize;

  final GuidanceStep step;
  final int stepIndex;
  final int totalSteps;

  final VoidCallback onSkip;

  /// Advances to the next step, or finishes the tour on the last one.
  final VoidCallback onNext;

  final String skipLabel;
  final String nextLabel;
  final String doneLabel;
  final String stepCounter;

  @override
  Widget build(BuildContext context) {
    final hole = targetRect.inflate(kSpotlightPadding);

    // Deterministic placement: fixed width + capped height.
    final placement = computeTooltipPlacement(
      target: targetRect,
      screenSize: screenSize,
      tooltipSize: const Size(kTooltipWidth, kTooltipMaxHeight),
      placement: step.placement,
    );

    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surfaceContainerHighest;
    final isLast = stepIndex >= totalSteps - 1;

    // Self-contained full-size layer: expands to its parent's size and owns
    // its own Stack, so it works inside an OverlayEntry or anywhere else.
    return SizedBox.expand(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dimmed backdrop with a transparent hole over the target.
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(
                hole: hole,
                dimColor: Colors.black.withValues(alpha: 0.55),
                borderColor: theme.colorScheme.primary,
              ),
            ),
          ),
          // Tapping the dimmed area advances (same as Next) so the user
          // cannot get stuck; the card sits above and absorbs its own taps.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onNext,
            ),
          ),
          Positioned(
            left: placement.topLeft.dx,
            top: placement.topLeft.dy,
            width: kTooltipWidth,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _TooltipCard(
                  step: step,
                  isLast: isLast,
                  skipLabel: skipLabel,
                  nextLabel: nextLabel,
                  doneLabel: doneLabel,
                  stepCounter: stepCounter,
                  cardColor: cardColor,
                  onSkip: onSkip,
                  onNext: onNext,
                ),
                // Diamond arrow pointing at the target. Positioned relative
                // to the card's actual bounds (not the max-height cap):
                // card below target → arrow on the top edge; card above →
                // arrow on the bottom edge.
                if (placement.side == GuidancePlacement.bottom)
                  Positioned(
                    top: -_arrowSize / 2,
                    left: placement.arrowDx - placement.topLeft.dx - _arrowSize / 2,
                    child: _DiamondArrow(color: cardColor),
                  )
                else if (placement.side == GuidancePlacement.top)
                  Positioned(
                    bottom: -_arrowSize / 2,
                    left: placement.arrowDx - placement.topLeft.dx - _arrowSize / 2,
                    child: _DiamondArrow(color: cardColor),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({
    required this.step,
    required this.isLast,
    required this.skipLabel,
    required this.nextLabel,
    required this.doneLabel,
    required this.stepCounter,
    required this.cardColor,
    required this.onSkip,
    required this.onNext,
  });

  final GuidanceStep step;
  final bool isLast;
  final String skipLabel;
  final String nextLabel;
  final String doneLabel;
  final String stepCounter;
  final Color cardColor;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: cardColor,
      elevation: 6,
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: kTooltipMaxHeight),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stepCounter,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(skipLabel),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(step.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(step.body, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: onNext,
                    child: Text(isLast ? doneLabel : nextLabel),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Side of the diamond arrow.
const double _arrowSize = 12;

/// Small rotated-square arrow (diamond) pointing at the target. The parent
/// Stack positions it on the card edge nearest the target.
class _DiamondArrow extends StatelessWidget {
  const _DiamondArrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: math.pi / 4,
      child: Container(
        width: _arrowSize,
        height: _arrowSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Paints the dim layer minus the spotlight hole.
class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.hole,
    required this.dimColor,
    required this.borderColor,
  });

  final Rect hole;
  final Color dimColor;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final holePath = Path()
      ..addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(16)));

    // Dim everything except the hole.
    final dim = Path.combine(PathOperation.difference, full, holePath);
    canvas.drawPath(dim, Paint()..color = dimColor);

    // Accent border around the hole (spotlight effect).
    canvas.drawRRect(
      RRect.fromRectAndRadius(hole, const Radius.circular(16)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.hole != hole ||
      old.dimColor != dimColor ||
      old.borderColor != borderColor;
}
