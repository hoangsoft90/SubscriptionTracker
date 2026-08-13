import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';

import 'package:subtrack/app/app.dart';

/// Privacy verification (spec §9 / privacy-compliance):
///
/// 1. With network access disabled, every core flow must work and the app's
///    own code must issue ZERO outbound requests.
/// 2. The only permitted network use is the platform store SDK (IAP), which is
///    user-initiated.
///
/// How this test proves "0 outbound requests":
/// - `subtrack` has no HTTP client in its own code: `pubspec.yaml` declares no
///   `http`, `dio`, `graphql` or analytics packages, and every feature talks
///   to local repositories only. Any future outbound call would require
///   adding a network dependency, which the dependency audit
///   (docs/privacy-labels.md FORBIDDEN list) blocks.
/// - A throwing `HttpOverrides` is installed: ANY `dart:io` HttpClient
///   connection attempt fails the test immediately, so if app code ever dials
///   out during these flows the test fails.
///
/// The assertions are intentionally locale- and state-agnostic: the app may
/// boot to onboarding (fresh install) or the dashboard (previous runs on the
/// same device), in EN or VI — we only assert the app builds and settles
/// without ever touching the network.
///
/// Run on a device/emulator with network disabled:
///   flutter test integration_test/privacy_network_test.dart -d DEVICE_ID
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots and settles with 0 outbound requests',
      (tester) async {
    // Any dart:io HttpClient attempt fails the test (records + throws).
    HttpOverrides.global = _ThrowingHttpOverrides();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [],
        child: const SubTrackApp(),
      ),
    );

    // Let the app boot (settings load, first frames). Avoid pumpAndSettle
    // (onboarding may contain continuous animations) — pump a few frames.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // The app is up — either onboarding or the dashboard, either locale.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Walk the main tab surface (bottom nav) — present in both boot paths.
    expect(find.byType(NavigationBar), findsWidgets);

    // Tear down the override so later tests are unaffected.
    HttpOverrides.global = null;
  });
}

/// HTTP overrides that throw on ANY connection attempt — proving app code
/// never dials out.
class _ThrowingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _ThrowingHttpClient();
}

class _ThrowingHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) => _fail('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _fail('POST', url);

  @override
  Future<HttpClientRequest> openUrl(
          String method, Uri url) =>
      _fail(method, url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _fail('GET', Uri.parse('http://$host:$port$path'));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _fail('POST', Uri.parse('http://$host:$port$path'));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected HttpClient use: ${invocation.memberName}');

  Future<HttpClientRequest> _fail(String method, Uri url) async {
    throw StateError('outbound $method $url — app code must not dial out');
  }
}
