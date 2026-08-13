import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/app/app.dart';

import 'widget_harness.dart';

void main() {
  testWidgets('SubTrack app renders (smoke)', (tester) async {
    // Use the widget harness so providers resolve against in-memory fakes
    // (sqflite doesn't work inside the fake-async zone of testWidgets).
    final harness = WidgetHarness();

    await tester.pumpWidget(harness.scope(child: const SubTrackApp()));
    await tester.pump();
    expect(find.byType(SubTrackApp), findsOneWidget);
  });
}
