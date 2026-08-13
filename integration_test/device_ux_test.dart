import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:subtrack/app/app.dart';
import 'package:subtrack/core/l10n/l10n.dart';
import 'package:subtrack/l10n/app_localizations.dart';

/// On-device UX regression test for the 4 reported bugs:
///
/// 1. Onboarding preset tap → selection checkmark + counter (Bug 1).
/// 2. A subscription with a very long amount renders without RenderFlex
///    right-overflow on the Subscriptions tab (Bug 2).
/// 3. Settings "Appearance" SegmentedButton fits a narrow phone (Bug 3).
/// 4. Tapping a category toggles its highlight (Bug 4).
///
/// Run (fresh app state recommended):
///   adb -s `DEVICE` shell pm clear com.subguard.app
///   flutter test integration_test/device_ux_test.dart -d `DEVICE`
///
/// Locale-agnostic: every finder uses the app's own l10n strings, so it works
/// in EN or VI. Any RenderFlex overflow throws and fails the test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('device UX: onboarding preset, overflow, settings, categories',
      (tester) async {
    try {
      await _run(tester);
    } catch (e, st) {
      // Print the real error to the device log so it survives process teardown.
      debugPrint('DEVICE_UX_TEST_ERROR: $e\n$st');
      rethrow;
    }
  });
}

Future<void> _run(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: const [], child: const SubTrackApp()),
    );
    debugPrint('STEP: pumpWidget done');
    await pumpUntilFound(tester, find.byType(MaterialApp));
    debugPrint('STEP: MaterialApp found');
    // AppLocalizations lives in an InheritedWidget BELOW MaterialApp, so the
    // lookup needs a descendant context (e.g. the first Scaffold), and the
    // delegates resolve asynchronously — poll until it is readable.
    await pumpUntilFound(tester, find.byType(Scaffold));
    final scaffold = find.byType(Scaffold).first;
    final l10nEnd = DateTime.now().add(const Duration(seconds: 20));
    while (DateTime.now().isBefore(l10nEnd)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (Localizations.of<AppLocalizations>(
            tester.element(scaffold),
            AppLocalizations,
          ) !=
          null) {
        break;
      }
    }
    final l10n = tester.element(scaffold).l10n;

    // ---- Bug 1: onboarding preset selection ----
    // Privacy promise step → Continue.
    await pumpUntilFound(tester, find.byType(FilledButton));
    // The CTA buttons render with an icon (FilledButton.icon style), so match
    // the label text directly instead of widgetWithText(FilledButton, ...).
    await tester.tap(find.text(l10n.onboardingContinue));
    // Currency step → Continue (wait for the switcher to settle).
    await pumpUntilFound(tester, find.text(l10n.onboardingCurrencyTitle));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(l10n.onboardingContinue));
    // Presets step.
    await pumpUntilFound(tester, find.text(l10n.onboardingPresetsTitle));
    await tester.pump(const Duration(milliseconds: 400));

    // Tap Netflix → checkmark appears inside its card + counter updates.
    final netflix = find.text(l10n.presetNetflix);
    await tester.tap(netflix);
    await tester.pump();
    final netflixCard =
        find.ancestor(of: netflix, matching: find.byType(Card));
    expect(
      find.descendant(of: netflixCard, matching: find.byIcon(Icons.check)),
      findsOneWidget,
    );
    expect(find.text(l10n.onboardingPresetsSelected(1)), findsOneWidget);

    // Start tracking → Home shell.
    await tester.tap(find.text(l10n.onboardingDone));
    await pumpUntilFound(tester, find.byType(NavigationBar));

    // ---- Bug 2: no right-overflow with a long amount ----
    // Subscriptions tab → FAB (add flow).
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(l10n.tabSubscriptions),
    ));
    await pumpUntilFound(tester, find.byType(FloatingActionButton));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byType(FloatingActionButton));

    // The onboarding preset pre-fills the first add form (Bug 1 flow).
    await pumpUntilFound(
      tester,
      find.widgetWithText(TextFormField, l10n.fieldName),
    );
    final nameField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, l10n.fieldName),
    );
    expect(nameField.controller?.text, l10n.presetNetflix);

    // Replace with a long-amount subscription (name + huge amount).
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.fieldName),
      'Long Amount Sub',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.fieldAmount),
      '1234567890',
    );
    await tester.scrollUntilVisible(
      find.text(l10n.save),
      100,
      scrollable: find.descendant(
        of: find.byType(Form),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text(l10n.save));

    // Back on the list — the long amount must render without overflow
    // (any RenderFlex overflow throws and fails the test).
    await pumpUntilFound(tester, find.text('Long Amount Sub'));
    await tester.pump(const Duration(milliseconds: 400));

    // ---- Bug 3: settings "Appearance" fits a narrow phone ----
    await tester.tap(find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(l10n.tabMore),
    ));
    await pumpUntilFound(tester, find.text(l10n.settingsTitle));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(l10n.settingsTitle));
    await pumpUntilFound(tester, find.text(l10n.settingsTheme));
    expect(find.byType(SegmentedButton<ThemeMode>), findsOneWidget);

    // ---- Bug 4: category tap highlight ----
    await tester.tap(find.text(l10n.settingsCategories));
    await pumpUntilFound(tester, find.text('Streaming')); // seeded default
    final streamingTile = find.widgetWithText(ListTile, 'Streaming');
    expect(tester.widget<ListTile>(streamingTile).selected, isFalse);
    await tester.tap(streamingTile);
    await tester.pump();
    expect(tester.widget<ListTile>(streamingTile).selected, isTrue);
}

/// Pumps frames until [finder] matches or [timeout] elapses. Integration
/// tests run in real time on the device, so generous timeouts are fine.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for $finder');
}
