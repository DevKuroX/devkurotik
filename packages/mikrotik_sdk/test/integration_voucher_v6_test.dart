/// Phase 5 — Voucher integration test against CHR RouterOS v6.
///
/// Run with: dart test test/integration_voucher_v6_test.dart
///
/// Requires CHR v6 to be reachable at 139.162.35.252:8728.
/// This file is NOT run in CI — it requires a live RouterOS target.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

import 'integration_credentials.dart';

// Credentials loaded from env vars (CHR_V6_*) or chr6.txt (gitignored).
// Never hardcode credentials. See integration_credentials.dart.
String get _host => chrV6Host;
String get _username => chrV6User;
String get _password => chrV6Password;
int get _port => chrV6Port;

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

  group('CHR v6 — Phase 5 Voucher Integration', () {
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
      const testName = 'test-vc-phase5-v6-001';
      _createdUsers.add(testName);

      await client.command(
        '/ip/hotspot/user/add',
        params: {
          'name': testName,
          'password': testName,
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
        (i) => 'test-batch-v6-phase5-${i.toString().padLeft(3, '0')}',
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
      final scripts = await client.command('/system/script/print');
      expect(scripts, isA<List>());
    });
  });
}
