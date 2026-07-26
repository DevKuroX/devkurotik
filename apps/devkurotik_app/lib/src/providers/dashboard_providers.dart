/// Phase 3 — Dashboard Riverpod providers.
///
/// Provider dependency graph:
///   routerRepositoryProvider          (Phase 2)
///   activeRouterProvider              (Phase 2)
///   dashboardServiceProvider          (Phase 3 — new)
///   dashboardProvider                 (Phase 3 — new, per-router)
///   activeDashboardProvider           (Phase 3 — new, active router view)
///   multiRouterDashboardProvider      (Phase 3 — new, all routers)
///   dashboardRefreshSettingsProvider  (Phase 3 — new, refresh config)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/router_repository.dart';
import '../domain/models/dashboard_data.dart';
import '../domain/models/router_model.dart';
import '../domain/services/dashboard_service.dart';
import 'router_providers.dart';

// ---------------------------------------------------------------------------
// Refresh settings
// ---------------------------------------------------------------------------

/// Configurable refresh interval for the dashboard.
///
/// A null value means manual-only refresh (no auto-polling).
class DashboardRefreshSettings {
  const DashboardRefreshSettings({this.interval});

  /// Null = manual refresh only.
  final Duration? interval;

  /// Whether auto-refresh is enabled.
  bool get autoRefresh => interval != null;

  DashboardRefreshSettings copyWith({Duration? interval}) =>
      DashboardRefreshSettings(interval: interval);

  /// Default: 30-second auto-refresh.
  static const defaultSettings = DashboardRefreshSettings(
    interval: Duration(seconds: 30),
  );

  /// Manual-only (no polling).
  static const manualOnly = DashboardRefreshSettings();
}

/// Mutable provider for dashboard refresh settings.
final dashboardRefreshSettingsProvider =
    NotifierProvider<DashboardRefreshSettingsNotifier, DashboardRefreshSettings>(
      DashboardRefreshSettingsNotifier.new,
    );

class DashboardRefreshSettingsNotifier
    extends Notifier<DashboardRefreshSettings> {
  @override
  DashboardRefreshSettings build() => DashboardRefreshSettings.defaultSettings;

  /// Enable auto-refresh with a specific interval.
  void setInterval(Duration interval) {
    state = DashboardRefreshSettings(interval: interval);
  }

  /// Disable auto-refresh (manual only).
  void disableAutoRefresh() {
    state = DashboardRefreshSettings.manualOnly;
  }
}

// ---------------------------------------------------------------------------
// Dashboard service provider
// ---------------------------------------------------------------------------

/// DashboardService singleton (timeout configured at 10s).
final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(timeout: const Duration(seconds: 10));
});

// ---------------------------------------------------------------------------
// Per-router dashboard state
// ---------------------------------------------------------------------------

/// Result carrying either live data, cached data, or an error.
///
/// Wraps [AsyncValue<DashboardData>] with an extra [cachedData] field
/// so the UI can show stale values alongside error messages.
class DashboardState {
  const DashboardState({
    required this.data,
    this.cachedData,
  });

  /// AsyncValue for the most recent fetch attempt.
  final AsyncValue<DashboardData> data;

  /// Cached snapshot from the last successful fetch (null on first load).
  final DashboardData? cachedData;

  bool get hasCache => cachedData != null;

  bool get isLoading => data is AsyncLoading;

  bool get hasError => data is AsyncError;

  bool get hasData => data is AsyncData;

  DashboardData? get liveData =>
      data is AsyncData ? (data as AsyncData<DashboardData>).value : null;

  /// The best data to display: live data if available, else cache.
  DashboardData? get displayData => liveData ?? cachedData?.asCached();
}

/// Family provider: dashboard state for a specific router ID.
final dashboardProvider =
    AsyncNotifierProviderFamily<DashboardNotifier, DashboardData, String>(
      DashboardNotifier.new,
    );

/// Notifier for a single router's dashboard data.
class DashboardNotifier
    extends FamilyAsyncNotifier<DashboardData, String> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  DashboardService get _service => ref.read(dashboardServiceProvider);

  @override
  Future<DashboardData> build(String arg) async {
    return _fetchData(arg);
  }

  /// Force a manual refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchData(arg));
  }

  Future<DashboardData> _fetchData(String routerId) async {
    // Get router model from the list.
    final routers = await ref.read(routerListProvider.future);
    final router = routers.where((r) => r.id == routerId).firstOrNull;
    if (router == null) {
      throw StateError('Router $routerId not found in list.');
    }

    final password = await _repo.getPassword(routerId);
    if (password == null) {
      throw StateError('No credentials found for router $routerId.');
    }

    return _service.fetch(router: router, password: password);
  }
}

// ---------------------------------------------------------------------------
// Active router dashboard
// ---------------------------------------------------------------------------

/// Dashboard data for the currently active router.
///
/// Returns [AsyncLoading] when no router is selected,
/// delegates to [dashboardProvider] when one is selected.
final activeDashboardProvider =
    AsyncNotifierProvider<ActiveDashboardNotifier, DashboardData?>(
      ActiveDashboardNotifier.new,
    );

class ActiveDashboardNotifier extends AsyncNotifier<DashboardData?> {
  @override
  Future<DashboardData?> build() async {
    final active = ref.watch(activeRouterProvider);
    if (active == null) return null;
    return ref.watch(dashboardProvider(active.id).future);
  }

  /// Refresh the active router's dashboard.
  Future<void> refresh() async {
    final active = ref.read(activeRouterProvider);
    if (active == null) return;
    await ref.read(dashboardProvider(active.id).notifier).refresh();
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Multi-router overview
// ---------------------------------------------------------------------------

/// Dashboard state for ALL persisted routers (multi-router overview).
///
/// Returns a map of router ID → DashboardData (or null if not yet loaded).
final multiRouterDashboardProvider =
    AsyncNotifierProvider<MultiRouterDashboardNotifier, List<DashboardData>>(
      MultiRouterDashboardNotifier.new,
    );

class MultiRouterDashboardNotifier
    extends AsyncNotifier<List<DashboardData>> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  DashboardService get _service => ref.read(dashboardServiceProvider);

  @override
  Future<List<DashboardData>> build() async {
    return _fetchAll();
  }

  /// Refresh all routers concurrently.
  Future<void> refreshAll() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchAll);
  }

  Future<List<DashboardData>> _fetchAll() async {
    final routers = await ref.read(routerListProvider.future);
    if (routers.isEmpty) return [];

    // Fetch all routers concurrently. Individual failures are caught
    // and reported as partial results — one bad router must not
    // prevent others from showing.
    final results = await Future.wait(
      routers.map((router) => _fetchOne(router)),
      eagerError: false,
    );

    return results.whereType<DashboardData>().toList();
  }

  Future<DashboardData?> _fetchOne(RouterModel router) async {
    try {
      final password = await _repo.getPassword(router.id);
      if (password == null) return null;
      return await _service.fetch(router: router, password: password);
    } on Exception {
      return null;
    }
  }
}
