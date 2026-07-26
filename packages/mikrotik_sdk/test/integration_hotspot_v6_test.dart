/// Phase 4 — Live integration tests against CHR v6.49.17 (Linode Singapore).
///
/// Run with: dart test test/integration_hotspot_v6_test.dart
///
/// Target: Linode nanode ap-south Singapore — CHR RouterOS 6.49.17
/// Credentials from chr6.txt (gitignored).
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
    await client.disconnect();
  });

  group('CHR v6 — Hotspot Phase 4 integration', () {
    // ── Profiles ────────────────────────────────────────────────────────────

    test('/ip/hotspot/user/profile/print returns list', () async {
      await client.connect();
      final result = await client.command('/ip/hotspot/user/profile/print');
      expect(result, isA<List>());
      print('Profiles: ${result.map((r) => r['name']).toList()}');
    });

    // ── Active sessions ──────────────────────────────────────────────────────

    test('/ip/hotspot/active/print returns list', () async {
      await client.connect();
      final result = await client.command('/ip/hotspot/active/print');
      expect(result, isA<List>());
      print('Active sessions: ${result.length}');
    });

    // ── Users — CRUD cycle ───────────────────────────────────────────────────

    test('add/list/edit/delete hotspot user cycle', () async {
      await client.connect();

      const testName = 'p4test-v6-user';
      const testPass = 'TestPass123';

      // Clean up any leftover.
      final existing = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      for (final u in existing) {
        final id = u['.id'];
        if (id != null) {
          await client.command(
            '/ip/hotspot/user/remove',
            params: {'.id': id},
          );
        }
      }

      // Add user.
      await client.command('/ip/hotspot/user/add', params: {
        'name': testName,
        'password': testPass,
        'profile': 'default',
        'server': 'all',
        'comment': 'phase4-v6-test',
      });
      print('Added user: $testName');

      // List and find.
      final listResult = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      expect(listResult, isNotEmpty);
      final user = listResult.first;
      expect(user['name'], testName);
      final userId = user['.id']!;
      print('User found: $user');

      // Edit.
      await client.command('/ip/hotspot/user/set', params: {
        '.id': userId,
        'comment': 'phase4-v6-edited',
      });

      final editedList = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      expect(editedList.first['comment'], 'phase4-v6-edited');
      print('User edited: comment = ${editedList.first['comment']}');

      // Disable.
      await client.command('/ip/hotspot/user/set', params: {
        '.id': userId,
        'disabled': 'yes',
      });
      final disabledList = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      expect(disabledList.first['disabled'], 'true');

      // Enable.
      await client.command('/ip/hotspot/user/set', params: {
        '.id': userId,
        'disabled': 'no',
      });

      // Delete.
      await client.command('/ip/hotspot/user/remove', params: {'.id': userId});

      // Verify.
      final deletedList = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      expect(deletedList, isEmpty);
      print('User lifecycle test complete on v6');
    });

    // ── Cookies ─────────────────────────────────────────────────────────────

    test('/ip/hotspot/cookie/print returns list', () async {
      await client.connect();
      final result = await client.command('/ip/hotspot/cookie/print');
      expect(result, isA<List>());
      print('Cookies: ${result.length}');
    });

    // ── Hosts ────────────────────────────────────────────────────────────────

    test('/ip/hotspot/host/print returns list', () async {
      await client.connect();
      final result = await client.command('/ip/hotspot/host/print');
      expect(result, isA<List>());
      print('Hosts: ${result.length}');
    });

    // ── Version confirmation ──────────────────────────────────────────────────

    test('router version is 6.x', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      final version = result.first['version'] ?? '';
      print('CHR v6 version: $version');
      expect(version, startsWith('6.'));
    });
  });
}
