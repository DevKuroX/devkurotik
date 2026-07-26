/// Phase 7 — Queue service.
///
/// Simple queue listing and removal within the audited scope.
///
/// ## Audited Scope
///
/// - `/queue/simple/print` — list all simple queues
/// - `/queue/simple/remove` — remove a simple queue by ID
///
/// Queue Tree is NOT in scope (not in API_ENDPOINTS.md or
/// FEATURE_MATRIX.md for the audited Mikhmon source).
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../models/queue_models.dart';
import '../models/router_model.dart';

/// Service for simple queue operations.
class QueueService {
  const QueueService({this.timeout = const Duration(seconds: 10)});

  final Duration timeout;

  /// List all simple queues from `/queue/simple/print`.
  Future<List<SimpleQueue>> listSimpleQueues(
    RouterModel router,
    String password,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      final result = await client.command('/queue/simple/print');
      return result
          .map((m) => SimpleQueue.fromApiMap(Map<String, String>.from(m)))
          .toList();
    } finally {
      await client.disconnect();
    }
  }

  /// Remove a simple queue by [queueId].
  ///
  /// This is only used in the IP binding cascade deletion flow as per
  /// `pipbinding.php` in the Mikhmon v3 source.
  Future<void> removeSimpleQueue(
    RouterModel router,
    String password,
    String queueId,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      await client.command('/queue/simple/remove', params: {'.id': queueId});
    } finally {
      await client.disconnect();
    }
  }

  // ── Private ───────────────────────────────────────────────────────────────

  MikrotikClient _client(RouterModel router, String password) {
    return MikrotikClient(
      host: router.host,
      username: router.username,
      password: password,
      port: router.port,
      timeout: timeout,
      maxRetries: 1,
    );
  }
}
