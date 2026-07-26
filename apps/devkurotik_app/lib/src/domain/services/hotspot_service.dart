/// Phase 4 — HotspotService.
///
/// Thin service layer over [MikrotikClient] for hotspot operations.
/// All calls are direct RouterOS API commands.
/// Credentials are NEVER stored in this class.
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../models/hotspot_models.dart';
import '../models/router_model.dart';

/// Thrown when a hotspot operation fails due to a RouterOS-level error.
class HotspotException implements Exception {
  const HotspotException(this.message, {this.operation});

  final String message;
  final String? operation;

  @override
  String toString() =>
      'HotspotException[$operation]: $message';
}

/// Service for all `/ip/hotspot/*` RouterOS operations.
///
/// Each method creates a short-lived [MikrotikClient], performs one
/// operation, and disconnects. The connection timeout is configurable.
class HotspotService {
  const HotspotService({
    this.timeout = const Duration(seconds: 10),
  });

  final Duration timeout;

  // ---------------------------------------------------------------------------
  // Users — read
  // ---------------------------------------------------------------------------

  /// List all hotspot users for a router.
  ///
  /// Optionally filter by [profile], [comment] prefix, or [expiredOnly].
  Future<List<HotspotUser>> listUsers({
    required RouterModel router,
    required String password,
    String? profile,
    String? comment,
    bool expiredOnly = false,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      final query = <String, String>{};
      if (profile != null && profile.isNotEmpty) {
        query['profile'] = profile;
      }
      if (comment != null && comment.isNotEmpty) {
        query['comment'] = comment;
      }
      if (expiredOnly) {
        query['limit-uptime'] = '1s';
      }
      final rows = await client.command(
        '/ip/hotspot/user/print',
        query: query,
      );
      return rows.map(HotspotUser.fromApiMap).toList();
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'listUsers',
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Get a single user by name.
  Future<HotspotUser?> getUserByName({
    required RouterModel router,
    required String password,
    required String name,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      final rows = await client.command(
        '/ip/hotspot/user/print',
        query: {'name': name},
      );
      if (rows.isEmpty) return null;
      return HotspotUser.fromApiMap(rows.first);
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'getUserByName',
      );
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Users — write
  // ---------------------------------------------------------------------------

  /// Add a new hotspot user.
  Future<void> addUser({
    required RouterModel router,
    required String password,
    required HotspotUserCreate params,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      await client.command(
        '/ip/hotspot/user/add',
        params: params.toApiParams(),
      );
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'addUser',
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Update an existing hotspot user by ID.
  Future<void> updateUser({
    required RouterModel router,
    required String password,
    required String userId,
    required HotspotUserUpdate update,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      final params = {'.id': userId, ...update.toApiParams()};
      await client.command('/ip/hotspot/user/set', params: params);
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'updateUser',
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Delete a single hotspot user by ID.
  Future<void> removeUser({
    required RouterModel router,
    required String password,
    required String userId,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      await client.command(
        '/ip/hotspot/user/remove',
        params: {'.id': userId},
      );
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'removeUser',
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Delete all users with a specific comment prefix.
  Future<int> removeUsersByComment({
    required RouterModel router,
    required String password,
    required String comment,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      // First list matching users.
      final rows = await client.command(
        '/ip/hotspot/user/print',
        query: {'comment': comment},
      );
      if (rows.isEmpty) return 0;
      // Remove each by .id individually.
      var removed = 0;
      for (final row in rows) {
        final id = row['.id'];
        if (id != null && id.isNotEmpty) {
          await client.command(
            '/ip/hotspot/user/remove',
            params: {'.id': id},
          );
          removed++;
        }
      }
      return removed;
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'removeUsersByComment',
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Delete all expired users (limit-uptime = 1s).
  Future<int> removeExpiredUsers({
    required RouterModel router,
    required String password,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      final rows = await client.command(
        '/ip/hotspot/user/print',
        query: {'limit-uptime': '1s'},
      );
      if (rows.isEmpty) return 0;
      var removed = 0;
      for (final row in rows) {
        final id = row['.id'];
        if (id != null && id.isNotEmpty) {
          await client.command(
            '/ip/hotspot/user/remove',
            params: {'.id': id},
          );
          removed++;
        }
      }
      return removed;
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'removeExpiredUsers',
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Enable a hotspot user.
  Future<void> enableUser({
    required RouterModel router,
    required String password,
    required String userId,
  }) async {
    await _setDisabled(router, password, userId, disabled: false);
  }

  /// Disable a hotspot user.
  Future<void> disableUser({
    required RouterModel router,
    required String password,
    required String userId,
  }) async {
    await _setDisabled(router, password, userId, disabled: true);
  }

  Future<void> _setDisabled(
    RouterModel router,
    String password,
    String userId, {
    required bool disabled,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      await client.command(
        '/ip/hotspot/user/set',
        params: {'.id': userId, 'disabled': disabled ? 'yes' : 'no'},
      );
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: disabled ? 'disableUser' : 'enableUser',
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Reset counters for a hotspot user.
  Future<void> resetCounters({
    required RouterModel router,
    required String password,
    required String userId,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      await client.command(
        '/ip/hotspot/user/reset-counters',
        params: {'.id': userId},
      );
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'resetCounters',
      );
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Profiles
  // ---------------------------------------------------------------------------

  /// List all hotspot user profiles.
  Future<List<HotspotProfile>> listProfiles({
    required RouterModel router,
    required String password,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      final rows = await client.command('/ip/hotspot/user/profile/print');
      return rows.map(HotspotProfile.fromApiMap).toList();
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'listProfiles',
      );
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Active sessions
  // ---------------------------------------------------------------------------

  /// List active hotspot sessions.
  Future<List<HotspotActive>> listActiveSessions({
    required RouterModel router,
    required String password,
    String? server,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      final query = <String, String>{};
      if (server != null && server.isNotEmpty) {
        query['server'] = server;
      }
      final rows = await client.command(
        '/ip/hotspot/active/print',
        query: query,
      );
      return rows.map(HotspotActive.fromApiMap).toList();
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'listActiveSessions',
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Disconnect a single active session.
  Future<void> disconnectSession({
    required RouterModel router,
    required String password,
    required String sessionId,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      await client.command(
        '/ip/hotspot/active/remove',
        params: {'.id': sessionId},
      );
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'disconnectSession',
      );
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Cookies
  // ---------------------------------------------------------------------------

  /// List hotspot cookies.
  Future<List<HotspotCookie>> listCookies({
    required RouterModel router,
    required String password,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      final rows = await client.command('/ip/hotspot/cookie/print');
      return rows.map(HotspotCookie.fromApiMap).toList();
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'listCookies',
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Remove a hotspot cookie by ID.
  Future<void> removeCookie({
    required RouterModel router,
    required String password,
    required String cookieId,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      await client.command(
        '/ip/hotspot/cookie/remove',
        params: {'.id': cookieId},
      );
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'removeCookie',
      );
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Hosts
  // ---------------------------------------------------------------------------

  /// List hotspot hosts.
  Future<List<HotspotHost>> listHosts({
    required RouterModel router,
    required String password,
    HostFilter filter = HostFilter.all,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      final query = <String, String>{};
      if (filter == HostFilter.authorized) {
        query['authorized'] = 'true';
      } else if (filter == HostFilter.bypassed) {
        query['bypassed'] = 'true';
      }
      final rows = await client.command(
        '/ip/hotspot/host/print',
        query: query,
      );
      return rows.map(HotspotHost.fromApiMap).toList();
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'listHosts',
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Remove a hotspot host by ID.
  Future<void> removeHost({
    required RouterModel router,
    required String password,
    required String hostId,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      await client.command(
        '/ip/hotspot/host/remove',
        params: {'.id': hostId},
      );
    } on RouterosException catch (e) {
      throw HotspotException(
        _sanitize(e.toString()),
        operation: 'removeHost',
      );
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Expiry display logic
  // ---------------------------------------------------------------------------

  /// Decode expiry information from a hotspot user's comment field.
  ///
  /// RouterOS/Mikhmon convention:
  ///   - Before first login: `"vc-RANDCODE-DATE-COMMENT"` → batch code
  ///   - After first login:  `"Jan/01/2025 14:30:00 vc-RANDCODE"` → expiry stamp
  ///
  /// Returns null if the comment does not contain expiry information.
  static HotspotExpiry? decodeExpiry(HotspotUser user) {
    final comment = user.comment;
    if (comment == null || comment.isEmpty) return null;

    // Pattern: "MMM/DD/YYYY HH:MM:SS ..."
    // e.g. "Jan/01/2025 14:30:00 vc-abc123"
    final expiryPattern = RegExp(
      r'^(\w{3}/\d{2}/\d{4} \d{2}:\d{2}:\d{2})',
    );
    final match = expiryPattern.firstMatch(comment);
    if (match != null) {
      final dateStr = match.group(1)!;
      final parsed = _parseRouterosDate(dateStr);
      return HotspotExpiry(
        expiryAt: parsed,
        rawStamp: dateStr,
        isExpired: parsed != null && parsed.isBefore(DateTime.now()),
      );
    }

    // No expiry stamp — just a batch code or generic comment.
    return null;
  }

  // ---------------------------------------------------------------------------
  // Audit log
  // ---------------------------------------------------------------------------

  /// Generate a local audit log entry for destructive actions.
  ///
  /// Returns a structured string suitable for persisting to a local log.
  static String auditEntry({
    required String action,
    required String routerId,
    required String subject,
    String? detail,
  }) {
    final now = DateTime.now().toIso8601String();
    return '[$now] $action | router=$routerId | subject=$subject'
        '${detail != null ? ' | $detail' : ''}';
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  MikrotikClient _buildClient(RouterModel router, String password) {
    return MikrotikClient(
      host: router.host,
      username: router.username,
      password: password,
      port: router.port,
      timeout: timeout,
      maxRetries: 0,
    );
  }

  /// Strip credentials from error messages before surfacing to UI.
  static String _sanitize(String message) {
    return message.replaceAllMapped(
      RegExp(r'=password=[^\s,]+'),
      (m) => '=password=***',
    );
  }

  /// Parse RouterOS date format: "Jan/01/2025 14:30:00"
  static DateTime? _parseRouterosDate(String s) {
    try {
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4,
        'May': 5, 'Jun': 6, 'Jul': 7, 'Aug': 8,
        'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      // "Jan/01/2025 14:30:00"
      final parts = s.split(' ');
      if (parts.length < 2) return null;
      final dateParts = parts[0].split('/');
      if (dateParts.length != 3) return null;
      final month = months[dateParts[0]];
      final day = int.tryParse(dateParts[1]);
      final year = int.tryParse(dateParts[2]);
      final timeParts = parts[1].split(':');
      if (timeParts.length != 3) return null;
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      final second = int.tryParse(timeParts[2]);
      if (month == null || day == null || year == null ||
          hour == null || minute == null || second == null) {
        return null;
      }
      return DateTime(year, month, day, hour, minute, second);
    } on Exception {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// HotspotExpiry
// ---------------------------------------------------------------------------

/// Decoded expiry info from a hotspot user's comment field.
class HotspotExpiry {
  const HotspotExpiry({
    this.expiryAt,
    this.rawStamp,
    this.isExpired = false,
  });

  /// Parsed expiry date/time (may be null if parsing failed).
  final DateTime? expiryAt;

  /// Raw date string from comment.
  final String? rawStamp;

  /// Whether the user has already expired.
  final bool isExpired;

  /// Formatted expiry display string.
  String get displayText {
    if (expiryAt == null) return rawStamp ?? 'Unknown';
    return expiryAt!.toLocal().toString().substring(0, 16);
  }
}
