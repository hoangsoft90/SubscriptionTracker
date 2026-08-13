/// Web: no SQLite on this platform anymore — the web storage backend is
/// browser localStorage (see `storage_backend_web.dart`), so there is no
/// sqflite factory to install. Kept for API compatibility with the native
/// stub (`database_factory_stub.dart`) — both are no-ops.
void configureDatabaseFactory() {}
