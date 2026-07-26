/// Phase 7 — Live integration tests against CHR v6.49.17 (Linode Singapore).
///
/// Run with: dart test test/integration_ppp_v6_test.dart
///
/// Validates PppService and QueueService operations against real RouterOS v6.
/// Credentials from chr6.txt (gitignored). NEVER commit credentials.
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

const _testSecretName = 'p7test-ppp-v6';

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

  group('CHR v6 — Phase 7 PPP + Queue integration', () {
    test('1. Version confirms v6', () async {
      await client.connect();
      final res = await client.command('/system/resource/print');
      expect(res, isNotEmpty);
      final version = res[0]['version'] ?? '';
      expect(version, startsWith('6.'),
          reason: 'Expected ROS v6.x, got: $version');
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
        'password': 'testv6pass',
        'service': 'l2tp',
        'profile': 'default',
        'comment': 'Phase 7 v6 test',
      });

      final created = await client.command('/ppp/secret/print',
          query: {'name': _testSecretName});
      expect(created, isNotEmpty);
      expect(created[0]['name'], _testSecretName);
      expect(created[0]['service'], 'l2tp');
    });

    test('6. List simple queues (read-only)', () async {
      await client.connect();
      final result = await client.command('/queue/simple/print');
      expect(result, isA<List>());
    });

    test('7. Delete PPP secret and verify cleanup', () async {
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
