/// DashboardService — Phase 3 dashboard data fetcher.
///
/// Fetches router monitoring data using exactly three endpoints:
///   - /system/resource/print
///   - /system/identity/print
///   - /interface/print
///
/// No other RouterOS endpoints are used in Phase 3.
// ignore_for_file: prefer_initializing_formals
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../models/router_model.dart';
import '../models/dashboard_data.dart';

/// Service for fetching dashboard data from a live MikroTik router.
///
/// One instance per call — create fresh or use [DashboardServiceFactory].
class DashboardService {
  DashboardService({Duration timeout = const Duration(seconds: 10)})
      : _timeout = timeout;

  final Duration _timeout;

  /// Fetch a fresh [DashboardData] snapshot for [router].
  ///
  /// [password] must come from flutter_secure_storage, never from the model.
  ///
  /// Throws [RouterosException] subclasses on auth/connection failure.
  Future<DashboardData> fetch({
    required RouterModel router,
    required String password,
  }) async {
    final client = MikrotikClient(
      host: router.host,
      username: router.username,
      password: password,
      port: router.port,
      timeout: _timeout,
      maxRetries: 0,
    );

    final fetchedAt = DateTime.now();

    try {
      await client.connect();

      // ── 1. /system/identity/print ──────────────────────────────────────────
      Map<String, String> identityMap = {};
      try {
        final res = await client.command('/system/identity/print');
        if (res.isNotEmpty) identityMap = res.first;
      } on RouterosException {
        // Non-fatal: identity may be missing on restricted accounts.
      }

      // ── 2. /system/resource/print ──────────────────────────────────────────
      Map<String, String> resourceMap = {};
      try {
        final res = await client.command('/system/resource/print');
        if (res.isNotEmpty) resourceMap = res.first;
      } on RouterosException {
        // Non-fatal: fallback to defaults.
      }

      // ── 3. /interface/print ────────────────────────────────────────────────
      List<Map<String, String>> interfaceRows = [];
      try {
        interfaceRows = await client.command('/interface/print');
      } on RouterosException {
        // Non-fatal: empty interface list.
      }

      await client.disconnect();

      return _buildData(
        router: router,
        identityMap: identityMap,
        resourceMap: resourceMap,
        interfaceRows: interfaceRows,
        fetchedAt: fetchedAt,
        source: DashboardDataSource.live,
      );
    } catch (_) {
      try {
        await client.disconnect();
      } on Exception {
        // Ignore disconnect errors during cleanup.
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static DashboardData _buildData({
    required RouterModel router,
    required Map<String, String> identityMap,
    required Map<String, String> resourceMap,
    required List<Map<String, String>> interfaceRows,
    required DateTime fetchedAt,
    required DashboardDataSource source,
  }) {
    final identity = identityMap['name'] ?? router.name;
    final version = resourceMap['version'] ?? '';
    final board = resourceMap['board-name'] ?? '';
    final cpuLoad = int.tryParse(resourceMap['cpu-load'] ?? '0') ?? 0;
    final totalMemory = int.tryParse(resourceMap['total-memory'] ?? '0') ?? 0;
    final freeMemory = int.tryParse(resourceMap['free-memory'] ?? '0') ?? 0;
    final uptime = resourceMap['uptime'] ?? '';
    final platform = resourceMap['platform'];
    final architecture = resourceMap['architecture-name'];

    final interfaces =
        interfaceRows.map((row) {
          final running = row['running'] == 'true';
          return InterfaceSummary(
            name: row['name'] ?? '',
            running: running,
            type: row['type'],
            macAddress: row['mac-address'],
          );
        }).toList();

    // Build RouterInfo from the fetched maps for capability display.
    RouterInfo? routerInfo;
    try {
      routerInfo = RouterInfo.fromApiMaps(
        identityMap: identityMap,
        resourceMap: resourceMap,
        detectedAt: fetchedAt,
      );
    } on Exception {
      // RouterInfo construction is non-fatal.
    }

    return DashboardData(
      routerId: router.id,
      routerName: router.name,
      routerHost: router.host,
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
      source: source,
      routerInfo: routerInfo,
    );
  }
}
