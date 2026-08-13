/// Configures the global `sqflite` database factory for the current platform.
///
/// Kept as a no-op on every platform: native sqflite registers its factory
/// automatically, and web no longer uses SQLite at all (the web storage
/// backend is browser localStorage — see `storage_backend_web.dart`).
library;

export 'database_factory_stub.dart'
    if (dart.library.js_interop) 'database_factory_web.dart';
