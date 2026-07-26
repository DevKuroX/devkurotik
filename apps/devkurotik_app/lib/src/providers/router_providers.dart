/// Phase 2 Riverpod providers for router management.
///
/// Provider dependency graph:
///   appDatabaseProvider → routerRepositoryProvider → routerListProvider
///                                                   → activeRouterProvider
///                                                   → routerHealthProvider
///   routerHealthServiceProvider → routerHealthProvider
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/database/app_database.dart';
import '../data/repositories/router_repository.dart';
import '../domain/models/router_model.dart';
import '../domain/services/router_health_service.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

/// Singleton AppDatabase instance.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Singleton FlutterSecureStorage instance.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

/// Singleton RouterRepository.
final routerRepositoryProvider = Provider<RouterRepository>((ref) {
  return RouterRepository(
    db: ref.watch(appDatabaseProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

/// Singleton RouterHealthService.
final routerHealthServiceProvider = Provider<RouterHealthService>((ref) {
  return RouterHealthService();
});

// ---------------------------------------------------------------------------
// Router list state
// ---------------------------------------------------------------------------

/// Async list of all persisted routers (ordered by last-used then name).
final routerListProvider =
    AsyncNotifierProvider<RouterListNotifier, List<RouterModel>>(
      RouterListNotifier.new,
    );

/// Notifier for [routerListProvider].
class RouterListNotifier extends AsyncNotifier<List<RouterModel>> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);

  @override
  Future<List<RouterModel>> build() async {
    return _repo.listRouters();
  }

  /// Reload the router list from the database.
  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_repo.listRouters);
  }

  /// Add a router and refresh.
  Future<void> addRouter({
    required RouterModel router,
    required String password,
  }) async {
    await _repo.addRouter(router: router, password: password);
    await reload();
  }

  /// Update a router and refresh.
  Future<void> updateRouter({
    required RouterModel router,
    String? password,
  }) async {
    await _repo.updateRouter(router: router, password: password);
    await reload();
  }

  /// Delete a router and refresh.
  Future<void> deleteRouter(String routerId) async {
    await _repo.deleteRouter(routerId);

    // If the deleted router was active, clear active selection.
    final activeNotifier = ref.read(activeRouterProvider.notifier);
    final current = ref.read(activeRouterProvider);
    if (current?.id == routerId) {
      activeNotifier.clearActive();
    }

    await reload();
  }
}

// ---------------------------------------------------------------------------
// Active router state
// ---------------------------------------------------------------------------

/// The currently selected/active router (null = none selected).
final activeRouterProvider =
    NotifierProvider<ActiveRouterNotifier, RouterModel?>(
      ActiveRouterNotifier.new,
    );

/// Notifier for [activeRouterProvider].
class ActiveRouterNotifier extends Notifier<RouterModel?> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);

  @override
  RouterModel? build() {
    // Eager-load last-used on startup (async kick-off).
    _loadLastUsed();
    return null;
  }

  Future<void> _loadLastUsed() async {
    final router = await _repo.getLastUsedRouter();
    if (router != null) {
      state = router;
    }
  }

  /// Select a router as active and persist as last-used.
  Future<void> selectRouter(RouterModel router) async {
    state = router;
    await _repo.setLastUsedRouter(router.id);
    // Refresh the list so lastUsedAt ordering updates.
    await ref.read(routerListProvider.notifier).reload();
  }

  /// Clear the active selection (e.g. after deletion).
  void clearActive() {
    state = null;
  }
}

// ---------------------------------------------------------------------------
// Health check state
// ---------------------------------------------------------------------------

/// Health check results keyed by router id.
final routerHealthProvider =
    AsyncNotifierProvider<RouterHealthNotifier, Map<String, HealthCheckResult>>(
      RouterHealthNotifier.new,
    );

/// Notifier for [routerHealthProvider].
class RouterHealthNotifier
    extends AsyncNotifier<Map<String, HealthCheckResult>> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  RouterHealthService get _health => ref.read(routerHealthServiceProvider);

  @override
  Future<Map<String, HealthCheckResult>> build() async {
    return {};
  }

  /// Run a health check for a single router.
  Future<void> checkRouter(RouterModel router) async {
    final password = await _repo.getPassword(router.id);
    if (password == null) {
      // No credentials stored — mark as auth failed.
      final result = HealthCheckResult(
        routerId: router.id,
        status: RouterHealthStatus.authFailed,
        errorMessage: 'No credentials found.',
        checkedAt: DateTime.now(),
      );
      _updateResult(router.id, result);
      return;
    }

    // Update to a checking state (optimistic empty result with unknown).
    final checking = HealthCheckResult(
      routerId: router.id,
      status: RouterHealthStatus.unknown,
      checkedAt: DateTime.now(),
    );
    _updateResult(router.id, checking);

    final result = await _health.check(router: router, password: password);
    _updateResult(router.id, result);
  }

  /// Run health checks for all routers.
  Future<void> checkAll(List<RouterModel> routers) async {
    await Future.wait(routers.map(checkRouter));
  }

  void _updateResult(String routerId, HealthCheckResult result) {
    final current = state.valueOrNull ?? {};
    state = AsyncData({...current, routerId: result});
  }
}
