/// Phase 5 — Quick Print Service.
///
/// Reads and writes Quick Print package configurations from RouterOS
/// /system/script entries.
///
/// Convention (from Mikhmon / SDK_DESIGN.md):
///   RouterOS script comment = "QuickPrintMikhmon"
///   RouterOS script source  = #-delimited config string
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

import '../models/router_model.dart';
import '../models/voucher_models.dart';

/// Service for Quick Print package management on RouterOS.
class QuickPrintService {
  const QuickPrintService({
    this.timeout = const Duration(seconds: 15),
  });

  final Duration timeout;

  /// Fetch all Quick Print packages from the router.
  ///
  /// Returns parsed [QuickPrintPackage] list.
  /// Entries without the `QuickPrintMikhmon` comment are ignored.
  Future<List<QuickPrintPackage>> listPackages({
    required RouterModel router,
    required String password,
  }) async {
    final client = _buildClient(router, password);
    final packages = <QuickPrintPackage>[];

    try {
      await client.connect();
      final result = await client.command(
        '/system/script/print',
        query: {'comment': QuickPrintPackage.routerOsComment},
      );

      for (final row in result) {
        final id = row['.id'] ?? '';
        final name = row['name'] ?? '';
        final source = row['source'] ?? '';
        if (id.isEmpty || source.isEmpty) continue;
        final pkg = QuickPrintPackage.decodeSource(id, name, source);
        if (pkg != null) packages.add(pkg);
      }
    } finally {
      await client.disconnect();
    }

    return packages;
  }

  /// Write a new Quick Print package to the router.
  ///
  /// Creates a new /system/script entry with the encoded source and
  /// the `QuickPrintMikhmon` comment.
  Future<void> writePackage({
    required RouterModel router,
    required String password,
    required String name,
    required QuickPrintPackage pkg,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      await client.command(
        '/system/script/add',
        params: {
          'name': name,
          'source': pkg.encodeSource(),
          'comment': QuickPrintPackage.routerOsComment,
        },
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Update an existing Quick Print package on the router.
  Future<void> updatePackage({
    required RouterModel router,
    required String password,
    required String scriptId,
    required String name,
    required QuickPrintPackage pkg,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      await client.command(
        '/system/script/set',
        params: {
          '.id': scriptId,
          'name': name,
          'source': pkg.encodeSource(),
          'comment': QuickPrintPackage.routerOsComment,
        },
      );
    } finally {
      await client.disconnect();
    }
  }

  /// Delete a Quick Print package from the router by script id.
  Future<void> deletePackage({
    required RouterModel router,
    required String password,
    required String scriptId,
  }) async {
    final client = _buildClient(router, password);
    try {
      await client.connect();
      await client.command(
        '/system/script/remove',
        params: {'.id': scriptId},
      );
    } finally {
      await client.disconnect();
    }
  }

  MikrotikClient _buildClient(RouterModel router, String password) {
    return MikrotikClient(
      host: router.host,
      username: router.username,
      password: password,
      port: router.port,
      timeout: timeout,
    );
  }
}
