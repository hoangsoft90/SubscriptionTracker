import 'package:flutter/material.dart';

/// Explains *why* a control is disabled and how to unlock it.
///
/// Wraps any widget (a disabled button, a blocked tile…) and, when the
/// wrapped control is not enabled, intercepts taps to show a short explainer
/// instead of silently doing nothing — so users are never confused by a
/// dead control. The explainer is either a lightweight anchored tooltip or a
/// modal (dialog) with an optional unlock action.
///
/// ```dart
/// DisabledStateHelper(
///   enabled: isPro,
///   title: context.l10n.disabledFreeLimitTitle,
///   message: context.l10n.disabledFreeLimitBody,
///   unlockLabel: context.l10n.paywallBuy,
///   onUnlock: () => context.push('/paywall'),
///   child: FloatingActionButton(onPressed: null, child: const Icon(Icons.add)),
/// )
/// ```
class DisabledStateHelper extends StatelessWidget {
  const DisabledStateHelper({
    super.key,
    required this.enabled,
    required this.child,
    this.title,
    this.message,
    this.unlockLabel,
    this.onUnlock,
    this.showAsDialog = true,
  });

  /// When true, [child] is rendered untouched (enabled state).
  final bool enabled;

  /// The control being wrapped. Must accept being shown disabled (e.g. an
  /// `onPressed: null` button) — this helper never changes its enabledness,
  /// it only adds the tap-to-explain behavior when disabled.
  final Widget child;

  /// Heading of the explainer (localized by the caller).
  final String? title;

  /// Short explanation of the reason + the unlock condition (localized).
  final String? message;

  /// Optional action label ("Unlock Pro"…). Omitted → explainer only.
  final String? unlockLabel;

  /// Runs when the user taps the unlock action (e.g. open the paywall).
  final VoidCallback? onUnlock;

  /// True → modal dialog; false → anchored tooltip-like popup.
  final bool showAsDialog;

  @override
  Widget build(BuildContext context) {
    if (enabled) return child;
    return GestureDetector(
      // Behavior opaque so taps anywhere on the wrapped control are caught
      // even if the child itself ignores pointers (disabled buttons still
      // absorb hits through IgnorePointer-free siblings — see below).
      behavior: HitTestBehavior.opaque,
      onTap: () => _explain(context),
      child: AbsorbPointer(
        // Neutralize the child's own (disabled) handlers so nothing else
        // reacts; the explanation is the only response.
        absorbing: true,
        child: child,
      ),
    );
  }

  Future<void> _explain(BuildContext context) async {
    final l10nTitle = title ?? '';
    final l10nMessage = message ?? '';
    if (showAsDialog) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: l10nTitle.isEmpty ? null : Text(l10nTitle),
          content: Text(l10nMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                MaterialLocalizations.of(context).okButtonLabel,
              ),
            ),
            if (unlockLabel != null && onUnlock != null)
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onUnlock!();
                },
                child: Text(unlockLabel!),
              ),
          ],
        ),
      );
    } else {
      // Lightweight anchored popup (tooltip-like) anchored to the control.
      final overlay = Overlay.of(context);
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.hasSize) return;
      final offset = renderBox.localToGlobal(Offset.zero);
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => _AnchoredTooltip(
          anchor: Rect.fromLTWH(
            offset.dx,
            offset.dy,
            renderBox.size.width,
            renderBox.size.height,
          ),
          title: l10nTitle,
          message: l10nMessage,
          unlockLabel: unlockLabel,
          onUnlock: onUnlock,
          onDismiss: () => entry.remove(),
        ),
      );
      overlay.insert(entry);
    }
  }
}

/// Small anchored card shown near the disabled control.
class _AnchoredTooltip extends StatelessWidget {
  const _AnchoredTooltip({
    required this.anchor,
    required this.title,
    required this.message,
    required this.unlockLabel,
    required this.onUnlock,
    required this.onDismiss,
  });

  final Rect anchor;
  final String title;
  final String message;
  final String? unlockLabel;
  final VoidCallback? onUnlock;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screen = MediaQuery.sizeOf(context);
    // Place above the anchor; fall back below when there's no room.
    const width = 260.0;
    const height = 140.0;
    final showBelow = anchor.top - height - 8 < 0;
    final left = (anchor.center.dx - width / 2)
        .clamp(8.0, (screen.width - width - 8.0).clamp(8.0, double.infinity));
    final top = showBelow ? anchor.bottom + 8 : anchor.top - height - 8;

    return Positioned(
      left: left,
      top: top,
      width: width,
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty)
                Text(title, style: theme.textTheme.titleSmall),
              if (title.isNotEmpty) const SizedBox(height: 4),
              Text(message, style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    child: Text(MaterialLocalizations.of(context).okButtonLabel),
                  ),
                  if (unlockLabel != null && onUnlock != null)
                    FilledButton(
                      onPressed: () {
                        onDismiss();
                        onUnlock!();
                      },
                      child: Text(unlockLabel!),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
