/// Creates the platform-appropriate [StorageBackend]:
///
/// - Native (Android/iOS): SQLite — [createStorageBackend] opens the app
///   database (migrations + seed) and wraps it in the sqflite repositories.
/// - Web: browser localStorage — [createStorageBackend] builds the
///   localStorage repositories over `BrowserLocalStorage` (seeded defaults).
///
/// The conditional import keeps sqflite (and its native plugin) out of the
/// web build entirely, and keeps `package:web`/localStorage out of native
/// builds — matching the `database_factory.dart` pattern.
library;

export 'storage_backend_stub.dart'
    if (dart.library.js_interop) 'storage_backend_web.dart';
