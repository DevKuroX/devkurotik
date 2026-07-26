/// Phase 7 — PPP service.
///
/// CRUD for PPP secrets, listing of PPP profiles and active sessions,
/// and disconnection of active PPP sessions.
///
/// ## Source Gap
///
/// Only `/ppp/active/remove` exists in the Mikhmon v3 source
/// (`process/removepactive.php`). Secret and profile endpoints are
/// gap-filled from the RouterOS API specification as documented in
/// PHASE_7.md Task 10 and FEATURE_MATRIX.md Module 12.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../models/ppp_models.dart';
import '../models/router_model.dart';

/// Service for PPP secret, profile, and active session operations.
///
/// All methods create a fresh [MikrotikClient], execute a single
/// logical operation, and disconnect. Credentials are never cached here.
class PppService {
  const PppService({this.timeout = const Duration(seconds: 10)});

  /// Timeout for all RouterOS API calls.
  final Duration timeout;

  // ── Secrets ───────────────────────────────────────────────────────────────

  /// List all PPP secrets from `/ppp/secret/print`.
  Future<List<PppSecret>> listSecrets(
    RouterModel router,
    String password,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      final result = await client.command('/ppp/secret/print');
      return result
          .map((m) => PppSecret.fromApiMap(Map<String, String>.from(m)))
          .toList();
    } finally {
      await client.disconnect();
    }
  }

  /// Add a new PPP secret.
  Future<void> addSecret(
    RouterModel router,
    String password,
    PppSecretCreate params,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      await client.command('/ppp/secret/add', params: params.toApiParams());
    } finally {
      await client.disconnect();
    }
  }

  /// Update an existing PPP secret by [secretId].
  Future<void> updateSecret(
    RouterModel router,
    String password,
    String secretId,
    PppSecretUpdate update,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      final apiParams = {'.id': secretId, ...update.toApiParams()};
      await client.command('/ppp/secret/set', params: apiParams);
    } finally {
      await client.disconnect();
    }
  }

  /// Delete a PPP secret by [secretId].
  Future<void> deleteSecret(
    RouterModel router,
    String password,
    String secretId,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      await client.command('/ppp/secret/remove', params: {'.id': secretId});
    } finally {
      await client.disconnect();
    }
  }

  /// Enable a PPP secret.
  Future<void> enableSecret(
    RouterModel router,
    String password,
    String secretId,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      await client.command('/ppp/secret/set',
          params: {'.id': secretId, 'disabled': 'no'});
    } finally {
      await client.disconnect();
    }
  }

  /// Disable a PPP secret.
  Future<void> disableSecret(
    RouterModel router,
    String password,
    String secretId,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      await client.command('/ppp/secret/set',
          params: {'.id': secretId, 'disabled': 'yes'});
    } finally {
      await client.disconnect();
    }
  }

  // ── Profiles ─────────────────────────────────────────────────────────────

  /// List all PPP profiles from `/ppp/profile/print`.
  Future<List<PppProfile>> listProfiles(
    RouterModel router,
    String password,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      final result = await client.command('/ppp/profile/print');
      return result
          .map((m) => PppProfile.fromApiMap(Map<String, String>.from(m)))
          .toList();
    } finally {
      await client.disconnect();
    }
  }

  // ── Active Sessions ──────────────────────────────────────────────────────

  /// List all active PPP sessions from `/ppp/active/print`.
  Future<List<PppActive>> listActiveSessions(
    RouterModel router,
    String password,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      final result = await client.command('/ppp/active/print');
      return result
          .map((m) => PppActive.fromApiMap(Map<String, String>.from(m)))
          .toList();
    } finally {
      await client.disconnect();
    }
  }

  /// Disconnect an active PPP session by [sessionId].
  ///
  /// This is the only PPP operation present in the Mikhmon v3 source
  /// (`process/removepactive.php`).
  Future<void> disconnectSession(
    RouterModel router,
    String password,
    String sessionId,
  ) async {
    final client = _client(router, password);
    await client.connect();
    try {
      await client.command('/ppp/active/remove', params: {'.id': sessionId});
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
