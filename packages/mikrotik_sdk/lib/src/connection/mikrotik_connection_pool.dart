/// MikroTik connection pool.
///
/// Manages persistent connections per router ID, eliminating the need to
/// reconnect on every operation (which was the PHP behavior — reconnecting
/// on every HTTP request).
///
/// ## Design
///
/// The pool is a per-instance registry (not a singleton). The app layer
/// (Phase 2+) is responsible for creating and holding a pool instance,
/// typically via a Riverpod provider.
///
/// ## Router ID
///
/// The router ID is an opaque string key (typically the router's database ID
/// from the Phase 2 persistence layer). It is not validated or interpreted
/// by the pool.
// ignore_for_file: prefer_initializing_formals
library;

import '../exceptions/routeros_exception.dart';
import '../logging/mikrotik_logger.dart';
import '../utils/mikrotik_credentials.dart';
import 'mikrotik_connection.dart';
import 'retry_policy.dart';

/// Manages a pool of named [MikrotikConnection] instances.
///
/// Connections are acquired by router ID. If a connection does not exist
/// or has been invalidated, a new one is created on [acquire].
final class MikrotikConnectionPool {
  final Map<String, MikrotikConnection> _pool = {};
  final RetryConfig _retryConfig;
  final Duration _connectTimeout;

  MikrotikConnectionPool({
    RetryConfig retryConfig = RetryConfig.defaultConfig,
    Duration connectTimeout = const Duration(seconds: 3),
  }) : _retryConfig = retryConfig,
       _connectTimeout = connectTimeout;

  // ─── Pool Operations ───────────────────────────────────────────────────────

  /// Acquires a connected [MikrotikConnection] for [routerId].
  ///
  /// If a live connection exists, returns it. Otherwise creates a new one
  /// using [credentials] and connects it.
  ///
  /// [credentials] must be provided when creating a new connection.
  /// If [credentials] is null and no connection exists, throws [ArgumentError].
  Future<MikrotikConnection> acquire(
    String routerId, {
    MikrotikCredentials? credentials,
  }) async {
    final existing = _pool[routerId];
    if (existing != null && existing.isConnected) {
      MikrotikLogger.logConnection(
        'Pool: reusing connection for routerId=$routerId',
      );
      return existing;
    }

    if (credentials == null) {
      throw ArgumentError(
        'credentials required to create a new connection for routerId=$routerId',
      );
    }

    MikrotikLogger.logConnection(
      'Pool: creating new connection for routerId=$routerId',
    );

    final conn = MikrotikConnection(
      credentials: credentials,
      retryConfig: _retryConfig,
      connectTimeout: _connectTimeout,
    );

    await conn.connect();
    _pool[routerId] = conn;
    return conn;
  }

  /// Releases a connection back to the pool without closing it.
  ///
  /// The connection remains available for future [acquire] calls.
  void release(String routerId) {
    // In this implementation, release is a no-op — connections are kept alive.
    // The pool keeps the connection open for reuse.
    MikrotikLogger.logConnection(
      'Pool: released routerId=$routerId (connection kept alive)',
    );
  }

  /// Invalidates and closes the connection for [routerId].
  ///
  /// The next [acquire] call for this router will create a fresh connection.
  Future<void> invalidate(String routerId) async {
    final conn = _pool.remove(routerId);
    if (conn == null) return;

    MikrotikLogger.logConnection(
      'Pool: invalidating connection for routerId=$routerId',
    );

    try {
      await conn.disconnect();
    } on RouterosException catch (e) {
      MikrotikLogger.logWarning(
        'Pool: error during invalidation of routerId=$routerId: ${e.message}',
      );
    }
  }

  /// Closes all connections in the pool and clears it.
  Future<void> closeAll() async {
    MikrotikLogger.logConnection(
      'Pool: closing all connections (${_pool.length} active)',
    );

    final ids = List<String>.from(_pool.keys);
    for (final id in ids) {
      await invalidate(id);
    }

    _pool.clear();
  }

  /// Returns whether a live connection exists for [routerId].
  bool hasConnection(String routerId) => _pool[routerId]?.isConnected ?? false;

  /// The number of active connections in the pool.
  int get connectionCount => _pool.length;
}
