/// RouterHealthService — Phase 2 connectivity/health checks.
///
/// Uses mikrotik_sdk MikrotikClient exclusively for connectivity validation.
/// Does NOT implement monitoring, metrics, or dashboard logic (Phase 3).
// ignore_for_file: prefer_initializing_formals
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../models/router_model.dart';

/// Result of a single health check against a router.
class HealthCheckResult {
  const HealthCheckResult({
    required this.routerId,
    required this.status,
    this.latencyMs,
    this.errorMessage,
    required this.checkedAt,
  });

  final String routerId;
  final RouterHealthStatus status;

  /// Round-trip latency in milliseconds (null if unreachable).
  final int? latencyMs;

  /// Error message if not reachable (credential-redacted).
  final String? errorMessage;

  final DateTime checkedAt;
}

/// Service that validates connectivity to a MikroTik router.
///
/// Timeout is fixed at 5 seconds per check — short enough for UI responsiveness.
class RouterHealthService {
  RouterHealthService({Duration timeout = const Duration(seconds: 5)})
    : _timeout = timeout;

  final Duration _timeout;

  /// Check if the router is reachable and credentials are valid.
  ///
  /// [password] must be the credential retrieved from secure storage.
  /// Never log the password.
  Future<HealthCheckResult> check({
    required RouterModel router,
    required String password,
  }) async {
    final stopwatch = Stopwatch()..start();
    final checkedAt = DateTime.now();

    try {
      final client = MikrotikClient(
        host: router.host,
        username: router.username,
        password: password,
        port: router.port,
        timeout: _timeout,
        maxRetries: 0,
      );

      await client.connect();

      // Minimal read to confirm auth and connectivity.
      await client.command('/system/identity/print');

      await client.disconnect();
      stopwatch.stop();

      return HealthCheckResult(
        routerId: router.id,
        status: RouterHealthStatus.reachable,
        latencyMs: stopwatch.elapsedMilliseconds,
        checkedAt: checkedAt,
      );
    } on RouterosAuthException {
      return HealthCheckResult(
        routerId: router.id,
        status: RouterHealthStatus.authFailed,
        errorMessage: 'Authentication failed — check username and password.',
        checkedAt: checkedAt,
      );
    } on RouterosTimeoutException {
      return HealthCheckResult(
        routerId: router.id,
        status: RouterHealthStatus.timeout,
        errorMessage: 'Connection timed out.',
        checkedAt: checkedAt,
      );
    } on RouterosConnectionException catch (e) {
      return HealthCheckResult(
        routerId: router.id,
        status: RouterHealthStatus.unreachable,
        errorMessage: 'Cannot reach router: ${e.message}',
        checkedAt: checkedAt,
      );
    } on RouterosRetryExhaustedException {
      return HealthCheckResult(
        routerId: router.id,
        status: RouterHealthStatus.unreachable,
        errorMessage: 'Connection failed after retries.',
        checkedAt: checkedAt,
      );
    } catch (e) {
      return HealthCheckResult(
        routerId: router.id,
        status: RouterHealthStatus.unreachable,
        errorMessage: 'Unexpected error: ${e.runtimeType}',
        checkedAt: checkedAt,
      );
    }
  }
}
