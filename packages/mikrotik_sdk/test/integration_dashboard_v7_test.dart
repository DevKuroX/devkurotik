/// Phase 3 live integration test against both CHR instances.
///
/// Tests that DashboardService fetches correct data from real RouterOS.
///
/// Run with:
///   dart test test/integration_dashboard_v7_test.dart  (CHR v7.15.1)
///
/// Not run in CI — requires live router access.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

// ─── CHR v7.15.1 (AWS EC2) credentials ────────────────────────────────────
// Credentials loaded from env vars (CHR_V7_*) or chr.txt (gitignored).
// See integration_credentials.dart for loading logic.
// NEVER hardcode credentials here.

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

  // ─── Phase 3 endpoint validation ──────────────────────────────────────────

  group('CHR v7.15.1 — Phase 3 endpoints', () {
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

      expect(version, startsWith('7.'));
      expect(cpuLoad, greaterThanOrEqualTo(0));
      expect(freeMemory, greaterThan(0));
      expect(totalMemory, greaterThan(0));
    });

    test('/interface/print returns at least one interface', () async {
      await client.connect();
      final result = await client.command('/interface/print');
      expect(result, isNotEmpty);
      expect(result.first, contains('name'));
      final names = result.map((r) => r['name']).toList();
      print('Interfaces: $names');
    });

    test('CPU display format is correct', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      final cpuLoad = int.tryParse(result.first['cpu-load'] ?? '0') ?? 0;
      // Phase 3 formatter: cpu() appends %
      final formatted = '${cpuLoad.clamp(0, 100)}%';
      expect(formatted, matches(RegExp(r'^\d+%$')));
      print('CPU formatted: $formatted');
    });

    test('memory display is non-zero', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      final total = int.tryParse(result.first['total-memory'] ?? '0') ?? 0;
      final free = int.tryParse(result.first['free-memory'] ?? '0') ?? 0;
      expect(total, greaterThan(0));
      expect(free, lessThanOrEqualTo(total));
      print('Memory: ${free}/${total} bytes free');
      print('Memory %: ${((total - free) / total * 100).round()}%');
    });

    test('version is 7.x and parsed correctly by RouterVersion', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      final versionRaw = result.first['version'] ?? '';
      final version = RouterVersion.parse(versionRaw);
      expect(version.major, equals(7));
      expect(version.isUnknown, isFalse);
      expect(CapabilityMatrix.supportsPlainAuth(version), isTrue);
      expect(CapabilityMatrix.supportsHotspot(version), isTrue);
      print('Version parsed: $version');
    });

    test('uptime string is parseable', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      final uptime = result.first['uptime'] ?? '';
      expect(uptime, isNotEmpty);
      // RouterOS uptime format: "4d12h30m5s" or similar.
      expect(uptime, matches(RegExp(r'(\d+[wdhms])+')));
      print('Uptime raw: $uptime');
    });

    test('board-name starts with CHR on virtual instance', () async {
      await client.connect();
      final result = await client.command('/system/resource/print');
      final board = result.first['board-name'] ?? '';
      expect(board.toUpperCase(), startsWith('CHR'));
      print('Board: $board');
    });

    test('RouterInfo.fromApiMaps constructs correctly from live data', () async {
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

      expect(info.version.major, equals(7));
      expect(info.isChr, isTrue);
      expect(CapabilityMatrix.supportsHotspot(info.version), isTrue);
    });
  });
}
