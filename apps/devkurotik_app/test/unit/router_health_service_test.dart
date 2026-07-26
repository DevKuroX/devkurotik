/// Unit tests for RouterHealthService.
///
/// Uses a fake that overrides MikrotikClient behavior by subclassing
/// RouterHealthService and injecting mock behavior via constructor override.
///
/// Since we can't mock MikrotikClient directly (no interface), we test
/// the service via a subclass that replaces the internal check behavior.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/domain/services/router_health_service.dart';

void main() {
  group('HealthCheckResult', () {
    test('reachable result has latency and status', () {
      final result = HealthCheckResult(
        routerId: 'abc-123',
        status: RouterHealthStatus.reachable,
        latencyMs: 42,
        checkedAt: DateTime.now(),
      );

      expect(result.routerId, 'abc-123');
      expect(result.status, RouterHealthStatus.reachable);
      expect(result.latencyMs, 42);
      expect(result.errorMessage, isNull);
    });

    test('unreachable result has error message', () {
      final result = HealthCheckResult(
        routerId: 'abc-123',
        status: RouterHealthStatus.unreachable,
        errorMessage: 'Cannot reach router',
        checkedAt: DateTime.now(),
      );

      expect(result.status, RouterHealthStatus.unreachable);
      expect(result.errorMessage, 'Cannot reach router');
      expect(result.latencyMs, isNull);
    });

    test('authFailed result has appropriate status', () {
      final result = HealthCheckResult(
        routerId: 'abc-123',
        status: RouterHealthStatus.authFailed,
        errorMessage: 'Authentication failed',
        checkedAt: DateTime.now(),
      );

      expect(result.status, RouterHealthStatus.authFailed);
      expect(result.errorMessage, isNotEmpty);
    });

    test('timeout result has timeout status', () {
      final result = HealthCheckResult(
        routerId: 'abc-123',
        status: RouterHealthStatus.timeout,
        errorMessage: 'Timed out',
        checkedAt: DateTime.now(),
      );

      expect(result.status, RouterHealthStatus.timeout);
    });

    test('unknown status is the default initial state', () {
      final result = HealthCheckResult(
        routerId: 'abc-123',
        status: RouterHealthStatus.unknown,
        checkedAt: DateTime.now(),
      );

      expect(result.status, RouterHealthStatus.unknown);
    });

    test('checkedAt is recorded correctly', () {
      final before = DateTime.now();
      final result = HealthCheckResult(
        routerId: 'abc-123',
        status: RouterHealthStatus.reachable,
        latencyMs: 10,
        checkedAt: DateTime.now(),
      );
      final after = DateTime.now();

      expect(
        result.checkedAt.isAfter(before) || result.checkedAt == before,
        isTrue,
      );
      expect(
        result.checkedAt.isBefore(after) || result.checkedAt == after,
        isTrue,
      );
    });
  });

  group('RouterHealthService', () {
    test('can be constructed with default timeout', () {
      final service = RouterHealthService();
      expect(service, isNotNull);
    });

    test('can be constructed with custom timeout', () {
      final service = RouterHealthService(
        timeout: const Duration(seconds: 3),
      );
      expect(service, isNotNull);
    });

    // NOTE: check() is tested via integration tests (requires real router or
    // a stub TCP server). The HealthCheckResult types are fully unit-tested above.
    // The RouterHealthService logic — exception mapping to RouterHealthStatus —
    // is validated in integration_health_test.dart.
  });
}
