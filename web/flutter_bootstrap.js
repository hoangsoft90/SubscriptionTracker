{{flutter_js}}
{{flutter_build_config}}

// Semantics tree enabled so screen readers (and headless tests) can read
// the UI text — Flutter renders to canvas otherwise. This uses the modern
// `initializeEngine(config)` path; the legacy `window.flutterConfiguration`
// is deprecated and conflicts with it (assertion error at boot).
_flutter.loader.load({
  config: {
    semanticsEnabled: true,
  },
});
