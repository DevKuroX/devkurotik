/// Phase 4 — Hotspot Riverpod providers.
///
/// Provider dependency graph:
///   routerRepositoryProvider (Phase 2)
///   activeRouterProvider     (Phase 2)
///   hotspotServiceProvider   (Phase 4 — new)
///   hotspotProvider          (Phase 4 — new, per-router family)
///   activeHotspotProvider    (Phase 4 — new, active router)
///   hotspotUserListProvider  (Phase 4 — new, filtered user list)
///   hotspotSearchProvider    (Phase 4 — new, search query state)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/router_repository.dart';
import '../domain/models/hotspot_models.dart';
import '../domain/models/router_model.dart';
import '../domain/services/hotspot_service.dart';
import 'router_providers.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

/// Singleton [HotspotService].
final hotspotServiceProvider = Provider<HotspotService>((ref) {
  return const HotspotService(timeout: Duration(seconds: 10));
});

// ---------------------------------------------------------------------------
// Per-router hotspot state
// ---------------------------------------------------------------------------

/// Family provider: full hotspot data snapshot for a specific router ID.
///
/// arg = router ID (String).
final hotspotProvider =
    AsyncNotifierProviderFamily<HotspotNotifier, HotspotData, String>(
      HotspotNotifier.new,
    );

/// Notifier for a single router's [HotspotData].
class HotspotNotifier extends FamilyAsyncNotifier<HotspotData, String> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  HotspotService get _service => ref.read(hotspotServiceProvider);

  @override
  Future<HotspotData> build(String arg) async {
    return _fetchData(arg);
  }

  /// Force a manual refresh of all hotspot data.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchData(arg));
  }

  Future<HotspotData> _fetchData(String routerId) async {
    final routers = await ref.read(routerListProvider.future);
    final router = routers.where((r) => r.id == routerId).firstOrNull;
    if (router == null) {
      throw StateError('Router $routerId not found.');
    }

    final password = await _repo.getPassword(routerId);
    if (password == null) {
      throw StateError('No credentials found for router $routerId.');
    }

    // Fetch users and profiles together; active sessions separately.
    final results = await Future.wait([
      _service.listUsers(router: router, password: password),
      _service.listProfiles(router: router, password: password),
      _service.listActiveSessions(router: router, password: password),
    ]);

    return HotspotData(
      routerId: routerId,
      users: results[0] as List<HotspotUser>,
      profiles: results[1] as List<HotspotProfile>,
      activeSessions: results[2] as List<HotspotActive>,
      fetchedAt: DateTime.now(),
    );
  }
}

// ---------------------------------------------------------------------------
// Active router hotspot
// ---------------------------------------------------------------------------

/// Hotspot data for the currently active router.
final activeHotspotProvider =
    AsyncNotifierProvider<ActiveHotspotNotifier, HotspotData?>(
      ActiveHotspotNotifier.new,
    );

class ActiveHotspotNotifier extends AsyncNotifier<HotspotData?> {
  @override
  Future<HotspotData?> build() async {
    final active = ref.watch(activeRouterProvider);
    if (active == null) return null;
    return ref.watch(hotspotProvider(active.id).future);
  }

  /// Refresh the active router's hotspot data.
  Future<void> refresh() async {
    final active = ref.read(activeRouterProvider);
    if (active == null) return;
    await ref.read(hotspotProvider(active.id).notifier).refresh();
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Search / filter state
// ---------------------------------------------------------------------------

/// Search query string for the hotspot user list.
final hotspotSearchProvider =
    NotifierProvider<HotspotSearchNotifier, String>(
      HotspotSearchNotifier.new,
    );

class HotspotSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clearQuery() {
    state = '';
  }
}

/// Current hotspot user filter mode.
final hotspotFilterProvider =
    NotifierProvider<HotspotFilterNotifier, HotspotUserFilter>(
      HotspotFilterNotifier.new,
    );

class HotspotFilterNotifier extends Notifier<HotspotUserFilter> {
  @override
  HotspotUserFilter build() => HotspotUserFilter.all;

  void setFilter(HotspotUserFilter filter) {
    state = filter;
  }

  void reset() {
    state = HotspotUserFilter.all;
  }
}

/// Selected profile filter value (used when filter = byProfile).
final hotspotProfileFilterProvider =
    NotifierProvider<HotspotProfileFilterNotifier, String?>(
      HotspotProfileFilterNotifier.new,
    );

class HotspotProfileFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setProfile(String profile) {
    state = profile;
  }

  void clear() {
    state = null;
  }
}

/// Selected comment filter value (used when filter = byComment).
final hotspotCommentFilterProvider =
    NotifierProvider<HotspotCommentFilterNotifier, String?>(
      HotspotCommentFilterNotifier.new,
    );

class HotspotCommentFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setComment(String comment) {
    state = comment;
  }

  void clear() {
    state = null;
  }
}

// ---------------------------------------------------------------------------
// Derived: filtered + searched user list
// ---------------------------------------------------------------------------

