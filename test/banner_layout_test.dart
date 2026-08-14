import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression: the AdMob banner platform-view placeholder reports infinite
/// height when unconstrained (BoxConstraints.biggest inside a Column). On the
/// Subscriptions screen the banner sits in the same Column as the Expanded
/// list, so an unconstrained banner collapses the list to h=0 — items stay in
/// the widget tree but render nothing ("list sometimes empty" bug, device
/// repro: add a subscription → tab shows nothing until the ad loads, then
/// the list vanishes entirely).
///
/// The fix constrains the AdWidget to the loaded banner's exact AdSize via
/// SizedBox(width, height). These tests pin down the layout invariant: an
/// unbounded ad-view child destroys the Expanded list; a fixed-size box
/// around it preserves it.
void main() {
  Widget buildColumn({required Widget adSlot}) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: const [
                  ListTile(title: Text('Netflix')),
                  ListTile(title: Text('Spotify')),
                ],
              ),
            ),
            adSlot,
          ],
        ),
      ),
    );
  }

  /// Mimics AdWidget's platform-view placeholder: it sizes itself to the
  /// biggest incoming constraints (infinite height inside a Column) without
  /// asserting — exactly what the real `_PlatformViewPlaceholderBox` does
  /// (device render tree: `size: Size(w, Infinity)` under
  /// `additionalConstraints: BoxConstraints(biggest)`).
  Widget unconstrainedAdPlaceholder() {
    return _BiggestBox();
  }

  testWidgets('unconstrained ad placeholder collapses the Expanded list',
      (tester) async {
    await tester.pumpWidget(
      buildColumn(adSlot: unconstrainedAdPlaceholder()),
    );

    // The unbounded ad slot makes the Column overflow; the Expanded list
    // ends up with zero height — the list is invisible while tiles exist.
    expect(tester.takeException(), isNotNull);
    final listSize = tester.getSize(find.byType(ListView));
    expect(listSize.height, 0,
        reason: 'unconstrained ad slot must collapse the list (bug repro)');
  });

  testWidgets('SizedBox-constrained ad slot keeps the Expanded list visible',
      (tester) async {
    await tester.pumpWidget(
      buildColumn(
        adSlot: const SizedBox(
          width: 360,
          height: 50,
          child: _BiggestBox(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final listSize = tester.getSize(find.byType(ListView));
    expect(listSize.height, greaterThan(0),
        reason: 'a fixed-size ad slot must not eat the list height (fix)');
    // Both tiles still rendered.
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget);
  });
}

/// Render box that takes the biggest incoming constraints — the behaviour of
/// the real `_PlatformViewPlaceholderBox` under `BoxConstraints.biggest`.
class _BiggestBox extends SingleChildRenderObjectWidget {
  const _BiggestBox();

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBiggestBox();
}

class _RenderBiggestBox extends RenderProxyBox {
  @override
  Size computeDryLayout(BoxConstraints constraints) => constraints.biggest;

  @override
  void performLayout() {
    size = computeDryLayout(constraints);
    if (child != null) {
      child!.layout(constraints);
    }
  }
}
