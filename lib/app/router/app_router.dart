import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/l10n.dart';
import '../../features/backup/presentation/backup_screen.dart';
import '../../features/calendar/presentation/money_calendar_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/dashboard/presentation/home_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/paywall/presentation/paywall_screen.dart';
import '../../features/settings/application/settings_controller.dart';
import '../../features/settings/presentation/more_tab.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/subscriptions/presentation/subscription_add_edit_screen.dart';
import '../../features/subscriptions/presentation/subscription_detail_screen.dart';
import '../../features/subscriptions/presentation/subscription_list_screen.dart';

/// Holds the destination the user tried to reach before being redirected to
/// onboarding — restored after onboarding completes (deep-link edge case).
String? _pendingDestination;

/// Route names (camelCase per architecture skill).
abstract final class AppRoutes {
  static const onboarding = 'onboarding';
  static const home = 'home';
  static const subscriptions = 'subscriptions';
  static const more = 'more';
  static const subscriptionDetail = 'subscriptionDetail';
  static const subscriptionAdd = 'subscriptionAdd';
  static const subscriptionEdit = 'subscriptionEdit';
  static const settings = 'settings';
  static const backup = 'backup';
  static const categories = 'categories';
  static const paywall = 'paywall';
  static const calendar = 'calendar';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Bump this counter to re-run the redirect when settings (onboarding flag)
  // change — the standard Riverpod + GoRouter refresh pattern.
  final refresh = ValueNotifier<int>(0);
  ref.listen(settingsControllerProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    // Unknown paths (typo, stale deep link, missing route): never a dead
    // end — show a recovery screen instead of a blank page.
    errorBuilder: (context, state) =>
        _NotFoundScreen(path: state.uri.toString()),

    redirect: (context, state) {
      final onboarding = ref.read(settingsControllerProvider).value;
      final path = state.matchedLocation;

      // While settings are still loading, stay put (no redirect storm).
      if (onboarding == null) return null;

      final onOnboarding = path.startsWith('/onboarding');

      if (!onboarding.onboardingCompleted) {
        // Not on onboarding → save the intended destination and redirect.
        if (!onOnboarding) {
          _pendingDestination = path;
          return '/onboarding';
        }
        return null; // already on onboarding — stay
      }

      // Onboarding completed: restore the pending deep-link destination, or
      // navigate to the default initial location (/home).
      if (onOnboarding) {
        final dest = _pendingDestination ?? '/home';
        _pendingDestination = null;
        return dest;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        name: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/paywall',
        name: AppRoutes.paywall,
        builder: (_, _) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/calendar',
        name: AppRoutes.calendar,
        builder: (_, _) => const MoneyCalendarScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, _, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subscriptions',
                name: AppRoutes.subscriptions,
                builder: (_, _) => const SubscriptionListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: AppRoutes.subscriptionAdd,
                    builder: (_, _) => const SubscriptionAddEditScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: AppRoutes.subscriptionDetail,
                    builder: (_, state) => SubscriptionDetailScreen(
                      subscriptionId: state.pathParameters['id']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        name: AppRoutes.subscriptionEdit,
                        builder: (_, state) => SubscriptionAddEditScreen(
                          subscriptionId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                name: AppRoutes.more,
                builder: (_, _) => const MoreTab(),
                routes: [
                  GoRoute(
                    path: 'settings',
                    name: AppRoutes.settings,
                    builder: (_, _) => const SettingsScreen(),
                  ),
                  GoRoute(
                    path: 'backup',
                    name: AppRoutes.backup,
                    builder: (_, _) => const BackupScreen(),
                  ),
                  GoRoute(
                    path: 'categories',
                    name: AppRoutes.categories,
                    builder: (_, _) => const CategoriesScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Recovery screen for unmatched paths — always offers a way back home.
class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // Recovery screen has nothing to pop to — back always goes home.
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.errorTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(l10n.errorBody(path), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined),
                  label: Text(l10n.tabHome),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.tabHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.list_alt_outlined),
            selectedIcon: const Icon(Icons.list_alt),
            label: l10n.tabSubscriptions,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: l10n.tabMore,
          ),
        ],
      ),
    );
  }
}
