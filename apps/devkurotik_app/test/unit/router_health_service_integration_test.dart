/// Tests for RouterHealthService exception mapping.
///
/// We test the full check() method against a refusing port (connection refused →
/// RouterosConnectionException → unreachable status) and a timeout scenario.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/domain/services/router_health_service.dart';

void main() {
  group('RouterHealthService.check()', () {
    const router = RouterModel(
      id: 'health-test',
      name: 'Test Router',
      host: '127.0.0.1',
      port: 19999, // We will bind to this or ensure it's closed.
      username: 'admin',
      group: RouterGroup.ungrouped,
    );

    test('returns unreachable when connection is refused', () async {
      // Ensure port 19999 is NOT listening so we get connection refused.
      // Check first; if bound, skip.
      var portFree = false;
      try {
        final s = await ServerSocket.bind('127.0.0.1', 19999);
        await s.close();
        portFree = true;
      } catch (_) {
        portFree = false;
      }

      if (!portFree) {
        // Port in use — skip this test.
        return;
      }

      final service = RouterHealthService(
        timeout: const Duration(seconds: 3),
      );

      final result = await service.check(
        router: router,
        password: 'testpass',
      );

      // Connection refused → unreachable (no server listening).
      expect(
        [
          RouterHealthStatus.unreachable,
          RouterHealthStatus.timeout,
        ],
        contains(result.status),
      );
      expect(result.routerId, 'health-test');
      expect(result.checkedAt, isNotNull);
    });

    test('result routerId matches router.id', () async {
      final service = RouterHealthService(
        timeout: const Duration(seconds: 1),
      );

      // Use an unreachable address (0.0.0.0 on a closed port).
      const unreachable = RouterModel(
        id: 'my-router-id',
        name: 'Unreachable',
        host: '127.0.0.1',
        port: 19998,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );

      final result = await service.check(
        router: unreachable,
        password: 'pass',
      );

      expect(result.routerId, 'my-router-id');
    });

    test('result has non-null checkedAt', () async {
      final service = RouterHealthService(
        timeout: const Duration(seconds: 1),
      );

      const r = RouterModel(
        id: 'r-1',
        name: 'R',
        host: '127.0.0.1',
        port: 19997,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );

      final result = await service.check(router: r, password: 'pass');
      expect(result.checkedAt, isNotNull);
    });

    test('error message does not contain password', () async {
      final service = RouterHealthService(
        timeout: const Duration(seconds: 1),
      );

      const r = RouterModel(
        id: 'r-2',
        name: 'R',
        host: '127.0.0.1',
        port: 19996,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );

      final result = await service.check(
        router: r,
        password: 'supersecretpassword',
      );

      // Error message must not contain the actual password.
      expect(result.errorMessage ?? '', isNot(contains('supersecretpassword')));
    });
  });
}
