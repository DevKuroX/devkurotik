/// Phase 5 — Voucher Generator Service.
///
/// Generates batches of hotspot voucher credentials and pushes them
/// to the router via MikrotikClient.
///
/// Uses RouterosRandom for generation — all generation is local.
library;

import 'dart:math' as math;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../models/router_model.dart';
import '../models/voucher_models.dart';
import '../models/hotspot_models.dart';

/// Service responsible for generating voucher credentials and pushing
/// them to the router.
class VoucherGeneratorService {
  const VoucherGeneratorService({
    this.timeout = const Duration(seconds: 30),
  });

  final Duration timeout;

  // ---------------------------------------------------------------------------
  // Generation (local — no network)
  // ---------------------------------------------------------------------------

  /// Generate a list of [VoucherItem]s from [params].
  ///
  /// This is a pure local operation — no network required.
  /// Duplicate detection: each username is checked against prior ones in this
  /// batch. On collision a new random string is drawn (max 10 retries).
  List<VoucherItem> generate(
    VoucherGenerationParams params, {
    math.Random? rng,
  }) {
    final charSet = params.charSet.characters;
    final usedNames = <String>{};
    final items = <VoucherItem>[];

    for (var i = 0; i < params.quantity; i++) {
      // Generate unique name.
      String name;
      var attempts = 0;
      do {
        final rand = _generateString(
          charSet,
          params.usernameLength - params.prefix.length,
          rng: rng,
        );
        name = '${params.prefix}$rand';
        attempts++;
      } while (usedNames.contains(name) && attempts < 10);

      usedNames.add(name);

      // Generate password.
      final String password;
      if (params.mode == VoucherMode.voucher) {
        // user = pass
        password = name;
      } else {
        // user + pass (separate)
        password = _generateString(charSet, params.passwordLength, rng: rng);
      }

      items.add(VoucherItem(name: name, password: password));
    }

    return items;
  }

  // ---------------------------------------------------------------------------
  // Router push (network)
  // ---------------------------------------------------------------------------

  /// Push all vouchers in [vouchers] to the router as hotspot users.
  ///
  /// Returns the number of successfully created users.
  /// On partial failure, already-created users remain on the router.
  /// The caller should handle partial failures by persisting the batch
  /// before calling this method.
  Future<int> pushToRouter({
    required RouterModel router,
    required String password,
    required List<VoucherItem> vouchers,
    required VoucherGenerationParams params,
  }) async {
    final client = MikrotikClient(
      host: router.host,
      username: router.username,
      password: password,
      port: router.port,
      timeout: timeout,
    );

    int created = 0;
    try {
      await client.connect();

      for (final v in vouchers) {
        final userParams = HotspotUserCreate(
          name: v.name,
          password: v.password,
          profile: params.profileName,
          server: params.server,
          limitUptime: params.limitUptime,
          comment: params.comment ?? params.server,
        );
        await client.command(
          '/ip/hotspot/user/add',
          params: userParams.toApiParams(),
        );
        created++;
      }
    } finally {
      await client.disconnect();
    }

    return created;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _generateString(String chars, int length, {math.Random? rng}) {
    if (length <= 0) return '';
    final r = rng ?? math.Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }
}
