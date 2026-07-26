/// Phase 7 — PPP Riverpod providers.
///
/// Provider dependency graph:
///   routerRepositoryProvider (Phase 2)
///   activeRouterProvider     (Phase 2)
///   pppServiceProvider       (Phase 7 — new)
///   pppProvider              (Phase 7 — new, per-router family)
///   activePppProvider        (Phase 7 — new, active router)
///   pppSearchProvider        (Phase 7 — new, search query state)
///   pppActionsProvider       (Phase 7 — new, write operations)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/router_repository.dart';
import '../domain/models/ppp_models.dart';
import '../domain/models/router_model.dart';
import '../domain/services/ppp_service.dart';
import 'router_providers.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

/// Singleton [PppService].
final pppServiceProvider = Provider<PppService>((ref) {
  return const PppService(timeout: Duration(seconds: 10));
});

// ---------------------------------------------------------------------------
// Per-router PPP state
// ---------------------------------------------------------------------------

/// Family provider: full PPP data snapshot for a specific router ID.
///
/// arg = router ID (String).
final pppProvider =
    AsyncNotifierProviderFamily<PppNotifier, PppData, String>(
      PppNotifier.new,
    );

/// Notifier for a single router's [PppData].
class PppNotifier extends FamilyAsyncNotifier<PppData, String> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  PppService get _service => ref.read(pppServiceProvider);

  @override
  Future<PppData> build(String arg) async {
    return _fetchData(arg);
  }

  /// Force a manual refresh of all PPP data.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchData(arg));
  }

  Future<PppData> _fetchData(String routerId) async {
    final routers = await ref.read(routerListProvider.future);
    final router = routers.where((r) => r.id == routerId).firstOrNull;
    if (router == null) {
      throw StateError('Router $routerId not found.');
    }

    final password = await _repo.getPassword(routerId);
    if (password == null) {
      throw StateError('No credentials found for router $routerId.');
    }

    // Fetch secrets, profiles, and active sessions in parallel.
    final results = await Future.wait([
      _service.listSecrets(router, password),
      _service.listProfiles(router, password),
      _service.listActiveSessions(router, password),
    ]);

    return PppData(
      routerId: routerId,
      secrets: results[0] as List<PppSecret>,
      profiles: results[1] as List<PppProfile>,
      activeSessions: results[2] as List<PppActive>,
      fetchedAt: DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// Active router PPP
// ---------------------------------------------------------------------------

/// PPP data for the currently active router.
final activePppProvider =
    AsyncNotifierProvider<ActivePppNotifier, PppData?>(
      ActivePppNotifier.new,
    );

class ActivePppNotifier extends AsyncNotifier<PppData?> {
  @override
  Future<PppData?> build() async {
    final active = ref.watch(activeRouterProvider);
    if (active == null) return null;
    return ref.watch(pppProvider(active.id).future);
  }

  Future<void> refresh() async {
    final active = ref.read(activeRouterProvider);
    if (active == null) return;
    await ref.read(pppProvider(active.id).notifier).refresh();
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Search / filter state
// ---------------------------------------------------------------------------

/// Search query string for the PPP secret list.
final pppSearchProvider = NotifierProvider<PppSearchNotifier, String>(
  PppSearchNotifier.new,
);

class PppSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clearQuery() {
    state = '';
  }
}

/// Current PPP service type filter.
final pppServiceFilterProvider =
    NotifierProvider<PppServiceFilterNotifier, PppServiceType>(
      PppServiceFilterNotifier.new,
    );

class PppServiceFilterNotifier extends Notifier<PppServiceType> {
  @override
  PppServiceType build() => PppServiceType.any;

  void setFilter(PppServiceType type) {
    state = type;
  }

  void reset() {
    state = PppServiceType.any;
  }
}

// ---------------------------------------------------------------------------
// Derived: filtered + searched secret list
// ---------------------------------------------------------------------------

/// Filtered and searched list of PPP secrets for the active router.
final filteredPppSecretsProvider = Provider<List<PppSecret>>((ref) {
  final pppAsync = ref.watch(activePppProvider);
  final serviceFilter = ref.watch(pppServiceFilterProvider);
  final search = ref.watch(pppSearchProvider);

  final data = pppAsync.valueOrNull;
  if (data == null) return [];

  var secrets = data.secrets;

  // Apply service filter.
  if (serviceFilter != PppServiceType.any) {
    secrets = secrets.where((s) => s.service == serviceFilter).toList();
  }

  // Apply search.
  final q = search.trim().toLowerCase();
  if (q.isNotEmpty) {
    secrets = secrets
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.profile.toLowerCase().contains(q) ||
              (s.comment?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  return secrets;
});

// ---------------------------------------------------------------------------
// Write actions
// ---------------------------------------------------------------------------

/// Notifier that performs write operations on PPP secrets for the
/// currently active router. Refreshes [pppProvider] after each action.
final pppActionsProvider =
    AsyncNotifierProvider<PppActionsNotifier, void>(
      PppActionsNotifier.new,
    );

class PppActionsNotifier extends AsyncNotifier<void> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  PppService get _service => ref.read(pppServiceProvider);

  @override
  Future<void> build() async {}

  RouterModel _requireActiveRouter() {
    final active = ref.read(activeRouterProvider);
    if (active == null) throw StateError('No active router selected.');
    return active;
  }

  Future<String> _requirePassword(String routerId) async {
    final password = await _repo.getPassword(routerId);
    if (password == null) {
      throw StateError('No credentials found for router $routerId.');
    }
    return password;
  }

  void _refresh(String routerId) {
    ref.read(pppProvider(routerId).notifier).refresh();
  }

  /// Add a new PPP secret.
  Future<void> addSecret(PppSecretCreate params) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.addSecret(router, password, params);
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Update an existing PPP secret.
  Future<void> updateSecret(String secretId, PppSecretUpdate update) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.updateSecret(router, password, secretId, update);
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Delete a PPP secret. Requires prior confirmation.
  Future<void> deleteSecret(String secretId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.deleteSecret(router, password, secretId);
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Enable a PPP secret.
  Future<void> enableSecret(String secretId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.enableSecret(router, password, secretId);
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Disable a PPP secret.
  Future<void> disableSecret(String secretId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.disableSecret(router, password, secretId);
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Disconnect an active PPP session.
  Future<void> disconnectSession(String sessionId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.disconnectSession(router, password, sessionId);
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
