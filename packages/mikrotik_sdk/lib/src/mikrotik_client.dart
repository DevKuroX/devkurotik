/// MikrotikClient — public API entry point for mikrotik_sdk.
///
/// [MikrotikClient] is the primary class downstream SDKs and the Flutter app
/// use to interact with a MikroTik RouterOS device.
///
/// ## Usage
///
/// ```dart
/// final client = MikrotikClient(
///   host: '192.168.1.1',
///   username: 'admin',
///   password: 'secret',
/// );
///
/// await client.connect();
///
/// final users = await client.command('/ip/hotspot/user/print');
/// for (final user in users) {
///   print(user['.id']);
/// }
///
/// await client.disconnect();
/// ```
///
/// ## Error handling
///
/// All errors are typed subclasses of [RouterosException]. Catch them
/// specifically or broadly:
///
/// ```dart
/// try {
///   await client.connect();
/// } on RouterosAuthException catch (e) {
///   // wrong credentials
/// } on RouterosConnectionException catch (e) {
///   // can't reach router
/// } on RouterosException catch (e) {
///   // any SDK error
/// }
/// ```
library;

import 'dart:async';

import 'connection/connection_state.dart';
import 'connection/mikrotik_connection.dart';
import 'connection/retry_policy.dart';
import 'exceptions/routeros_exception.dart';
import 'utils/mikrotik_credentials.dart';

export 'connection/connection_state.dart';
export 'connection/retry_policy.dart';
export 'exceptions/routeros_exception.dart';
export 'utils/mikrotik_credentials.dart';
export 'utils/routeros_format.dart';
export 'utils/routeros_random.dart';

/// The primary RouterOS API client.
///
/// Wraps a [MikrotikConnection] and exposes the stable command API
/// that downstream SDKs (hotspot_sdk, monitoring_sdk, etc.) consume.
final class MikrotikClient {
  final MikrotikConnection _connection;

  MikrotikClient({
    required String host,
    required String username,
    required String password,
    int port = 8728,
    Duration timeout = const Duration(seconds: 3),
    int maxRetries = 5,
  }) : _connection = MikrotikConnection(
         credentials: MikrotikCredentials(
           host: host,
           username: username,
           password: password,
           port: port,
         ),
         retryConfig: RetryConfig(
           maxRetries: maxRetries,
           baseDelay: const Duration(seconds: 3),
         ),
         connectTimeout: timeout,
       );

  /// Creates a client from a [MikrotikCredentials] object.
  factory MikrotikClient.fromCredentials(
    MikrotikCredentials credentials, {
    Duration timeout = const Duration(seconds: 3),
    int maxRetries = 5,
  }) {
    return MikrotikClient(
      host: credentials.host,
      username: credentials.username,
      password: credentials.password,
      port: credentials.port,
      timeout: timeout,
      maxRetries: maxRetries,
    );
  }

  // ─── State ─────────────────────────────────────────────────────────────────

  /// The current connection state.
  ConnectionState get connectionState => _connection.state;

  /// Whether the client is connected and authenticated.
  bool get isConnected => _connection.isConnected;

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  /// Connects to the RouterOS device and authenticates.
  ///
  /// Throws [RouterosConnectionException] if unreachable.
  /// Throws [RouterosAuthException] if credentials are wrong.
  /// Throws [RouterosTimeoutException] if connection times out.
  /// Throws [RouterosRetryExhaustedException] if all retries fail.
  Future<void> connect() => _connection.connect();

  /// Disconnects from the RouterOS device.
  Future<void> disconnect() => _connection.disconnect();

  // ─── Commands ──────────────────────────────────────────────────────────────

  /// Executes a RouterOS API command and returns all response rows.
  ///
  /// [path] is the RouterOS API path, e.g. `'/ip/hotspot/user/print'`.
  ///
  /// [query] is a map of `?key=value` filter parameters.
  /// [params] is a map of `=key=value` setter parameters.
  /// [proplist] limits the returned fields to the given list.
  /// [countOnly] returns only a count of matching items.
  ///
  /// Returns a [List] of [Map] — one map per `!re` response row.
  ///
  /// Throws [RouterosCommandException] if the command fails.
  /// Throws [RouterosNotConnectedException] if not connected.
  Future<List<Map<String, String>>> command(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> params = const {},
    bool countOnly = false,
    List<String>? proplist,
  }) {
    return _connection.command(
      path,
      query: query,
      params: params,
      countOnly: countOnly,
      proplist: proplist,
    );
  }

  /// Sends a fire-and-forget command to RouterOS (no response expected).
  ///
  /// Used for commands like `/system/reboot` and `/system/shutdown`.
  Future<void> execute(String path) => _connection.execute(path);
}
