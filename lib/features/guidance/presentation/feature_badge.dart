import 'package:flutter/material.dart';

/// Highlight mode for [FeatureBadge].
enum BadgeVariant {
  /// A plain colored dot — minimal signal, no text.
  dot,

  /// A small pill with a label (e.g. "New").
  label,
}

/// Marks a UI element as new/updated until the user acknowledges it.
///
/// Overlays a small dot or label (default "New") on the top-right corner of
/// any widget. Visibility is controlled by the caller (typically from the
/// guidance controller — `hasCompletedStep`), so the badge disappears once
/// the related guidance has been seen — never spam on repeated visits.
///
/// ```dart
/// FeatureBadge(
///   visible: !ref.watch(guidanceControllerProvider).value!.completedStepIds.contains('calendar'),
///   label: context.l10n.featureNew,
///   child: IconButton(...),
/// )
/// ```
class FeatureBadge extends StatelessWidget {
  const FeatureBadge({
    super.key,
    required this.child,
    this.visible = true,
    this.variant = BadgeVariant.label,
    this.label = 'New',
    this.color,
    this.offset = const Offset(4, -4),
  });

  /// The widget being marked (icon, button, tile…).
  final Widget child;

  /// When false the badge renders nothing — the element looks untouched.
  final bool visible;

  final BadgeVariant variant;

  /// Text shown for [BadgeVariant.label] (already localized by the caller).
  final String label;

  /// Badge background; defaults to the error color (attention red).
  final Color? color;

  /// Position of the badge relative to the top-right corner of [child].
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;

    final theme = Theme.of(context);
    final bg = color ?? theme.colorScheme.error;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: offset.dy,
          right: offset.dx,
          child: switch (variant) {
            BadgeVariant.dot => Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.surface.withValues(alpha: 0.9),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            BadgeVariant.label => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onError,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
          },
        ),
      ],
    );
  }
}
