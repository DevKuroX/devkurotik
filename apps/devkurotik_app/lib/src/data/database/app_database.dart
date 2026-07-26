/// Drift AppDatabase — Phase 5 adds VoucherBatchTable.
///
/// Generated code lives in app_database.g.dart (via build_runner).
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'router_table.dart';
import 'voucher_batch_table.dart';

part 'app_database.g.dart';

/// The main Drift database for DevKuroTik.
///
/// Schema version 2 — Added VoucherBatchTable for Phase 5 Voucher Engine.
@DriftDatabase(tables: [RouterTable, VoucherBatchTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(voucherBatchTable);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'devkurotik.db'));
    return NativeDatabase.createInBackground(file);
  });
}
