/// RouterRepository — Phase 2 persistence boundary.
///
/// Splits storage:
/// - Drift/SQLite: router metadata (id, name, host, port, username, group, note, timestamps)
/// - flutter_secure_storage: router password (key: `router_pwd_<id>`)
/// - SharedPreferences-style via secure storage: last-used router id (key: `last_used_router_id`)
///
/// The caller NEVER reads a password from this class after the initial save.
/// Passwords are retrieved only when a connection is needed (via [getPassword]).
// ignore_for_file: prefer_initializing_formals
library;

import 'package:drift/drift.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../database/app_database.dart';
import '../../domain/models/router_model.dart';

/// Secure storage key prefix for router passwords.
const _kPasswordPrefix = 'router_pwd_';

/// Secure storage key for the last-used router id.
const _kLastUsedKey = 'last_used_router_id';

/// Repository for all router persistence operations.
///
/// All mutations are atomic with respect to each storage tier:
/// - Drift write completes before secure-storage write.
/// - Secure-storage delete completes before Drift delete.
class RouterRepository {
  RouterRepository({
    required AppDatabase db,
    required FlutterSecureStorage secureStorage,
  }) : _db = db,
       _secure = secureStorage;

  final AppDatabase _db;
  final FlutterSecureStorage _secure;

  // ---------------------------------------------------------------------------
  // Write operations
  // ---------------------------------------------------------------------------

  /// Persist a new router.
  ///
  /// [password] is stored in secure storage; all other fields go to Drift.
  /// Throws [RouterValidationException] if required fields are empty.
  Future<RouterModel> addRouter({
    required RouterModel router,
    required String password,
  }) async {
    _validateRouter(router);
    _validatePassword(password);

    // 1. Persist metadata to Drift.
    await _db.into(_db.routerTable).insert(_toCompanion(router));

    // 2. Store password in secure storage.
    await _secure.write(key: '$_kPasswordPrefix${router.id}', value: password);

    return router;
  }

  /// Update an existing router.
  ///
  /// Pass [password] only if the password is being changed; pass null to leave
  /// the existing password untouched.
  Future<RouterModel> updateRouter({
    required RouterModel router,
    String? password,
  }) async {
    _validateRouter(router);
    if (password != null) {
      _validatePassword(password);
    }

    // 1. Update Drift row.
    await (_db.update(_db.routerTable)
          ..where((t) => t.id.equals(router.id)))
        .write(_toCompanion(router));

    // 2. Optionally update password.
    if (password != null) {
      await _secure.write(
        key: '$_kPasswordPrefix${router.id}',
        value: password,
      );
    }

    return router;
  }

  /// Delete a router and its stored credentials.
  ///
  /// Also clears last-used if this router was last used.
  Future<void> deleteRouter(String routerId) async {
    // 1. Delete from Drift.
    await (_db.delete(_db.routerTable)
          ..where((t) => t.id.equals(routerId)))
        .go();

    // 2. Delete password from secure storage.
    await _secure.delete(key: '$_kPasswordPrefix$routerId');

    // 3. Clear last-used if it pointed to this router.
    final lastUsed = await _secure.read(key: _kLastUsedKey);
    if (lastUsed == routerId) {
      await _secure.delete(key: _kLastUsedKey);
    }
  }

  // ---------------------------------------------------------------------------
  // Read operations
  // ---------------------------------------------------------------------------

  /// List all routers, ordered by last-used descending, then by name.
  Future<List<RouterModel>> listRouters() async {
    final rows = await _db.select(_db.routerTable).get();
    final models = rows.map(_fromRow).toList();
    models.sort((a, b) {
      final aTime = a.lastUsedAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.lastUsedAt?.millisecondsSinceEpoch ?? 0;
      if (bTime != aTime) return bTime.compareTo(aTime);
      return a.name.compareTo(b.name);
    });
    return models;
  }

  /// Get a single router by id. Returns null if not found.
  Future<RouterModel?> getRouter(String routerId) async {
    final row =
        await (_db.select(_db.routerTable)
              ..where((t) => t.id.equals(routerId)))
            .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Retrieve the stored password for a router.
  ///
  /// Returns null if the password was never stored (should not happen in
  /// normal operation but may occur after a partial migration).
  Future<String?> getPassword(String routerId) async {
    return _secure.read(key: '$_kPasswordPrefix$routerId');
  }

  // ---------------------------------------------------------------------------
  // Last-used router
  // ---------------------------------------------------------------------------

  /// Persist the last-used router id.
  Future<void> setLastUsedRouter(String routerId) async {
    // Also update the lastUsedAt column in Drift.
    await (_db.update(_db.routerTable)
          ..where((t) => t.id.equals(routerId)))
        .write(
          RouterTableCompanion(
            lastUsedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
    await _secure.write(key: _kLastUsedKey, value: routerId);
  }

  /// Read the last-used router id. Returns null if none was set.
  Future<String?> getLastUsedRouterId() async {
    return _secure.read(key: _kLastUsedKey);
  }

  /// Load the last-used router model (null if none or deleted).
  Future<RouterModel?> getLastUsedRouter() async {
    final id = await getLastUsedRouterId();
    if (id == null) return null;
    return getRouter(id);
  }

  // ---------------------------------------------------------------------------
  // Grouping
  // ---------------------------------------------------------------------------

  /// List routers filtered by group.
  Future<List<RouterModel>> listRoutersByGroup(RouterGroup group) async {
    final rows =
        await (_db.select(_db.routerTable)
              ..where((t) => t.groupName.equals(group.name)))
            .get();
    return rows.map(_fromRow).toList();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  RouterTableCompanion _toCompanion(RouterModel r) {
    return RouterTableCompanion(
      id: Value(r.id),
      name: Value(r.name),
      host: Value(r.host),
      port: Value(r.port),
      username: Value(r.username),
      groupName: Value(r.group.name),
      note: Value(r.note),
      lastUsedAt: Value(r.lastUsedAt?.millisecondsSinceEpoch),
      createdAt: Value(
        r.createdAt?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  RouterModel _fromRow(RouterTableData row) {
    return RouterModel(
      id: row.id,
      name: row.name,
      host: row.host,
      port: row.port,
      username: row.username,
      group: RouterGroup.fromString(row.groupName),
      note: row.note,
      lastUsedAt:
          row.lastUsedAt != null
              ? DateTime.fromMillisecondsSinceEpoch(row.lastUsedAt!)
              : null,
      createdAt:
          row.createdAt != null
              ? DateTime.fromMillisecondsSinceEpoch(row.createdAt!)
              : null,
    );
  }

  void _validateRouter(RouterModel r) {
    if (r.id.isEmpty) {
      throw const RouterValidationException('Router id must not be empty.');
    }
    if (r.name.trim().isEmpty) {
      throw const RouterValidationException('Router name must not be empty.');
    }
    if (r.host.trim().isEmpty) {
      throw const RouterValidationException('Router host must not be empty.');
    }
    if (r.username.trim().isEmpty) {
      throw const RouterValidationException(
        'Router username must not be empty.',
      );
    }
    if (r.port < 1 || r.port > 65535) {
      throw const RouterValidationException(
        'Router port must be between 1 and 65535.',
      );
    }
  }

  void _validatePassword(String password) {
    if (password.isEmpty) {
      throw const RouterValidationException('Password must not be empty.');
    }
  }
}

/// Thrown when router field validation fails.
class RouterValidationException implements Exception {
  const RouterValidationException(this.message);

  final String message;

  @override
  String toString() => 'RouterValidationException: $message';
}
