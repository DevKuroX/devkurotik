/// Phase 5 — Widget tests for voucher screens.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/data/database/app_database.dart';
import 'package:devkurotik_app/src/domain/models/voucher_models.dart';
import 'package:devkurotik_app/src/providers/router_providers.dart';
import 'package:devkurotik_app/src/providers/voucher_providers.dart';
import 'package:devkurotik_app/src/ui/voucher/voucher_preview_screen.dart';
import 'package:devkurotik_app/src/ui/voucher/voucher_template_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

VoucherBatch _makeBatch({int count = 3}) {
  return VoucherBatch(
    id: 'batch-test',
    routerId: 'router-test',
    batchCode: 'vc-A1B2-20260726',
    profileName: 'default',
    quantity: count,
    mode: VoucherMode.voucher,
    charSet: VoucherCharSet.digitMixed,
    prefix: '',
    usernameLength: 8,
    passwordLength: 8,
    generatedAt: DateTime(2026, 7, 26),
    vouchers: List.generate(
      count,
      (i) => VoucherItem(name: 'user${i + 1}', password: 'user${i + 1}'),
    ),
  );
}

AppDatabase _testDb() => AppDatabase(NativeDatabase.memory());

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(_testDb()),
      ...overrides,
    ],
    child: MaterialApp(home: child),
  );
}

// ---------------------------------------------------------------------------
// VoucherPreviewScreen
// ---------------------------------------------------------------------------

void main() {
  group('VoucherPreviewScreen', () {
    testWidgets('shows batch code in title', (tester) async {
      final batch = _makeBatch();
      await tester.pumpWidget(_wrap(VoucherPreviewScreen(batch: batch)));
      await tester.pump();
      expect(find.textContaining('vc-A1B2-20260726'), findsWidgets);
    });

    testWidgets('shows all voucher items', (tester) async {
      final batch = _makeBatch(count: 3);
      await tester.pumpWidget(_wrap(VoucherPreviewScreen(batch: batch)));
      await tester.pump();
      expect(find.text('user1'), findsOneWidget);
      expect(find.text('user2'), findsOneWidget);
      expect(find.text('user3'), findsOneWidget);
    });

    testWidgets('shows share and print buttons', (tester) async {
      final batch = _makeBatch();
      await tester.pumpWidget(_wrap(VoucherPreviewScreen(batch: batch)));
      await tester.pump();
      expect(find.byKey(const Key('share_pdf_btn')), findsOneWidget);
      expect(find.byKey(const Key('print_btn')), findsOneWidget);
    });

    testWidgets('template button exists', (tester) async {
      final batch = _makeBatch();
      await tester.pumpWidget(_wrap(VoucherPreviewScreen(batch: batch)));
      await tester.pump();
      expect(find.byKey(const Key('template_btn')), findsOneWidget);
    });

    testWidgets('shows voucher count', (tester) async {
      final batch = _makeBatch(count: 5);
      await tester.pumpWidget(_wrap(VoucherPreviewScreen(batch: batch)));
      await tester.pump();
      // 5 voucher items shown
      expect(find.byKey(const Key('voucher_0')), findsOneWidget);
      expect(find.byKey(const Key('voucher_4')), findsOneWidget);
    });

    testWidgets('shows profile name in summary bar', (tester) async {
      final batch = _makeBatch(count: 2);
      await tester.pumpWidget(_wrap(VoucherPreviewScreen(batch: batch)));
      await tester.pump();
      expect(find.textContaining('default'), findsWidgets);
    });
  });

  // ---------------------------------------------------------------------------
  // VoucherTemplateScreen
  // ---------------------------------------------------------------------------

  group('VoucherTemplateScreen', () {
    testWidgets('shows all template options', (tester) async {
      await tester.pumpWidget(_wrap(const VoucherTemplateScreen()));
      await tester.pump();
      for (final t in VoucherTemplate.values) {
        expect(
          find.byKey(Key('template_card_${t.name}')),
          findsOneWidget,
          reason: 'Template card for ${t.name} not found',
        );
      }
    });

    testWidgets('selecting thermal template updates provider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(_testDb()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VoucherTemplateScreen()),
        ),
      );
      await tester.pump();

      // Tap thermal template card.
      await tester.tap(find.byKey(const Key('template_card_thermal180')));
      await tester.pump();

      expect(
        container.read(voucherTemplateProvider),
        equals(VoucherTemplate.thermal180),
      );
    });

    testWidgets('default template starts selected', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(_testDb()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VoucherTemplateScreen()),
        ),
      );
      await tester.pump();

      expect(
        container.read(voucherTemplateProvider),
        equals(VoucherTemplate.default220),
      );
    });

    testWidgets('selecting small template updates provider', (tester) async {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(_testDb()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: VoucherTemplateScreen()),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('template_card_small160')));
      await tester.pump();

      expect(
        container.read(voucherTemplateProvider),
        equals(VoucherTemplate.small160),
      );
    });

    testWidgets('shows template labels', (tester) async {
      await tester.pumpWidget(_wrap(const VoucherTemplateScreen()));
      await tester.pump();
      expect(find.text('Default (220px)'), findsOneWidget);
      expect(find.text('Thermal (180px)'), findsOneWidget);
      expect(find.text('Small (160px)'), findsOneWidget);
    });
  });
}
