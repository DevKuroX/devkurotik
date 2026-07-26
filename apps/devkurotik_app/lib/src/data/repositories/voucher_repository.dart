/// Phase 5 — Voucher Repository.
///
/// Persistence boundary for VoucherBatch records in SQLite via Drift.
/// Voucher passwords stored here are the PRODUCT being generated,
/// not router admin passwords.
library;

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../domain/models/voucher_models.dart';

/// Repository for all voucher batch persistence operations.
// ignore_for_file: prefer_initializing_formals
class VoucherRepository {
  VoucherRepository({required AppDatabase db}) : _db = db;

  final AppDatabase _db;

  // ---------------------------------------------------------------------------
  // Write
  // ---------------------------------------------------------------------------

  /// Persist a new or replace an existing voucher batch.
  Future<void> saveBatch(VoucherBatch batch) async {
    await _db
        .into(_db.voucherBatchTable)
        .insertOnConflictUpdate(_toCompanion(batch));
  }

  /// Delete a batch by id.
  Future<void> deleteBatch(String id) async {
    await (_db.delete(_db.voucherBatchTable)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Delete all batches for a given router.
  Future<void> deleteAllForRouter(String routerId) async {
    await (_db.delete(_db.voucherBatchTable)
          ..where((t) => t.routerId.equals(routerId)))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Read
  // ---------------------------------------------------------------------------

  /// List all batches for a router, ordered by most recent first.
  Future<List<VoucherBatch>> listBatches(String routerId) async {
    final rows = await (_db.select(_db.voucherBatchTable)
          ..where((t) => t.routerId.equals(routerId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.generatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
    return rows.map(_fromRow).toList();
  }

  /// Get a single batch by id. Returns null if not found.
  Future<VoucherBatch?> getBatch(String id) async {
    final row = await (_db.select(_db.voucherBatchTable)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Get the most recently generated batch for a router.
  Future<VoucherBatch?> getLastBatch(String routerId) async {
    final rows = await (_db.select(_db.voucherBatchTable)
          ..where((t) => t.routerId.equals(routerId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.generatedAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(1))
        .get();
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  VoucherBatchTableCompanion _toCompanion(VoucherBatch b) {
    return VoucherBatchTableCompanion(
      id: Value(b.id),
      routerId: Value(b.routerId),
      batchCode: Value(b.batchCode),
      profileName: Value(b.profileName),
      quantity: Value(b.quantity),
      mode: Value(b.mode.name),
      charSet: Value(b.charSet.name),
      prefix: Value(b.prefix),
      usernameLength: Value(b.usernameLength),
      passwordLength: Value(b.passwordLength),
      limitUptime: Value(b.limitUptime),
      comment: Value(b.comment),
      generatedAt: Value(b.generatedAt.millisecondsSinceEpoch),
      voucherListJson: Value(b.voucherListJson),
    );
  }

  VoucherBatch _fromRow(VoucherBatchTableData row) {
    return VoucherBatch(
      id: row.id,
      routerId: row.routerId,
      batchCode: row.batchCode,
      profileName: row.profileName,
      quantity: row.quantity,
      mode: VoucherMode.values.firstWhere(
        (m) => m.name == row.mode,
        orElse: () => VoucherMode.voucher,
      ),
      charSet: VoucherCharSet.values.firstWhere(
        (c) => c.name == row.charSet,
        orElse: () => VoucherCharSet.digitMixed,
      ),
      prefix: row.prefix,
      usernameLength: row.usernameLength,
      passwordLength: row.passwordLength,
      limitUptime: row.limitUptime,
      comment: row.comment,
      generatedAt: DateTime.fromMillisecondsSinceEpoch(row.generatedAt),
      vouchers: VoucherBatch.parseVoucherList(row.voucherListJson),
    );
  }
}
