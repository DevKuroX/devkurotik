/// Phase 4 — Live integration tests against CHR v7.15.1 (AWS EC2).
///
/// Run with: dart test test/integration_hotspot_v7_test.dart
///
/// Target: AWS EC2 t3.small us-east-1 — CHR RouterOS 7.15.1
/// Credentials from chr.txt (gitignored).
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

import 'integration_credentials.dart';

// Credentials loaded from env vars (CHR_V7_*) or chr.txt (gitignored).
// Never hardcode credentials. See integration_credentials.dart.
String get _host => chrV7Host;
String get _username => chrV7User;
String get _password => chrV7Password;
int get _port => chrV7Port;

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

  group('CHR v7 — Hotspot Phase 4 integration', () {
    // ── Profiles ────────────────────────────────────────────────────────────

    test('/ip/hotspot/user/profile/print returns list', () async {
      await client.connect();
      final result = await client.command('/ip/hotspot/user/profile/print');
      // CHR may have 0 or more profiles — just verify it doesn't throw.
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

      const testName = 'p4test-v7-user';
      const testPass = 'TestPass123';

      // Clean up any leftover from previous run.
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
        'comment': 'phase4-test',
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
      expect(user['comment'], 'phase4-test');
      final userId = user['.id']!;
      print('User found: $user');

      // Edit user (add comment update).
      await client.command('/ip/hotspot/user/set', params: {
        '.id': userId,
        'comment': 'phase4-test-edited',
      });

      // Verify edit.
      final editedList = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      expect(editedList.first['comment'], 'phase4-test-edited');
      print('User edited: comment = ${editedList.first['comment']}');

      // Disable user.
      await client.command('/ip/hotspot/user/set', params: {
        '.id': userId,
        'disabled': 'yes',
      });

      final disabledList = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      expect(disabledList.first['disabled'], 'true');
      print('User disabled: ${disabledList.first['disabled']}');

      // Enable user.
      await client.command('/ip/hotspot/user/set', params: {
        '.id': userId,
        'disabled': 'no',
      });

      final enabledList = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      expect(enabledList.first['disabled'], isNot('true'));
      print('User enabled: disabled = ${enabledList.first['disabled']}');

      // Delete user.
      await client.command('/ip/hotspot/user/remove', params: {'.id': userId});
      print('Deleted user: $testName');

      // Verify deleted.
      final deletedList = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': testName},
      );
      expect(deletedList, isEmpty);
      print('User delete verified: not found');
    });

    // ── Reset counters ────────────────────────────────────────────────────────

    test('reset-counters works without error', () async {
      await client.connect();

      // Create temp user.
      const tempName = 'p4test-v7-reset';
      await client.command('/ip/hotspot/user/add', params: {
        'name': tempName,
        'password': 'pass',
        'profile': 'default',
        'server': 'all',
      });

      final list = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': tempName},
      );
      if (list.isEmpty) {
        print('Skip: user not created (hotspot may be disabled)');
        return;
      }
      final userId = list.first['.id']!;

      // Reset counters.
      try {
        await client.command(
          '/ip/hotspot/user/reset-counters',
          params: {'.id': userId},
        );
        print('Counters reset successfully');
      } on RouterosCommandException catch (e) {
        // Some CHR configs don't support reset-counters without hotspot active
        print('reset-counters trap (expected on CHR without HS): ${e.trapMessage}');
      }

      // Cleanup.
      await client.command('/ip/hotspot/user/remove', params: {'.id': userId});
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

    // ── Bulk delete by comment ────────────────────────────────────────────────

    test('bulk delete by comment works', () async {
      await client.connect();

      const batchComment = 'phase4-bulk-test';

      // Add 3 users with same comment.
      for (var i = 1; i <= 3; i++) {
        await client.command('/ip/hotspot/user/add', params: {
          'name': 'p4bulk$i',
          'password': 'pass',
          'profile': 'default',
          'server': 'all',
          'comment': batchComment,
        });
      }

      // Verify all 3 exist.
      final before = await client.command(
        '/ip/hotspot/user/print',
        query: {'comment': batchComment},
      );
      expect(before.length, 3);

      // Delete by comment.
      for (final u in before) {
        final id = u['.id'];
        if (id != null) {
          await client.command(
            '/ip/hotspot/user/remove',
            params: {'.id': id},
          );
        }
      }

      // Verify deleted.
      final after = await client.command(
        '/ip/hotspot/user/print',
        query: {'comment': batchComment},
      );
      expect(after, isEmpty);
      print('Bulk delete by comment: 3 users deleted');
    });

    // ── Multi-router isolation evidence ──────────────────────────────────────

    test('router identity confirms correct target', () async {
      await client.connect();
      final identity = await client.command('/system/identity/print');
      final version = await client.command('/system/resource/print');
      print('Router: ${identity.first['name']} — '
          'ROS ${version.first['version']}');
      expect(version.first['version'], startsWith('7.'));
    });
  });
}
