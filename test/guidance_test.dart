import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtrack/core/providers.dart';

import 'package:subtrack/features/guidance/application/guidance_controller.dart';
import 'package:subtrack/features/guidance/domain/guidance_step.dart';
import 'package:subtrack/features/guidance/presentation/disabled_state_helper.dart';
import 'package:subtrack/features/guidance/presentation/feature_badge.dart';
import 'package:subtrack/features/guidance/presentation/guidance_host.dart';
import 'package:subtrack/features/guidance/presentation/spotlight_overlay.dart';
import 'package:subtrack/features/guidance/presentation/tooltip_geometry.dart';
import 'package:subtrack/features/subscriptions/domain/billing_cycle.dart';
import 'package:subtrack/features/subscriptions/domain/subscription.dart';
import 'package:subtrack/features/subscriptions/domain/subscription_status.dart';

import 'fakes.dart';
import 'widget_harness.dart';

void main() {
  group('Tooltip geometry (responsive placement)', () {
    const screen = Size(400, 800);
    const tooltip = Size(280, 160);

    test('auto places below when there is room', () {
      final target = const Rect.fromLTWH(60, 100, 280, 60);
      final p = computeTooltipPlacement(
        target: target,
        screenSize: screen,
        tooltipSize: tooltip,
      );
      expect(p.side, GuidancePlacement.bottom);
      expect(p.topLeft.dy, closeTo(target.bottom + kTooltipGap, 0.001));
    });

    test('auto flips above when there is no room below', () {
      final target = const Rect.fromLTWH(60, 600, 280, 60);
      final p = computeTooltipPlacement(
        target: target,
        screenSize: screen,
        tooltipSize: tooltip,
      );
      expect(p.side, GuidancePlacement.top);
      expect(p.topLeft.dy, closeTo(target.top - tooltip.height - kTooltipGap, 0.001));
    });

    test('centers horizontally on the target', () {
      final target = const Rect.fromLTWH(100, 200, 200, 50);
      final p = computeTooltipPlacement(
        target: target,
        screenSize: screen,
        tooltipSize: tooltip,
      );
      expect(p.topLeft.dx, closeTo(target.center.dx - tooltip.width / 2, 0.001));
    });

    test('clamps horizontally so the card never leaves the screen', () {
      // Target near the right edge → card would overflow; must clamp.
      final target = const Rect.fromLTWH(350, 200, 40, 50);
      final p = computeTooltipPlacement(
        target: target,
        screenSize: screen,
        tooltipSize: tooltip,
      );
      expect(p.topLeft.dx, lessThanOrEqualTo(screen.width - tooltip.width));
      expect(p.topLeft.dx, greaterThanOrEqualTo(0));
    });

    test('explicit placement hint wins over auto', () {
      final target = const Rect.fromLTWH(60, 100, 280, 60);
      final p = computeTooltipPlacement(
        target: target,
        screenSize: screen,
        tooltipSize: tooltip,
        placement: GuidancePlacement.top,
      );
      expect(p.side, GuidancePlacement.top);
    });
  });

  group('GuidanceController', () {
    late FakeSettingsRepository repo;
    late ProviderContainer container;

    ProviderContainer makeContainer() {
      repo = FakeSettingsRepository();
      return ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWith((ref) => repo),
        ],
      );
    }

    tearDown(() => container.dispose());

    test('new user: tour should show (not seen)', () async {
      container = makeContainer();
      final notifier = container.read(guidanceControllerProvider.notifier);
      await container.read(guidanceControllerProvider.future);
      expect(await notifier.shouldShowTour('firstRunHome'), isTrue);
    });

    test('completing the last step marks the tour as seen and persists', () async {
      container = makeContainer();
      final notifier = container.read(guidanceControllerProvider.notifier);
      await container.read(guidanceControllerProvider.future);

      await notifier.completeStep(
        'home.cost',
        tourId: 'firstRunHome',
        tourStepIds: const ['home.cost', 'home.calendar'],
      );
      // Only one of two steps done → tour still shows.
      expect(await notifier.shouldShowTour('firstRunHome'), isTrue);

      await notifier.completeStep(
        'home.calendar',
        tourId: 'firstRunHome',
        tourStepIds: const ['home.cost', 'home.calendar'],
      );
      expect(await notifier.shouldShowTour('firstRunHome'), isFalse);
      expect(repo.get('guidance.steps'), completion('home.cost,home.calendar'));
      expect(repo.get('guidance.tours'), completion('firstRunHome'));
    });

    test('skip marks the tour as seen and persists', () async {
      container = makeContainer();
      final notifier = container.read(guidanceControllerProvider.notifier);
      await container.read(guidanceControllerProvider.future);

      await notifier.markTourSeen('firstRunHome');
      expect(await notifier.shouldShowTour('firstRunHome'), isFalse);
      expect(repo.get('guidance.tours'), completion('firstRunHome'));
    });

    test('state survives a fresh controller (persisted across relaunch)', () async {
      container = makeContainer();
      final notifier = container.read(guidanceControllerProvider.notifier);
      await container.read(guidanceControllerProvider.future);
      await notifier.markTourSeen('firstRunHome');

      // Simulate relaunch: new container over the same repo.
      final container2 = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWith((ref) => repo)],
      );
      addTearDown(container2.dispose);
      await container2.read(guidanceControllerProvider.future);
      final notifier2 = container2.read(guidanceControllerProvider.notifier);
      expect(await notifier2.shouldShowTour('firstRunHome'), isFalse);
    });
  });

  group('FeatureBadge', () {
    testWidgets('renders label badge when visible', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureBadge(
              visible: true,
              label: 'New',
              child: Icon(Icons.add),
            ),
          ),
        ),
      );
      expect(find.text('New'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('hidden badge renders only the child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureBadge(
              visible: false,
              label: 'New',
              child: Icon(Icons.add),
            ),
          ),
        ),
      );
      expect(find.text('New'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('dot variant shows no text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeatureBadge(
              visible: true,
              variant: BadgeVariant.dot,
              child: Icon(Icons.add),
            ),
          ),
        ),
      );
      expect(find.text('New'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('DisabledStateHelper', () {
    testWidgets('enabled: child passes through untouched', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: DisabledStateHelper(
                enabled: true,
                message: 'why',
                child: ElevatedButton(onPressed: null, child: Text('Go')),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Go'), findsOneWidget);
      expect(find.text('why'), findsNothing);
    });

    testWidgets('disabled + tap → dialog explains reason and unlock', (tester) async {
      var unlocked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: DisabledStateHelper(
                enabled: false,
                title: 'Locked',
                message: 'Upgrade to Pro to add more.',
                unlockLabel: 'Unlock',
                onUnlock: () => unlocked = true,
                child: const ElevatedButton(onPressed: null, child: Text('Go')),
              ),
            ),
          ),
        ),
      );

      // Tap the helper itself (the wrapped control absorbs its own hits —
      // the helper's outer GestureDetector receives the tap).
      await tester.tap(
        find.byType(DisabledStateHelper),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Upgrade to Pro to add more.'), findsOneWidget);

      await tester.tap(find.text('Unlock'));
      await tester.pumpAndSettle();
      expect(unlocked, isTrue);
    });
  });

  group('SpotlightOverlay', () {
    testWidgets('renders dimmed layer, step text and actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpotlightOverlay(
              targetRect: Rect.fromLTWH(50, 200, 300, 80),
              screenSize: Size(400, 800),
              step: GuidanceStep(
                id: 's1',
                targetKey: 't',
                title: 'Welcome',
                body: 'This is the cost card.',
              ),
              stepIndex: 0,
              totalSteps: 2,
              skipLabel: 'Skip',
              nextLabel: 'Next',
              doneLabel: 'Done',
              stepCounter: 'Step 1 of 2',
              onSkip: _noop,
              onNext: _noop,
            ),
          ),
        ),
      );

      expect(find.text('Welcome'), findsOneWidget);
      expect(find.text('This is the cost card.'), findsOneWidget);
      expect(find.text('Step 1 of 2'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Done'), findsNothing); // not the last step yet
    });

    testWidgets('last step shows Done instead of Next', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SpotlightOverlay(
              targetRect: Rect.fromLTWH(50, 200, 300, 80),
              screenSize: Size(400, 800),
              step: GuidanceStep(
                id: 's2',
                targetKey: 't',
                title: 'Last',
                body: 'Almost done.',
              ),
              stepIndex: 1,
              totalSteps: 2,
              skipLabel: 'Skip',
              nextLabel: 'Next',
              doneLabel: 'Done',
              stepCounter: 'Step 2 of 2',
              onSkip: _noop,
              onNext: _noop,
            ),
          ),
        ),
      );
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
    });
  });

  group('GuidanceHost', () {
    testWidgets('shows tour once, then never again (persisted)', (tester) async {
      final harness = WidgetHarness(
        subscriptions: _seedSubscriptions,
        onboardingCompleted: true,
      );
      final costKey = GlobalKey();
      final calendarKey = GlobalKey();

      Future<void> pumpHost() async {
        await tester.pumpWidget(
          harness.scope(
            child: MaterialApp(
              home: GuidanceHost(
                tourId: 'firstRunHome',
                steps: const [
                  GuidanceStep(
                    id: 'home.cost',
                    targetKey: 'cost',
                    title: 'Cost title',
                    body: 'Cost body',
                  ),
                  GuidanceStep(
                    id: 'home.calendar',
                    targetKey: 'calendar',
                    title: 'Calendar title',
                    body: 'Calendar body',
                  ),
                ],
                targetKeys: {'cost': costKey, 'calendar': calendarKey},
                child: Column(
                  children: [
                    KeyedSubtree(
                      key: costKey,
                      child: const SizedBox(width: 200, height: 80),
                    ),
                    const SizedBox(height: 200),
                    KeyedSubtree(
                      key: calendarKey,
                      child: const SizedBox(width: 200, height: 80),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump(); // resolve async providers
        await tester.pump(); // let the post-frame callback insert the overlay
      }

      await pumpHost();
      // Step 1 shown.
      expect(find.text('Cost title'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // Next → step 2.
      await tester.tap(find.text('Next'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Calendar title'), findsOneWidget);
      expect(find.text('Cost title'), findsNothing);

      // Done → tour finished and persisted.
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Calendar title'), findsNothing);
      expect(harness.settingsRepo.get('guidance.tours'), completion('firstRunHome'));

      // Relaunch: same repo, fresh widget tree → no tour.
      await pumpHost();
      expect(find.text('Cost title'), findsNothing);
    });

    testWidgets('skip aborts and persists seen state', (tester) async {
      final harness = WidgetHarness(
        subscriptions: _seedSubscriptions,
        onboardingCompleted: true,
      );
      final key = GlobalKey();

      await tester.pumpWidget(
        harness.scope(
          child: MaterialApp(
            home: GuidanceHost(
              tourId: 'firstRunHome',
              steps: const [
                GuidanceStep(
                  id: 'home.cost',
                  targetKey: 'cost',
                  title: 'Cost title',
                  body: 'Cost body',
                ),
              ],
              targetKeys: {'cost': key},
              child: KeyedSubtree(
                key: key,
                child: const SizedBox(width: 200, height: 80),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Cost title'), findsOneWidget);
      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump();

      expect(find.text('Cost title'), findsNothing);
      expect(harness.settingsRepo.get('guidance.tours'), completion('firstRunHome'));
    });

    testWidgets('skip clears steps too, so per-step badges disappear', (tester) async {
      final harness = WidgetHarness(
        subscriptions: _seedSubscriptions,
        onboardingCompleted: true,
      );
      final key = GlobalKey();

      await tester.pumpWidget(
        harness.scope(
          child: MaterialApp(
            home: GuidanceHost(
              tourId: 'firstRunHome',
              steps: const [
                GuidanceStep(
                  id: 'home.cost',
                  targetKey: 'cost',
                  title: 'Cost title',
                  body: 'Cost body',
                ),
              ],
              targetKeys: {'cost': key},
              child: KeyedSubtree(
                key: key,
                child: const SizedBox(width: 200, height: 80),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Skip'));
      await tester.pump();
      await tester.pump();

      // Both the tour (no re-show) and the step (badge clears) are persisted.
      expect(harness.settingsRepo.get('guidance.tours'), completion('firstRunHome'));
      expect(harness.settingsRepo.get('guidance.steps'), completion('home.cost'));
      final container = harness.container();
      await container.read(guidanceControllerProvider.future);
      final notifier = container.read(guidanceControllerProvider.notifier);
      expect(notifier.hasCompletedStep('home.cost'), isTrue);
    });
  });
}

void _noop() {}

/// One active subscription so the dashboard/GuidanceHost have a target.
Subscription _sub(String id) => Subscription(
      id: id,
      name: 'Netflix',
      amountMinor: 1499,
      currency: 'USD',
      billingCycle: BillingCycle.monthly,
      startDate: DateTime(2026, 1, 1),
      nextBillingDate: DateTime(2026, 8, 15),
      billingAnchorDay: 1,
      isTrial: false,
      status: SubscriptionStatus.active,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

final _seedSubscriptions = [_sub('s1')];
