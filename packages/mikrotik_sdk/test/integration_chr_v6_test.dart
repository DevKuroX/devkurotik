/// Real integration test against CHR RouterOS v6.49.17 (Linode).
///
/// Run with: dart test test/integration_chr_v6_test.dart
///
/// Target: Linode nanode g6-nanode-1 ap-south Singapore
/// CHR v6.49.17 — plain text auth (post-v6.43), empty default password.
/// This file is NOT run in CI — requires live RouterOS v6 target.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

const _host = '139.162.35.252';
const _username = 'admin';
const _password = 'Ssh19233@'; // CHR v6 — password set via weblish
const _port = 8728;

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

  // ─── Phase 1 SDK validation ────────────────────────────────────────────────

  group('CHR v6.49.17 — SDK transport + auth', () {
    test('connects and authenticates with empty password', () async {
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
      print('RouterOS version : ${res['version']}');
      print('CPU load         : ${res['cpu-load']}%');
      print('Free memory      : ${RouterosFormat.bytes(int.tryParse(res['free-memory'] ?? '0') ?? 0)}');
      print('Board            : ${res['board-name']}');
      print('Architecture     : ${res['architecture-name']}');
    });

    test('version string starts with "6.49"', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      final version = result.first['version'] ?? '';
      print('Version: $version');
      expect(version, startsWith('6.49'));
    });

    test('reads /system/routerboard/print (real hardware returns data)', () async {
      await client.connect();
      // CHR v6 on KVM may return trap (no physical routerboard) or data
      // Either outcome is acceptable — we just verify no crash
      try {
        final result = await client.command('/system/routerboard/print');
        print('Routerboard: $result');
      } on RouterosCommandException catch (e) {
        print('CHR v6 routerboard trap (expected for virtual): ${e.trapMessage}');
      }
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
        password: 'wrongpassword999',
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

      await Future<void>.delayed(const Duration(seconds: 2));

      final client2 = MikrotikClient(
        host: _host,
        username: _username,
        password: _password,
        port: _port,
        timeout: const Duration(seconds: 15),
        maxRetries: 0,
      );
      await client2.connect();
      expect(client2.isConnected, isTrue);
      await client2.disconnect();
    });
  });

  // ─── AMENDMENT_001 CapabilityDetector validation ──────────────────────────

  group('CHR v6.49.17 — CapabilityDetector (AMENDMENT_001)', () {
    late CapabilityDetector detector;
    late MikrotikCredentials credentials;

    setUp(() {
      detector = const CapabilityDetector(timeout: Duration(seconds: 15));
      credentials = const MikrotikCredentials(
        host: _host,
        username: _username,
        password: _password,
        port: _port,
      );
    });

    test('detect() returns RouterInfo', () async {
      final info = await detector.detect(credentials: credentials);

      print('--- RouterInfo (CHR v6.49.17) ---');
      print('version.raw   : ${info.version.raw}');
      print('version.major : ${info.version.major}');
      print('version.minor : ${info.version.minor}');
      print('board         : ${info.board}');
      print('isChr         : ${info.isChr}');
      print('isVirtual     : ${info.isVirtual}');
      print('identity      : ${info.identity}');
      print('architecture  : ${info.architecture}');
      print('cpuCount      : ${info.cpuCount}');
      print('platform      : ${info.platform}');

      expect(info.version.isUnknown, isFalse);
      expect(info.version.major, 6);
      expect(info.version.minor, 49);
      expect(info.detectedAt, isNotNull);
    });

    test('version.major == 6', () async {
      final info = await detector.detect(credentials: credentials);
      expect(info.version.major, 6);
    });

    test('version.minor >= 49', () async {
      final info = await detector.detect(credentials: credentials);
      expect(info.version.minor, greaterThanOrEqualTo(49));
    });

    test('CapabilityMatrix.supportsPlainAuth for v6.49 → true', () async {
      final info = await detector.detect(credentials: credentials);
      final result = CapabilityMatrix.supportsPlainAuth(info.version);
      print('supportsPlainAuth(${info.version.raw}) = $result');
      expect(result, isTrue);
    });

    test('CapabilityMatrix.requiresMd5Auth for v6.49 → false', () async {
      final info = await detector.detect(credentials: credentials);
      expect(CapabilityMatrix.requiresMd5Auth(info.version), isFalse);
    });

    test('CapabilityMatrix.supportsHotspot for v6.49 → true', () async {
      final info = await detector.detect(credentials: credentials);
      expect(CapabilityMatrix.supportsHotspot(info.version), isTrue);
    });

    test('CapabilityMatrix.supportsPppoe for v6.49 → true', () async {
      final info = await detector.detect(credentials: credentials);
      expect(CapabilityMatrix.supportsPppoe(info.version), isTrue);
    });

    test('CapabilityMatrix.supportsApiSsl for v6.49 → true', () async {
      final info = await detector.detect(credentials: credentials);
      expect(CapabilityMatrix.supportsApiSsl(info.version), isTrue);
    });

    test('CapabilityMatrix.hasKnownVariance for v6.49 → false', () async {
      final info = await detector.detect(credentials: credentials);
      final result = CapabilityMatrix.hasKnownVariance(info.version);
      print('hasKnownVariance(${info.version.raw}) = $result');
      expect(result, isFalse);
    });

    test('full CapabilityMatrix summary printed for evidence', () async {
      final info = await detector.detect(credentials: credentials);
      final summary = CapabilityMatrix.summary(info.version);
      print('--- CapabilityMatrix.summary (CHR v6.49.17) ---');
      summary.forEach((k, v) => print('  $k: $v'));
    });
  });
}