/// Filtered and searched list of hotspot users for the active router.
///
/// Applies:
/// 1. [hotspotFilterProvider] — server-side-equivalent filtering (client-side
///    applied to already-fetched list).
/// 2. [hotspotSearchProvider] — client-side text search on name + comment.
final filteredHotspotUsersProvider = Provider<List<HotspotUser>>((ref) {
  final hotspotAsync = ref.watch(activeHotspotProvider);
  final filter = ref.watch(hotspotFilterProvider);
  final profileFilter = ref.watch(hotspotProfileFilterProvider);
  final commentFilter = ref.watch(hotspotCommentFilterProvider);
  final search = ref.watch(hotspotSearchProvider);

  final data = hotspotAsync.valueOrNull;
  if (data == null) return [];

  var users = data.users;

  // Apply filter.
  switch (filter) {
    case HotspotUserFilter.byProfile:
      if (profileFilter != null && profileFilter.isNotEmpty) {
        users = users.where((u) => u.profile == profileFilter).toList();
      }
    case HotspotUserFilter.byComment:
      if (commentFilter != null && commentFilter.isNotEmpty) {
        users = users
            .where(
              (u) =>
                  u.comment != null &&
                  u.comment!.contains(commentFilter),
            )
            .toList();
      }
    case HotspotUserFilter.expired:
      users = users.where((u) => u.isExpired).toList();
    case HotspotUserFilter.all:
      break;
  }

  // Apply search.
  final q = search.trim().toLowerCase();
  if (q.isNotEmpty) {
    users = users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              (u.comment?.toLowerCase().contains(q) ?? false) ||
              u.profile.toLowerCase().contains(q),
        )
        .toList();
  }

  return users;
});

// ---------------------------------------------------------------------------
// Per-router user management actions
// ---------------------------------------------------------------------------

/// Notifier that performs write operations on hotspot users for the
/// currently active router. Refreshes [hotspotProvider] after each action.
final hotspotActionsProvider =
    AsyncNotifierProvider<HotspotActionsNotifier, void>(
      HotspotActionsNotifier.new,
    );

class HotspotActionsNotifier extends AsyncNotifier<void> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  HotspotService get _service => ref.read(hotspotServiceProvider);

  @override
  Future<void> build() async {}

  RouterModel _requireActiveRouter() {
    final active = ref.read(activeRouterProvider);
    if (active == null) {
      throw StateError('No active router selected.');
    }
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
    ref.read(hotspotProvider(routerId).notifier).refresh();
  }

  /// Add a new hotspot user.
  Future<void> addUser(HotspotUserCreate params) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.addUser(
        router: router,
        password: password,
        params: params,
      );
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Update an existing hotspot user.
  Future<void> updateUser(String userId, HotspotUserUpdate update) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.updateUser(
        router: router,
        password: password,
        userId: userId,
        update: update,
      );
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Delete a single user. Requires prior confirmation.
  Future<void> deleteUser(String userId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.removeUser(
        router: router,
        password: password,
        userId: userId,
      );
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Bulk delete users by comment prefix. Requires prior confirmation.
  Future<int> bulkDeleteByComment(String comment) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      final removed = await _service.removeUsersByComment(
        router: router,
        password: password,
        comment: comment,
      );
      _refresh(router.id);
      state = const AsyncData(null);
      return removed;
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Bulk delete expired users. Requires prior confirmation.
  Future<int> bulkDeleteExpired() async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      final removed = await _service.removeExpiredUsers(
        router: router,
        password: password,
      );
      _refresh(router.id);
      state = const AsyncData(null);
      return removed;
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Enable a user.
  Future<void> enableUser(String userId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.enableUser(
        router: router,
        password: password,
        userId: userId,
      );
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Disable a user.
  Future<void> disableUser(String userId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.disableUser(
        router: router,
        password: password,
        userId: userId,
      );
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Reset counters for a user.
  Future<void> resetCounters(String userId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.resetCounters(
        router: router,
        password: password,
        userId: userId,
      );
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Disconnect an active session.
  Future<void> disconnectSession(String sessionId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.disconnectSession(
        router: router,
        password: password,
        sessionId: sessionId,
      );
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Remove a cookie.
  Future<void> removeCookie(String cookieId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.removeCookie(
        router: router,
        password: password,
        cookieId: cookieId,
      );
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Remove a host.
  Future<void> removeHost(String hostId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.removeHost(
        router: router,
        password: password,
        hostId: hostId,
      );
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

// ---------------------------------------------------------------------------
// Cookie and host list providers (per active router)
// ---------------------------------------------------------------------------

/// Cookie list for the active router.
final hotspotCookieProvider =
    AsyncNotifierProvider<HotspotCookieNotifier, List<HotspotCookie>>(
      HotspotCookieNotifier.new,
    );

class HotspotCookieNotifier extends AsyncNotifier<List<HotspotCookie>> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  HotspotService get _service => ref.read(hotspotServiceProvider);

  @override
  Future<List<HotspotCookie>> build() async {
    final active = ref.watch(activeRouterProvider);
    if (active == null) return [];
    return _fetch(active);
  }

  Future<List<HotspotCookie>> _fetch(RouterModel router) async {
    final password = await _repo.getPassword(router.id);
    if (password == null) return [];
    return _service.listCookies(router: router, password: password);
  }

  Future<void> refresh() async {
    final active = ref.read(activeRouterProvider);
    if (active == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(active));
  }
}

/// Host list for the active router.
final hotspotHostProvider =
    AsyncNotifierProvider<HotspotHostNotifier, List<HotspotHost>>(
      HotspotHostNotifier.new,
    );

class HotspotHostNotifier extends AsyncNotifier<List<HotspotHost>> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  HotspotService get _service => ref.read(hotspotServiceProvider);

  @override
  Future<List<HotspotHost>> build() async {
    final active = ref.watch(activeRouterProvider);
    if (active == null) return [];
    return _fetch(active, HostFilter.all);
  }

  Future<List<HotspotHost>> _fetch(RouterModel router, HostFilter filter) async {
    final password = await _repo.getPassword(router.id);
    if (password == null) return [];
    return _service.listHosts(router: router, password: password, filter: filter);
  }

  Future<void> refresh({HostFilter filter = HostFilter.all}) async {
    final active = ref.read(activeRouterProvider);
    if (active == null) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(active, filter));
  }
}
