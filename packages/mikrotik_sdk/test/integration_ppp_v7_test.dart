/// Phase 7 — Live integration tests against CHR v7.15.1 (AWS EC2).
///
/// Run with: dart test test/integration_ppp_v7_test.dart
///
/// Validates PppService and QueueService operations against real RouterOS v7.
/// Credentials from chr.txt (gitignored). NEVER commit credentials.
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

const _testSecretName = 'p7test-ppp-secret';

MikrotikClient _newClient() => MikrotikClient(
      host: _host,
      username: _username,
      password: _password,
      port: _port,
      timeout: const Duration(seconds: 15),
      maxRetries: 0,
    );

Future<void> _cleanupTestSecret() async {
  final c = _newClient();
  await c.connect();
  try {
    final existing = await c.command('/ppp/secret/print',
        query: {'name': _testSecretName});
    if (existing.isNotEmpty) {
      await c.command('/ppp/secret/remove',
          params: {'.id': existing[0]['.id']!});
    }
  } catch (_) {}
  await c.disconnect();
}

void main() {
  late MikrotikClient client;

  setUpAll(() async {
    await _cleanupTestSecret();
  });

  setUp(() {
    client = _newClient();
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('CHR v7 — Phase 7 PPP + Queue integration', () {
    test('1. Version confirms v7', () async {
      await client.connect();
      final res = await client.command('/system/resource/print');
      expect(res, isNotEmpty);
      final version = res[0]['version'] ?? '';
      expect(version, startsWith('7.'),
          reason: 'Expected ROS v7.x, got: $version');
    });

    test('2. List PPP secrets (read-only)', () async {
      await client.connect();
      final result = await client.command('/ppp/secret/print');
      expect(result, isA<List>());
    });

    test('3. List PPP profiles (read-only)', () async {
      await client.connect();
      final result = await client.command('/ppp/profile/print');
      expect(result, isA<List>());
    });

    test('4. List PPP active sessions (read-only)', () async {
      await client.connect();
      final result = await client.command('/ppp/active/print');
      expect(result, isA<List>());
    });

    test('5. Add PPP secret', () async {
      await client.connect();
      await client.command('/ppp/secret/add', params: {
        'name': _testSecretName,
        'password': 'testpass123',
        'service': 'pppoe',
        'profile': 'default',
        'comment': 'Phase 7 test secret',
      });

      final created = await client.command('/ppp/secret/print',
          query: {'name': _testSecretName});
      expect(created, isNotEmpty);
      expect(created[0]['name'], _testSecretName);
      expect(created[0]['service'], 'pppoe');
      expect(created[0]['comment'], 'Phase 7 test secret');
    });

    test('6. Update PPP secret (change comment and disable)', () async {
      await client.connect();

      final existing = await client.command('/ppp/secret/print',
          query: {'name': _testSecretName});
      expect(existing, isNotEmpty);

      await client.command('/ppp/secret/set', params: {
        '.id': existing[0]['.id']!,
        'comment': 'Phase 7 test secret - updated',
        'disabled': 'yes',
      });

      final updated = await client.command('/ppp/secret/print',
          query: {'name': _testSecretName});
      expect(updated, isNotEmpty);
      expect(updated[0]['comment'], 'Phase 7 test secret - updated');
      expect(updated[0]['disabled'], 'true');
    });

    test('7. List simple queues (read-only)', () async {
      await client.connect();
      final result = await client.command('/queue/simple/print');
      expect(result, isA<List>());
    });

    test('8. Delete PPP secret and verify cleanup', () async {
      await client.connect();

      final existing = await client.command('/ppp/secret/print',
          query: {'name': _testSecretName});
      if (existing.isNotEmpty) {
        await client.command('/ppp/secret/remove',
            params: {'.id': existing[0]['.id']!});
      }

      final afterDelete = await client.command('/ppp/secret/print',
          query: {'name': _testSecretName});
      expect(afterDelete, isEmpty);
    });
  });
}
