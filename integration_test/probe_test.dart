import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('probe: plain pump works', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Hi'))),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump();
    }
    expect(find.text('Hi'), findsOneWidget);
  });

  testWidgets('probe: pump with duration works', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Hi2'))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Hi2'), findsOneWidget);
  });

  testWidgets('probe: pumpAndSettle works', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Hi3'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hi3'), findsOneWidget);
  });
}
