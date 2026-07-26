/// Unit tests for DashboardData — Phase 3.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/dashboard_data.dart';

DashboardData _makeData({
  int cpuLoad = 20,
  int totalMemory = 536870912, // 512 MB
  int freeMemory = 268435456, // 256 MB
  String uptime = '4d12h30m',
  String version = '7.15.1 (stable)',
  String board = 'CHR',
  List<InterfaceSummary>? interfaces,
  DashboardDataSource source = DashboardDataSource.live,
}) {
  return DashboardData(
    routerId: 'router-1',
    routerName: 'Test Router',
    routerHost: '192.168.88.1',
    identity: 'test-router',
    version: version,
    board: board,
    cpuLoad: cpuLoad,
    totalMemory: totalMemory,
    freeMemory: freeMemory,
    uptime: uptime,
    interfaces: interfaces ??
        [
          const InterfaceSummary(name: 'ether1', running: true),
          const InterfaceSummary(name: 'ether2', running: false),
        ],
    fetchedAt: DateTime(2026, 7, 26, 12),
    source: source,
  );
}

void main() {
  group('DashboardData — computed properties', () {
    test('usedMemory is totalMemory - freeMemory', () {
      final data = _makeData(totalMemory: 512, freeMemory: 200);
      expect(data.usedMemory, equals(312));
    });

    test('memoryUsageFraction is correct', () {
      final data = _makeData(
        totalMemory: 536870912,
        freeMemory: 268435456,
      );
      expect(data.memoryUsageFraction, closeTo(0.5, 0.001));
    });

    test('memoryUsageFraction is 0 when totalMemory is 0', () {
      final data = _makeData(totalMemory: 0, freeMemory: 0);
      expect(data.memoryUsageFraction, equals(0.0));
    });

    test('memoryUsagePercent rounds correctly', () {
      final data = _makeData(
        totalMemory: 536870912,
        freeMemory: 268435456,
      );
      expect(data.memoryUsagePercent, equals(50));
    });

    test('runningInterfaceCount counts only running interfaces', () {
      final data = _makeData(
        interfaces: [
          const InterfaceSummary(name: 'ether1', running: true),
          const InterfaceSummary(name: 'ether2', running: true),
          const InterfaceSummary(name: 'wlan1', running: false),
        ],
      );
      expect(data.runningInterfaceCount, equals(2));
      expect(data.totalInterfaceCount, equals(3));
    });

    test('isLive is true for live data', () {
      final data = _makeData(source: DashboardDataSource.live);
      expect(data.isLive, isTrue);
    });

    test('isLive is false for cached data', () {
      final data = _makeData(source: DashboardDataSource.cached);
      expect(data.isLive, isFalse);
    });
  });

  group('DashboardData.asCached', () {
    test('returns copy with cached source', () {
      final data = _makeData(source: DashboardDataSource.live);
      final cached = data.asCached();

      expect(cached.source, equals(DashboardDataSource.cached));
      expect(cached.isLive, isFalse);
      // Other fields preserved.
      expect(cached.routerId, equals(data.routerId));
      expect(cached.version, equals(data.version));
      expect(cached.cpuLoad, equals(data.cpuLoad));
    });
  });

  group('DashboardData.toString', () {
    test('contains key fields', () {
      final data = _makeData(cpuLoad: 42, version: '7.15.1 (stable)');
      final str = data.toString();
      expect(str, contains('router-1'));
      expect(str, contains('7.15.1'));
      expect(str, contains('42%'));
    });
  });

  group('InterfaceSummary', () {
    test('stores name and running state', () {
      const iface = InterfaceSummary(
        name: 'ether1',
        running: true,
        type: 'ether',
        macAddress: 'AA:BB:CC:DD:EE:FF',
      );
      expect(iface.name, equals('ether1'));
      expect(iface.running, isTrue);
      expect(iface.type, equals('ether'));
    });

    test('toString does not throw', () {
      const iface = InterfaceSummary(name: 'wlan1', running: false);
      expect(iface.toString(), isNotEmpty);
    });
  });

  group('DashboardDataSource enum', () {
    test('all values are present', () {
      expect(
        DashboardDataSource.values,
        containsAll([DashboardDataSource.live, DashboardDataSource.cached]),
      );
    });
  });
}
