/// Phase 7 — Queue Riverpod providers.
///
/// Provider dependency graph:
///   routerRepositoryProvider (Phase 2)
///   activeRouterProvider     (Phase 2)
///   queueServiceProvider     (Phase 7 — new)
///   simpleQueueProvider      (Phase 7 — new, per-router family)
///   activeSimpleQueueProvider (Phase 7 — new, active router)
///   queueActionsProvider     (Phase 7 — new, remove action)
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/router_repository.dart';
import '../domain/models/queue_models.dart';
import '../domain/models/router_model.dart';
import '../domain/services/queue_service.dart';
import 'router_providers.dart';

// ---------------------------------------------------------------------------
// Infrastructure
// ---------------------------------------------------------------------------

/// Singleton [QueueService].
final queueServiceProvider = Provider<QueueService>((ref) {
  return const QueueService(timeout: Duration(seconds: 10));
});

// ---------------------------------------------------------------------------
// Per-router queue state
// ---------------------------------------------------------------------------

/// Family provider: simple queue list for a specific router ID.
///
/// arg = router ID (String).
final simpleQueueProvider =
    AsyncNotifierProviderFamily<SimpleQueueNotifier, List<SimpleQueue>, String>(
      SimpleQueueNotifier.new,
    );

/// Notifier for a single router's simple queue list.
class SimpleQueueNotifier
    extends FamilyAsyncNotifier<List<SimpleQueue>, String> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  QueueService get _service => ref.read(queueServiceProvider);

  @override
  Future<List<SimpleQueue>> build(String arg) async {
    return _fetchData(arg);
  }

  /// Force a manual refresh.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchData(arg));
  }

  Future<List<SimpleQueue>> _fetchData(String routerId) async {
    final routers = await ref.read(routerListProvider.future);
    final router = routers.where((r) => r.id == routerId).firstOrNull;
    if (router == null) throw StateError('Router $routerId not found.');

    final password = await _repo.getPassword(routerId);
    if (password == null) {
      throw StateError('No credentials found for router $routerId.');
    }

    return _service.listSimpleQueues(router, password);
  }
}

// ---------------------------------------------------------------------------
// Active router queue
// ---------------------------------------------------------------------------

/// Simple queue list for the currently active router.
final activeSimpleQueueProvider =
    AsyncNotifierProvider<ActiveSimpleQueueNotifier, List<SimpleQueue>>(
      ActiveSimpleQueueNotifier.new,
    );

class ActiveSimpleQueueNotifier
    extends AsyncNotifier<List<SimpleQueue>> {
  @override
  Future<List<SimpleQueue>> build() async {
    final active = ref.watch(activeRouterProvider);
    if (active == null) return [];
    return ref.watch(simpleQueueProvider(active.id).future);
  }

  Future<void> refresh() async {
    final active = ref.read(activeRouterProvider);
    if (active == null) return;
    await ref.read(simpleQueueProvider(active.id).notifier).refresh();
    ref.invalidateSelf();
  }
}

// ---------------------------------------------------------------------------
// Search / filter state
// ---------------------------------------------------------------------------

/// Search query for the queue list.
final queueSearchProvider = NotifierProvider<QueueSearchNotifier, String>(
  QueueSearchNotifier.new,
);

class QueueSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }

  void clearQuery() {
    state = '';
  }
}

/// Current queue filter.
final queueFilterProvider =
    NotifierProvider<QueueFilterNotifier, SimpleQueueFilter>(
      QueueFilterNotifier.new,
    );

class QueueFilterNotifier extends Notifier<SimpleQueueFilter> {
  @override
  SimpleQueueFilter build() => SimpleQueueFilter.all;

  void setFilter(SimpleQueueFilter f) {
    state = f;
  }

  void reset() {
    state = SimpleQueueFilter.all;
  }
}

// ---------------------------------------------------------------------------
// Derived: filtered + searched queue list
// ---------------------------------------------------------------------------

/// Filtered and searched simple queue list for the active router.
final filteredSimpleQueuesProvider = Provider<List<SimpleQueue>>((ref) {
  final qAsync = ref.watch(activeSimpleQueueProvider);
  final filter = ref.watch(queueFilterProvider);
  final search = ref.watch(queueSearchProvider);

  var queues = qAsync.valueOrNull ?? [];

  // Apply filter.
  switch (filter) {
    case SimpleQueueFilter.enabled:
      queues = queues.where((q) => !q.disabled).toList();
    case SimpleQueueFilter.disabled:
      queues = queues.where((q) => q.disabled).toList();
    case SimpleQueueFilter.all:
      break;
  }

  // Apply search.
  final q = search.trim().toLowerCase();
  if (q.isNotEmpty) {
    queues = queues
        .where(
          (queue) =>
              queue.name.toLowerCase().contains(q) ||
              (queue.target?.toLowerCase().contains(q) ?? false) ||
              (queue.comment?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  return queues;
});

// ---------------------------------------------------------------------------
// Write actions (remove only — per audited scope)
// ---------------------------------------------------------------------------

/// Notifier that performs write operations on simple queues for the
/// currently active router.
final queueActionsProvider =
    AsyncNotifierProvider<QueueActionsNotifier, void>(
      QueueActionsNotifier.new,
    );

class QueueActionsNotifier extends AsyncNotifier<void> {
  RouterRepository get _repo => ref.read(routerRepositoryProvider);
  QueueService get _service => ref.read(queueServiceProvider);

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
    ref.read(simpleQueueProvider(routerId).notifier).refresh();
  }

  /// Remove a simple queue. Requires prior confirmation.
  Future<void> removeQueue(String queueId) async {
    final router = _requireActiveRouter();
    final password = await _requirePassword(router.id);
    state = const AsyncLoading();
    try {
      await _service.removeSimpleQueue(router, password, queueId);
      _refresh(router.id);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
