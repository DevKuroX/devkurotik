/// Real integration test against CHR RouterOS v7.
///
/// Run with: dart test test/integration_chr_test.dart
///
/// Requires environment variables or edit the constants below.
/// This file is NOT run in CI — it requires a live RouterOS target.
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
      timeout: const Duration(seconds: 10),
      maxRetries: 0,
    );
  });

  tearDown(() async {
    await client.disconnect();
  });

  group('CHR v7 — live integration tests', () {
    test('connects and authenticates successfully', () async {
      await client.connect();
      expect(client.isConnected, isTrue);
      expect(client.connectionState, equals(ConnectionState.connected));
    });

    test('reads /system/identity/print', () async {
      await client.connect();
      final result = await client.command('/system/identity/print');
      expect(result, isNotEmpty);
      expect(result.first, contains('name'));
      print('Router identity: ${result.first['name']}');
    });

    test('reads /system/resource/print', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      expect(result, isNotEmpty);
      final res = result.first;
      expect(res, contains('version'));
      expect(res, contains('cpu-load'));
      expect(res, contains('free-memory'));
      print('RouterOS version: ${res['version']}');
      print('CPU load: ${res['cpu-load']}%');
      print('Free memory: ${RouterosFormat.bytes(int.tryParse(res['free-memory'] ?? '0') ?? 0)}');
    });

    test('reads /system/routerboard/print (CHR returns trap — expected)', () async {
      await client.connect();
      // CHR (virtual router) does not have routerboard hardware.
      // RouterOS v7 returns !trap for this command on CHR — this is correct behavior.
      await expectLater(
        client.command('/system/routerboard/print'),
        throwsA(isA<RouterosCommandException>()),
      );
      print('CHR correctly returns trap for /system/routerboard/print');
    });

    test('reads /system/clock/print', () async {
      await client.connect();
      final result = await client.command('/system/clock/print');
      expect(result, isNotEmpty);
      expect(result.first, contains('time'));
      print('Router time: ${result.first['time']} ${result.first['date']}');
    });

    test('reads /interface/print', () async {
      await client.connect();
      final result = await client.command('/interface/print');
      expect(result, isNotEmpty);
      print('Interfaces: ${result.map((r) => r['name']).toList()}');
    });

    test('wrong password throws RouterosAuthException', () async {
      final badClient = MikrotikClient(
        host: _host,
        username: _username,
        password: 'wrongpassword123',
        port: _port,
        timeout: const Duration(seconds: 5),
        maxRetries: 0,
      );
      await expectLater(
        badClient.connect(),
        throwsA(isA<RouterosAuthException>()),
      );
    });

    test('wrong port throws connection-related exception', () async {
      final badClient = MikrotikClient(
        host: _host,
        username: _username,
        password: _password,
        port: 9999,
        timeout: const Duration(seconds: 3),
        maxRetries: 0,
      );
      await expectLater(
        badClient.connect(),
        throwsA(
          anyOf(
            isA<RouterosConnectionException>(),
            isA<RouterosTimeoutException>(),
            isA<RouterosRetryExhaustedException>(),
          ),
        ),
      );
    });

    test('disconnect then reconnect works', () async {
      await client.connect();
      expect(client.isConnected, isTrue);
      await client.disconnect();
      expect(client.isConnected, isFalse);

      // Small delay — RouterOS v7 may have a brief session cooldown after disconnect
      await Future<void>.delayed(const Duration(seconds: 2));

      // Reconnect with a fresh client
      final client2 = MikrotikClient(
        host: _host,
        username: _username,
        password: _password,
        port: _port,
        timeout: const Duration(seconds: 10),
        maxRetries: 0,
      );
      await client2.connect();
      expect(client2.isConnected, isTrue);
      await client2.disconnect();
    });
  });
}
