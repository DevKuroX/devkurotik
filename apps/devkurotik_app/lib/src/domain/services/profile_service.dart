/// Phase 6 — ProfileService.
///
/// RouterOS API operations for hotspot user profile management.
/// Uses OnLoginScriptGenerator to produce canonical Mikhmon-compatible scripts.
///
/// Endpoints used:
///   /ip/hotspot/user/profile/print
///   /ip/hotspot/user/profile/add
///   /ip/hotspot/user/profile/set
///   /ip/hotspot/user/profile/remove
///   /system/scheduler/print
///   /system/scheduler/add
///   /system/scheduler/set
///   /system/scheduler/remove
library;

import 'dart:math';

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../models/profile_models.dart';
import '../models/router_model.dart';
import 'on_login_script_generator.dart';

/// Service for managing hotspot user profiles with Mikhmon-compatible scripts.
class ProfileService {
  const ProfileService({this.timeout = const Duration(seconds: 10)});

  final Duration timeout;

  static const _generator = OnLoginScriptGenerator();

  // ---------------------------------------------------------------------------
  // Profile list
  // ---------------------------------------------------------------------------

  /// Lists all hotspot user profiles on the router.
  Future<List<HotspotProfile>> listProfiles(
    RouterModel router,
    String password,
  ) async {
    final client = MikrotikClient(
      host: router.host,
      port: router.port,
      username: router.username,
      password: password,
    );
    try {
      await client.connect().timeout(timeout);
      final raw = await client
          .command('/ip/hotspot/user/profile/print')
          .timeout(timeout);
      return raw.map(HotspotProfile.fromApiMap).toList();
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Add profile
  // ---------------------------------------------------------------------------

  /// Creates a new hotspot user profile with the generated on-login script
  /// and its associated background sweep scheduler.
  Future<void> addProfile(
    RouterModel router,
    String password,
    ProfileScriptParams params, {
    String? addressPool,
    String? rateLimit,
    int sharedUsers = 1,
    String? parentQueue,
  }) async {
    final result = _generator.generate(params);
    final schedParams = _buildSchedulerParams();

    final client = MikrotikClient(
      host: router.host,
      port: router.port,
      username: router.username,
      password: password,
    );
    try {
      await client.connect().timeout(timeout);

      final profileArgs = <String, String>{
        'name': params.profileName,
        'on-login': result.onLogin,
        'shared-users': sharedUsers.toString(),
        'status-autorefresh': '1m',
      };
      if (addressPool != null && addressPool.isNotEmpty && addressPool != 'none') {
        profileArgs['address-pool'] = addressPool;
      }
      if (rateLimit != null && rateLimit.isNotEmpty) {
        profileArgs['rate-limit'] = rateLimit;
      }
      if (parentQueue != null && parentQueue.isNotEmpty && parentQueue != 'none') {
        profileArgs['parent-queue'] = parentQueue;
      }

      await client
          .command('/ip/hotspot/user/profile/add', params: profileArgs)
          .timeout(timeout);

      if (result.requiresScheduler) {
        await client.command('/system/scheduler/add', params: {
          'name': params.profileName,
          'start-time': schedParams.startTime,
          'interval': schedParams.interval,
          'on-event': result.bgService,
          'disabled': 'no',
          'comment': 'Monitor Profile ${params.profileName}',
        }).timeout(timeout);
      }
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Update profile
  // ---------------------------------------------------------------------------

  /// Updates an existing hotspot user profile's on-login script and manages
  /// the associated background sweep scheduler lifecycle.
  Future<void> updateProfile(
    RouterModel router,
    String password,
    String profileId,
    ProfileScriptParams params, {
    String? addressPool,
    String? rateLimit,
    int sharedUsers = 1,
    String? parentQueue,
  }) async {
    final result = _generator.generate(params);
    final schedParams = _buildSchedulerParams();

    final client = MikrotikClient(
      host: router.host,
      port: router.port,
      username: router.username,
      password: password,
    );
    try {
      await client.connect().timeout(timeout);

      final profileArgs = <String, String>{
        '.id': profileId,
        'name': params.profileName,
        'on-login': result.onLogin,
        'shared-users': sharedUsers.toString(),
        'status-autorefresh': '1m',
      };
      if (addressPool != null && addressPool.isNotEmpty && addressPool != 'none') {
        profileArgs['address-pool'] = addressPool;
      }
      if (rateLimit != null && rateLimit.isNotEmpty) {
        profileArgs['rate-limit'] = rateLimit;
      }
      if (parentQueue != null && parentQueue.isNotEmpty && parentQueue != 'none') {
        profileArgs['parent-queue'] = parentQueue;
      }

      await client
          .command('/ip/hotspot/user/profile/set', params: profileArgs)
          .timeout(timeout);

      // Find existing scheduler
      final existingSched = await client.command(
        '/system/scheduler/print',
        query: {'name': params.profileName},
      ).timeout(timeout);
      final schedId = existingSched.isNotEmpty ? existingSched[0]['.id'] : null;

      if (result.requiresScheduler) {
        if (schedId != null) {
          await client.command('/system/scheduler/set', params: {
            '.id': schedId,
            'name': params.profileName,
            'start-time': schedParams.startTime,
            'interval': schedParams.interval,
            'on-event': result.bgService,
            'disabled': 'no',
            'comment': 'Monitor Profile ${params.profileName}',
          }).timeout(timeout);
        } else {
          await client.command('/system/scheduler/add', params: {
            'name': params.profileName,
            'start-time': schedParams.startTime,
            'interval': schedParams.interval,
            'on-event': result.bgService,
            'disabled': 'no',
            'comment': 'Monitor Profile ${params.profileName}',
          }).timeout(timeout);
        }
      } else {
        if (schedId != null) {
          await client.command('/system/scheduler/remove', params: {
            '.id': schedId,
          }).timeout(timeout);
        }
      }
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Delete profile
  // ---------------------------------------------------------------------------

  /// Deletes a hotspot user profile and its associated background scheduler.
  Future<void> deleteProfile(
    RouterModel router,
    String password,
    String profileId,
    String profileName,
  ) async {
    final client = MikrotikClient(
      host: router.host,
      port: router.port,
      username: router.username,
      password: password,
    );
    try {
      await client.connect().timeout(timeout);

      final existingSched = await client.command(
        '/system/scheduler/print',
        query: {'name': profileName},
      ).timeout(timeout);
      if (existingSched.isNotEmpty) {
        final schedId = existingSched[0]['.id'];
        if (schedId != null) {
          await client.command('/system/scheduler/remove', params: {
            '.id': schedId,
          }).timeout(timeout);
        }
      }

      await client.command('/ip/hotspot/user/profile/remove', params: {
        '.id': profileId,
      }).timeout(timeout);
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Scheduler query
  // ---------------------------------------------------------------------------

  /// Fetches the background sweep scheduler for a profile, or null if absent.
  Future<SchedulerEntry?> getProfileScheduler(
    RouterModel router,
    String password,
    String profileName,
  ) async {
    final client = MikrotikClient(
      host: router.host,
      port: router.port,
      username: router.username,
      password: password,
    );
    try {
      await client.connect().timeout(timeout);
      final raw = await client.command(
        '/system/scheduler/print',
        query: {'name': profileName},
      ).timeout(timeout);
      if (raw.isEmpty) return null;
      final m = raw[0];
      return SchedulerEntry(
        id: m['.id'] ?? '',
        name: m['name'] ?? '',
        interval: m['interval'] ?? '',
        disabled: m['disabled'] == 'true',
        comment: m['comment'],
      );
    } finally {
      await client.disconnect();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  _SchedulerRandomParams _buildSchedulerParams() {
    final rng = Random();
    final startTime =
        '0${rng.nextInt(5) + 1}:${rng.nextInt(50) + 10}:${rng.nextInt(50) + 10}';
    final interval = '00:02:${rng.nextInt(50) + 10}';
    return _SchedulerRandomParams(startTime: startTime, interval: interval);
  }
}

/// Result of a scheduler query.
class SchedulerEntry {
  const SchedulerEntry({
    required this.id,
    required this.name,
    required this.interval,
    required this.disabled,
    this.comment,
  });

  final String id;
  final String name;
  final String interval;
  final bool disabled;
  final String? comment;

  bool get isMonitorScheduler =>
      comment?.startsWith('Monitor Profile') ?? false;
}

class _SchedulerRandomParams {
  const _SchedulerRandomParams({
    required this.startTime,
    required this.interval,
  });

  final String startTime;
  final String interval;
}
