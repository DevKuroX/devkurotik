// ignore_for_file: prefer_const_constructors
library;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:devkurotik_app/src/data/database/app_database.dart';
import 'package:devkurotik_app/src/data/repositories/voucher_repository.dart';
import 'package:devkurotik_app/src/domain/models/voucher_models.dart';
import 'package:devkurotik_app/src/providers/voucher_providers.dart';

// ---------------------------------------------------------------------------
// In-memory test database
// ---------------------------------------------------------------------------

AppDatabase _testDb() {
  return AppDatabase(NativeDatabase.memory());
}

VoucherBatch _makeBatch({
  String id = 'batch-1',
  String routerId = 'router-1',
  String batchCode = 'vc-A1B2-20260726',
  int quantity = 10,
  VoucherMode mode = VoucherMode.voucher,
  DateTime? generatedAt,
}) {
  return VoucherBatch(
    id: id,
    routerId: routerId,
    batchCode: batchCode,
    profileName: 'default',
    quantity: quantity,
    mode: mode,
    charSet: VoucherCharSet.digitMixed,
    prefix: '',
    usernameLength: 8,
    passwordLength: 8,
    generatedAt: generatedAt ?? DateTime(2026, 7, 26),
    vouchers: [
      const VoucherItem(name: 'user1', password: 'user1'),
      const VoucherItem(name: 'user2', password: 'user2'),
    ],
  );
}

void main() {
  late AppDatabase db;
  late VoucherRepository repo;

  setUp(() {
    db = _testDb();
    repo = VoucherRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  // ---------------------------------------------------------------------------
  // VoucherRepository CRUD
  // ---------------------------------------------------------------------------

  group('VoucherRepository', () {
    test('saveBatch and getBatch round-trip', () async {
      final batch = _makeBatch();
      await repo.saveBatch(batch);
      final retrieved = await repo.getBatch('batch-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('batch-1'));
      expect(retrieved.profileName, equals('default'));
      expect(retrieved.vouchers.length, equals(2));
    });

    test('listBatches returns all for routerId', () async {
      await repo.saveBatch(_makeBatch(id: 'b1', routerId: 'r1'));
      await repo.saveBatch(_makeBatch(id: 'b2', routerId: 'r1'));
      await repo.saveBatch(_makeBatch(id: 'b3', routerId: 'r2'));

      final r1Batches = await repo.listBatches('r1');
      expect(r1Batches.length, equals(2));

      final r2Batches = await repo.listBatches('r2');
      expect(r2Batches.length, equals(1));
    });

    test('listBatches ordered by most recent first', () async {
      final older = _makeBatch(
        id: 'b1',
        routerId: 'r1',
        generatedAt: DateTime(2026, 7, 1),
      );
      final newer = _makeBatch(
        id: 'b2',
        routerId: 'r1',
        generatedAt: DateTime(2026, 7, 26),
      );
      await repo.saveBatch(older);
      await repo.saveBatch(newer);

      final batches = await repo.listBatches('r1');
      expect(batches.first.id, equals('b2'));
      expect(batches.last.id, equals('b1'));
    });

    test('deleteBatch removes the batch', () async {
      final batch = _makeBatch();
      await repo.saveBatch(batch);
      await repo.deleteBatch('batch-1');
      final retrieved = await repo.getBatch('batch-1');
      expect(retrieved, isNull);
    });

    test('getLastBatch returns most recent', () async {
      final older = _makeBatch(
        id: 'b1',
        routerId: 'r1',
        generatedAt: DateTime(2026, 7, 1),
      );
      final newer = _makeBatch(
        id: 'b2',
        routerId: 'r1',
        generatedAt: DateTime(2026, 7, 26),
      );
      await repo.saveBatch(older);
      await repo.saveBatch(newer);

      final last = await repo.getLastBatch('r1');
      expect(last?.id, equals('b2'));
    });

    test('getLastBatch returns null when no batches', () async {
      final last = await repo.getLastBatch('empty-router');
      expect(last, isNull);
    });

    test('getBatch returns null when not found', () async {
      expect(await repo.getBatch('nonexistent'), isNull);
    });

    test('saveBatch updates on conflict (same id)', () async {
      final batch = _makeBatch();
      await repo.saveBatch(batch);
      final updated = batch.copyWith(profileName: 'updated');
      await repo.saveBatch(updated);
      final retrieved = await repo.getBatch('batch-1');
      expect(retrieved?.profileName, equals('updated'));
    });

    test('voucher list round-trips (JSON)', () async {
      final batch = _makeBatch();
      await repo.saveBatch(batch);
      final retrieved = await repo.getBatch('batch-1');
      expect(retrieved!.vouchers[0].name, equals('user1'));
      expect(retrieved.vouchers[1].password, equals('user2'));
    });

    test('mode round-trips', () async {
      final upBatch = _makeBatch(mode: VoucherMode.userpass);
      await repo.saveBatch(upBatch);
      final retrieved = await repo.getBatch('batch-1');
      expect(retrieved?.mode, equals(VoucherMode.userpass));
    });

    test('deleteAllForRouter removes all batches for that router', () async {
      await repo.saveBatch(_makeBatch(id: 'b1', routerId: 'r1'));
      await repo.saveBatch(_makeBatch(id: 'b2', routerId: 'r1'));
      await repo.saveBatch(_makeBatch(id: 'b3', routerId: 'r2'));

      await repo.deleteAllForRouter('r1');

      expect(await repo.listBatches('r1'), isEmpty);
      expect(await repo.listBatches('r2'), hasLength(1));
    });
  });

  // ---------------------------------------------------------------------------
  // VoucherGenerationParams provider
  // ---------------------------------------------------------------------------

  group('VoucherGenerationParamsNotifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(voucherGenerationParamsProvider), isNull);
    });

    test('setParams updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final params = VoucherGenerationParams(
        routerId: 'r',
        routerHost: '192.168.1.1',
        profileName: 'default',
        quantity: 10,
        mode: VoucherMode.voucher,
        charSet: VoucherCharSet.digitMixed,
        usernameLength: 8,
        passwordLength: 8,
      );

      container.read(voucherGenerationParamsProvider.notifier).setParams(params);
      expect(container.read(voucherGenerationParamsProvider), equals(params));
    });

    test('clearParams sets null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final params = VoucherGenerationParams(
        routerId: 'r',
        routerHost: '192.168.1.1',
        profileName: 'default',
        quantity: 10,
        mode: VoucherMode.voucher,
        charSet: VoucherCharSet.digitMixed,
        usernameLength: 8,
        passwordLength: 8,
      );

      container.read(voucherGenerationParamsProvider.notifier).setParams(params);
      container.read(voucherGenerationParamsProvider.notifier).clearParams();
      expect(container.read(voucherGenerationParamsProvider), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // VoucherTemplateNotifier
  // ---------------------------------------------------------------------------

  group('VoucherTemplateNotifier', () {
    test('initial template is default220', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(voucherTemplateProvider),
        equals(VoucherTemplate.default220),
      );
    });

    test('setTemplate updates to thermal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(voucherTemplateProvider.notifier)
          .setTemplate(VoucherTemplate.thermal180);
      expect(
        container.read(voucherTemplateProvider),
        equals(VoucherTemplate.thermal180),
      );
    });

    test('setTemplate updates to small', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(voucherTemplateProvider.notifier)
          .setTemplate(VoucherTemplate.small160);
      expect(
        container.read(voucherTemplateProvider),
        equals(VoucherTemplate.small160),
      );
    });
  });
}
