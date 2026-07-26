/// Widget tests for EditRouterScreen.
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
import 'package:devkurotik_app/src/ui/router_management/edit_router_screen.dart';

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
  }) async => _store[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => _store.remove(key);
}

Widget _buildEditScreen({
  required RouterRepository repo,
  required String routerId,
}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => EditRouterScreen(routerId: routerId),
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

  const testRouter = RouterModel(
    id: 'edit-001',
    name: 'Router To Edit',
    host: '192.168.88.1',
    port: 8728,
    username: 'admin',
    group: RouterGroup.office,
    note: 'original note',
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    secure = _FakeSecureStorage();
    repo = RouterRepository(db: db, secureStorage: secure);
  });

  tearDown(() async {
    await db.close();
  });

  group('EditRouterScreen', () {
    testWidgets('shows not-found message for unknown router id', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildEditScreen(repo: repo, routerId: 'nonexistent'),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('edit_router_not_found')), findsOneWidget);
    });

    testWidgets('renders form fields after loading without error', (
      tester,
    ) async {
      await repo.addRouter(router: testRouter, password: 'pass');
      await tester.pumpWidget(
        _buildEditScreen(repo: repo, routerId: 'edit-001'),
      );
      await tester.pumpAndSettle();
      // No exception thrown, form is visible.
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('router_name_field')), findsOneWidget);
    });

    testWidgets('renders form fields after loading', (tester) async {
      await repo.addRouter(router: testRouter, password: 'pass');
      await tester.pumpWidget(
        _buildEditScreen(repo: repo, routerId: 'edit-001'),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('router_name_field')), findsOneWidget);
      expect(find.byKey(const Key('router_host_field')), findsOneWidget);
      expect(find.byKey(const Key('router_port_field')), findsOneWidget);
      expect(find.byKey(const Key('router_username_field')), findsOneWidget);
      expect(find.byKey(const Key('router_password_field')), findsOneWidget);
    });

    testWidgets('pre-fills form with existing router data', (tester) async {
      await repo.addRouter(router: testRouter, password: 'pass');
      await tester.pumpWidget(
        _buildEditScreen(repo: repo, routerId: 'edit-001'),
      );
      await tester.pumpAndSettle();

      // Verify pre-filled name.
      final nameField = tester.widget<TextField>(
        find
            .descendant(
              of: find.byKey(const Key('router_name_field')),
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(nameField.controller?.text, 'Router To Edit');
    });

    testWidgets('shows update button in app bar', (tester) async {
      await repo.addRouter(router: testRouter, password: 'pass');
      await tester.pumpWidget(
        _buildEditScreen(repo: repo, routerId: 'edit-001'),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('update_router_btn')), findsOneWidget);
    });

    testWidgets('shows validation error when name is cleared', (tester) async {
      await repo.addRouter(router: testRouter, password: 'pass');
      await tester.pumpWidget(
        _buildEditScreen(repo: repo, routerId: 'edit-001'),
      );
      await tester.pumpAndSettle();

      // Clear the name field.
      await tester.tap(find.byKey(const Key('router_name_field')));
      await tester.enterText(find.byKey(const Key('router_name_field')), '');
      await tester.tap(find.byKey(const Key('update_router_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('password field is blank (isEdit mode)', (tester) async {
      await repo.addRouter(router: testRouter, password: 'pass');
      await tester.pumpWidget(
        _buildEditScreen(repo: repo, routerId: 'edit-001'),
      );
      await tester.pumpAndSettle();

      final passwordField = tester.widget<TextField>(
        find
            .descendant(
              of: find.byKey(const Key('router_password_field')),
              matching: find.byType(TextField),
            )
            .first,
      );
      // Password is blank in edit mode.
      expect(passwordField.controller?.text, isEmpty);
    });
  });
}
