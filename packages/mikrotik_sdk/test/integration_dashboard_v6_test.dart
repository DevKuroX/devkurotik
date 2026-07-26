/// Phase 3 live integration test against CHR v6.49.17 (Linode).
///
/// Tests that DashboardService endpoints work correctly on RouterOS v6.
///
/// Run with:
///   dart test test/integration_dashboard_v6_test.dart
///
/// Not run in CI — requires live Linode CHR v6 instance.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

// ─── CHR v6.49.17 (Linode Singapore) credentials ──────────────────────────
// Credentials are read from chr6.txt at test runtime:
//   Host: 139.162.35.252
//   Username: admin
//   Password: (empty)
//   Port: 8728

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

  // ─── Phase 3 endpoint validation ──────────────────────────────────────────

  group('CHR v6.49.17 — Phase 3 endpoints', () {
    test('/system/identity/print returns identity name', () async {
      await client.connect();
      final result = await client.command('/system/identity/print');
      expect(result, isNotEmpty);
      expect(result.first, contains('name'));
      print('Identity: ${result.first['name']}');
    });

    test('/system/resource/print returns CPU, memory, version, board', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      expect(result, isNotEmpty);
      final res = result.first;

      expect(res, contains('version'));
      expect(res, contains('cpu-load'));
      expect(res, contains('free-memory'));
      expect(res, contains('total-memory'));
      expect(res, contains('uptime'));
      expect(res, contains('board-name'));

      final version = res['version'] ?? '';
      final cpuLoad = int.tryParse(res['cpu-load'] ?? '') ?? -1;
      final freeMemory = int.tryParse(res['free-memory'] ?? '') ?? -1;
      final totalMemory = int.tryParse(res['total-memory'] ?? '') ?? -1;

      print('Version    : $version');
      print('Board      : ${res['board-name']}');
      print('CPU load   : $cpuLoad%');
      print('Free mem   : ${RouterosFormat.bytes(freeMemory)}');
      print('Total mem  : ${RouterosFormat.bytes(totalMemory)}');
      print('Uptime     : ${res['uptime']}');

      expect(version, startsWith('6.49'));
      expect(cpuLoad, greaterThanOrEqualTo(0));
      expect(freeMemory, greaterThan(0));
      expect(totalMemory, greaterThan(0));
    });

    test('/interface/print returns at least one interface', () async {
      await client.connect();
      final result = await client.command('/interface/print');
      expect(result, isNotEmpty);
      final names = result.map((r) => r['name']).toList();
      print('Interfaces: $names');
    });

    test('version is 6.49 and parsed correctly by RouterVersion', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      final versionRaw = result.first['version'] ?? '';
      final version = RouterVersion.parse(versionRaw);
      expect(version.major, equals(6));
      expect(version.minor, equals(49));
      expect(version.isUnknown, isFalse);
      expect(CapabilityMatrix.supportsPlainAuth(version), isTrue);
      expect(CapabilityMatrix.requiresMd5Auth(version), isFalse);
      print('Version parsed: $version');
    });

    test('uptime string is parseable', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      final uptime = result.first['uptime'] ?? '';
      expect(uptime, isNotEmpty);
      expect(uptime, matches(RegExp(r'(\d+[wdhms])+')));
      print('Uptime raw: $uptime');
    });

    test('memory is available on v6', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      final total = int.tryParse(result.first['total-memory'] ?? '0') ?? 0;
      final free = int.tryParse(result.first['free-memory'] ?? '0') ?? 0;
      expect(total, greaterThan(0));
      expect(free, greaterThanOrEqualTo(0));
      print('Memory: ${RouterosFormat.bytes(total - free)} / ${RouterosFormat.bytes(total)} used');
    });

    test('RouterInfo from v6 data shows correct major version', () async {
      await client.connect();
      final identityResult = await client.command('/system/identity/print');
      final resourceResult = await client.command('/system/resource/print');

      final identityMap = identityResult.isNotEmpty ? identityResult.first : <String, String>{};
      final resourceMap = resourceResult.isNotEmpty ? resourceResult.first : <String, String>{};

      final info = RouterInfo.fromApiMaps(
        identityMap: identityMap,
        resourceMap: resourceMap,
        detectedAt: DateTime.now(),
      );

      print('RouterInfo.version : ${info.version.raw}');
      print('RouterInfo.board   : ${info.board}');
      print('RouterInfo.isChr   : ${info.isChr}');

      expect(info.version.major, equals(6));
      expect(CapabilityMatrix.supportsHotspot(info.version), isTrue);
    });
  });
}
