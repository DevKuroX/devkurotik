/// Phase 5 — Voucher integration test against CHR RouterOS v7.
///
/// Run with: dart test test/integration_voucher_v7_test.dart
///
/// Requires CHR v7 to be reachable at 54.147.121.92:8728.
/// This file is NOT run in CI — it requires a live RouterOS target.
///
/// SECURITY: Passwords are read from constants here for the test-only
/// CHR instance. Never commit real production credentials.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

const _host = '54.147.121.92';
const _username = 'admin';
const _password = 'Ssh19233@';
const _port = 8728;

/// Generated test usernames — tracked for cleanup.
final _createdUsers = <String>[];

void main() {
  late MikrotikClient client;

  setUp(() {
    client = MikrotikClient(
      host: _host,
      username: _username,
      password: _password,
      port: _port,
      timeout: const Duration(seconds: 15),
      maxRetries: 0,
    );
  });

  tearDown(() async {
    // Clean up any users created during this test run.
    if (_createdUsers.isNotEmpty && client.isConnected) {
      for (final name in _createdUsers) {
        try {
          final found = await client.command(
            '/ip/hotspot/user/print',
            query: {'name': name},
          );
          for (final row in found) {
            final id = row['.id'];
            if (id != null) {
              await client.command(
                '/ip/hotspot/user/remove',
                params: {'.id': id},
              );
            }
          }
        } on Exception {
          // Best-effort cleanup.
        }
      }
      _createdUsers.clear();
    }
    await client.disconnect();
  });

  group('CHR v7 — Phase 5 Voucher Integration', () {
    test('connects and authenticates successfully', () async {
      await client.connect();
      expect(client.isConnected, isTrue);
    });

    test('can list hotspot profiles', () async {
      await client.connect();
      final profiles = await client.command('/ip/hotspot/user/profile/print');
      expect(profiles, isA<List>());
    });

    test('can create a voucher user (voucher mode)', () async {
      await client.connect();
      const testName = 'test-vc-phase5-v7-001';
      _createdUsers.add(testName);

      await client.command(
        '/ip/hotspot/user/add',
        params: {
          'name': testName,
          'password': testName, // voucher mode: user == pass
          'profile': 'default',
          'comment': 'phase5-test',
        },
      );

      // Verify created.
      final users = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      expect(users.length, greaterThanOrEqualTo(1));
      expect(users.first['name'], equals(testName));
    });

    test('can create a userpass voucher (separate user/pass)', () async {
      await client.connect();
      const testName = 'test-up-phase5-v7-002';
      const testPass = 'pass-v7-002';
      _createdUsers.add(testName);

      await client.command(
        '/ip/hotspot/user/add',
        params: {
          'name': testName,
          'password': testPass,
          'profile': 'default',
          'comment': 'phase5-test',
        },
      );

      final users = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      expect(users.length, greaterThanOrEqualTo(1));
      expect(users.first['name'], equals(testName));
    });

    test('can create batch of 5 vouchers', () async {
      await client.connect();
      final batchNames = List.generate(
        5,
        (i) => 'test-batch-v7-phase5-${i.toString().padLeft(3, '0')}',
      );
      _createdUsers.addAll(batchNames);

      for (final name in batchNames) {
        await client.command(
          '/ip/hotspot/user/add',
          params: {
            'name': name,
            'password': name,
            'profile': 'default',
            'comment': 'vc-phase5-batch',
          },
        );
      }

      // Verify all were created.
      for (final name in batchNames) {
        final found = await client.command(
          '/ip/hotspot/user/print',
          query: {'name': name},
        );
        expect(found.length, greaterThanOrEqualTo(1),
            reason: 'User $name not found on router');
      }
    });

    test('can read /system/script for Quick Print compatibility', () async {
      await client.connect();
      // List scripts — should not throw even if empty.
      final scripts = await client.command('/system/script/print');
      expect(scripts, isA<List>());
    });

    test('can write and read Quick Print script', () async {
      await client.connect();
      const scriptName = 'test-qp-phase5-v7';
      const source =
          '#192.168.1.1#vc#8##digitMixed#default#1h#0#phase5-test';

      // Add script.
      await client.command(
        '/system/script/add',
        params: {
          'name': scriptName,
          'source': source,
          'comment': 'QuickPrintMikhmon',
        },
      );

      // Read it back.
      final scripts = await client.command(
        '/system/script/print',
        query: {'name': scriptName},
      );
      expect(scripts.length, greaterThanOrEqualTo(1));
      expect(scripts.first['source'], equals(source));
      expect(scripts.first['comment'], equals('QuickPrintMikhmon'));

      // Clean up.
      final id = scripts.first['.id'];
      if (id != null) {
        await client.command(
          '/system/script/remove',
          params: {'.id': id},
        );
      }
    });
  });
}
