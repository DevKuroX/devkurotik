/// Dashboard data snapshot for a single router.
///
/// Populated from three RouterOS endpoints (Phase 3):
///   - /system/resource/print
///   - /system/identity/print
///   - /interface/print
///
/// Never holds credentials. All fields have safe defaults.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

// ---------------------------------------------------------------------------
// Interface summary
// ---------------------------------------------------------------------------

/// Minimal interface descriptor (name + running state only).
class InterfaceSummary {
  const InterfaceSummary({
    required this.name,
    required this.running,
    this.type,
    this.macAddress,
  });

  final String name;
  final bool running;

  /// Interface type (e.g. "ether", "wlan", "bridge"). May be null.
  final String? type;

  /// MAC address string. May be null.
  final String? macAddress;

  @override
  String toString() =>
      'InterfaceSummary(name: $name, running: $running, type: $type)';
}

// ---------------------------------------------------------------------------
// Dashboard data
// ---------------------------------------------------------------------------

/// Enum to distinguish data freshness in the dashboard.
enum DashboardDataSource {
  /// Data was just fetched from the live router.
  live,

  /// Data was returned from local cache due to a failed refresh.
  cached,
}

/// Immutable snapshot of router monitoring data.
///
/// Created by [DashboardService]. Never persisted — transient view model only.
class DashboardData {
  const DashboardData({
    required this.routerId,
    required this.routerName,
    required this.routerHost,
    required this.identity,
    required this.version,
    required this.board,
    required this.cpuLoad,
    required this.totalMemory,
    required this.freeMemory,
    required this.uptime,
    required this.interfaces,
    required this.fetchedAt,
    this.platform,
    this.architecture,
    this.source = DashboardDataSource.live,
    this.routerInfo,
  });

  /// Stable router ID from RouterModel.
  final String routerId;

  /// Human-readable router name from RouterModel.
  final String routerName;

  /// Router host/IP from RouterModel.
  final String routerHost;

  /// Router identity name (from /system/identity/print).
  final String identity;

  /// RouterOS version string (e.g. "7.15.1 (stable)").
  final String version;

  /// Board/model name (e.g. "CHR Amazon EC2 t3.small").
  final String board;

  /// CPU load percentage (0–100).
  final int cpuLoad;

  /// Total memory in bytes.
  final int totalMemory;

  /// Free memory in bytes.
  final int freeMemory;

  /// Uptime raw string from RouterOS (e.g. "4d12h0m0s").
  final String uptime;

  /// All interfaces returned by /interface/print.
  final List<InterfaceSummary> interfaces;

  /// When this snapshot was fetched.
  final DateTime fetchedAt;

  /// Optional platform (e.g. "MikroTik").
  final String? platform;

  /// Optional architecture (e.g. "x86_64").
  final String? architecture;

  /// Whether data is live or cached.
  final DashboardDataSource source;

  /// Optional full RouterInfo (populated if CapabilityDetector ran).
  final RouterInfo? routerInfo;

  /// Used memory in bytes.
  int get usedMemory => totalMemory - freeMemory;

  /// Memory usage as fraction [0.0 – 1.0].
  double get memoryUsageFraction =>
      totalMemory > 0 ? usedMemory / totalMemory : 0.0;

  /// Memory usage percentage (0–100 rounded).
  int get memoryUsagePercent => (memoryUsageFraction * 100).round();

  /// Number of running interfaces.
  int get runningInterfaceCount =>
      interfaces.where((i) => i.running).length;

  /// Total interface count.
  int get totalInterfaceCount => interfaces.length;

  /// Whether this snapshot is from live data (not cache).
  bool get isLive => source == DashboardDataSource.live;

  /// Returns a copy marked as [DashboardDataSource.cached].
  DashboardData asCached() => DashboardData(
    routerId: routerId,
    routerName: routerName,
    routerHost: routerHost,
    identity: identity,
    version: version,
    board: board,
    cpuLoad: cpuLoad,
    totalMemory: totalMemory,
    freeMemory: freeMemory,
    uptime: uptime,
    interfaces: interfaces,
    fetchedAt: fetchedAt,
    platform: platform,
    architecture: architecture,
    source: DashboardDataSource.cached,
    routerInfo: routerInfo,
  );

  @override
  String toString() =>
      'DashboardData(routerId: $routerId, identity: $identity, '
      'version: $version, cpu: $cpuLoad%, mem: $memoryUsagePercent%, '
      'uptime: $uptime, ifaces: $totalInterfaceCount, source: $source)';
}
