/// Widget tests for RouterListScreen.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:devkurotik_app/src/data/database/app_database.dart';
import 'package:devkurotik_app/src/data/repositories/router_repository.dart';
import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/providers/router_providers.dart';
import 'package:devkurotik_app/src/ui/router_management/router_list_screen.dart';

/// In-memory fake FlutterSecureStorage.
class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final _store = <String, String>{};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

/// Build a testable widget tree with overridden providers.
/// Only overrides routerRepositoryProvider to avoid double-open of DB.
Widget _buildTestApp({required RouterRepository repo}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => const RouterListScreen(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [routerRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late AppDatabase db;
  late _FakeSecureStorage secure;
  late RouterRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    secure = _FakeSecureStorage();
    repo = RouterRepository(db: db, secureStorage: secure);
  });

  tearDown(() async {
    await db.close();
  });

  group('RouterListScreen — empty state', () {
    testWidgets('shows empty message when no routers saved', (tester) async {
      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('router_list_empty')), findsOneWidget);
    });

    testWidgets('shows add FAB', (tester) async {
      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add_router_fab')), findsOneWidget);
    });

    testWidgets('shows AppBar with title "Routers"', (tester) async {
      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Routers'), findsOneWidget);
    });
  });

  group('RouterListScreen — with routers', () {
    const r1 = RouterModel(
      id: 'id-1',
      name: 'Office Router',
      host: '192.168.88.1',
      port: 8728,
      username: 'admin',
      group: RouterGroup.office,
    );
    const r2 = RouterModel(
      id: 'id-2',
      name: 'Home Router',
      host: '10.0.0.1',
      port: 8728,
      username: 'admin',
      group: RouterGroup.home,
    );

    testWidgets('shows router tiles when routers exist', (tester) async {
      await repo.addRouter(router: r1, password: 'pass1');
      await repo.addRouter(router: r2, password: 'pass2');

      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('router_list_view')), findsOneWidget);
      expect(find.byKey(const Key('router_tile_id-1')), findsOneWidget);
      expect(find.byKey(const Key('router_tile_id-2')), findsOneWidget);
    });

    testWidgets('shows router names in tiles', (tester) async {
      await repo.addRouter(router: r1, password: 'pass1');
      await repo.addRouter(router: r2, password: 'pass2');

      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('Office Router'), findsOneWidget);
      expect(find.text('Home Router'), findsOneWidget);
    });

    testWidgets('group filter chips are shown', (tester) async {
      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('group_filter_all')), findsOneWidget);
      expect(
        find.byKey(const Key('group_filter_office'), skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('filtering by group shows only matching routers', (
      tester,
    ) async {
      await repo.addRouter(router: r1, password: 'pass1');
      await repo.addRouter(router: r2, password: 'pass2');

      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      // Use ungrouped which is always visible (first chip after All).
      // r1 is in 'office', r2 is in 'home'. Use ungrouped filter which has no matches.
      await tester.tap(
        find.byKey(
          const Key('group_filter_ungrouped'),
          skipOffstage: false,
        ),
      );
      await tester.pumpAndSettle();

      // Neither router is in 'ungrouped', so both should be hidden.
      expect(find.text('Office Router'), findsNothing);
      expect(find.text('Home Router'), findsNothing);
    });
  });

  group('RouterListScreen — delete', () {
    const router = RouterModel(
      id: 'del-1',
      name: 'Router To Delete',
      host: '192.168.1.1',
      port: 8728,
      username: 'admin',
      group: RouterGroup.ungrouped,
    );

    testWidgets('shows delete confirmation dialog', (tester) async {
      await repo.addRouter(router: router, password: 'pass');

      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      // Open popup menu for the router tile.
      await tester.tap(find.byKey(const Key('router_menu_del-1')));
      await tester.pumpAndSettle();

      // Tap "Delete" in the popup.
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('delete_confirmation_dialog')),
        findsOneWidget,
      );
    });

    testWidgets('cancel button closes dialog without deleting', (tester) async {
      await repo.addRouter(router: router, password: 'pass');

      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('router_menu_del-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_cancel_btn')));
      await tester.pumpAndSettle();

      // Router should still exist in the list.
      expect(find.text('Router To Delete'), findsOneWidget);
    });

    testWidgets('confirm delete removes router from list', (tester) async {
      await repo.addRouter(router: router, password: 'pass');

      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('router_menu_del-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_confirm_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Router To Delete'), findsNothing);
      expect(find.byKey(const Key('router_list_empty')), findsOneWidget);
    });
  });

  group('RouterListScreen — selection', () {
    const r1 = RouterModel(
      id: 'sel-1',
      name: 'Select Router',
      host: '192.168.88.1',
      port: 8728,
      username: 'admin',
      group: RouterGroup.ungrouped,
    );

    testWidgets('tapping a tile sets it as active (snackbar shown)', (
      tester,
    ) async {
      await repo.addRouter(router: r1, password: 'pass');

      await tester.pumpWidget(_buildTestApp(repo: repo));
      await tester.pumpAndSettle();

      // Tap the tile to select it.
      await tester.tap(find.byKey(const Key('router_tile_sel-1')));
      await tester.pumpAndSettle();

      // Snackbar should appear.
      expect(find.text('Active router: Select Router'), findsOneWidget);
    });
  });
}
