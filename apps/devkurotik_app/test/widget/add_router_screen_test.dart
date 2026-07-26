/// Widget tests for AddRouterScreen.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:devkurotik_app/src/data/database/app_database.dart';
import 'package:devkurotik_app/src/data/repositories/router_repository.dart';
import 'package:devkurotik_app/src/providers/router_providers.dart';
import 'package:devkurotik_app/src/ui/router_management/add_router_screen.dart';

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
  }) async =>
      _store[key];

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.remove(key);
}

Widget _buildAddScreen({required RouterRepository repo}) {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const AddRouterScreen()),
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

  group('AddRouterScreen', () {
    testWidgets('renders form fields', (tester) async {
      await tester.pumpWidget(_buildAddScreen(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('router_name_field')), findsOneWidget);
      expect(find.byKey(const Key('router_host_field')), findsOneWidget);
      expect(find.byKey(const Key('router_port_field')), findsOneWidget);
      expect(find.byKey(const Key('router_username_field')), findsOneWidget);
      expect(find.byKey(const Key('router_password_field')), findsOneWidget);
      expect(find.byKey(const Key('router_group_dropdown')), findsOneWidget);
      expect(find.byKey(const Key('router_note_field')), findsOneWidget);
    });

    testWidgets('shows save button in app bar', (tester) async {
      await tester.pumpWidget(_buildAddScreen(repo: repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('save_router_btn')), findsOneWidget);
    });

    testWidgets('shows validation error when name is empty', (tester) async {
      await tester.pumpWidget(_buildAddScreen(repo: repo));
      await tester.pumpAndSettle();

      // Fill everything except name.
      await tester.enterText(
        find.byKey(const Key('router_host_field')),
        '192.168.88.1',
      );
      await tester.enterText(
        find.byKey(const Key('router_username_field')),
        'admin',
      );
      await tester.enterText(
        find.byKey(const Key('router_password_field')),
        'password',
      );

      await tester.tap(find.byKey(const Key('save_router_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
    });

    testWidgets('shows validation error when host is empty', (tester) async {
      await tester.pumpWidget(_buildAddScreen(repo: repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('router_name_field')),
        'My Router',
      );
      await tester.enterText(
        find.byKey(const Key('router_password_field')),
        'password',
      );

      await tester.tap(find.byKey(const Key('save_router_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Host is required'), findsOneWidget);
    });

    testWidgets('shows validation error when password is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildAddScreen(repo: repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('router_name_field')),
        'My Router',
      );
      await tester.enterText(
        find.byKey(const Key('router_host_field')),
        '192.168.88.1',
      );

      await tester.tap(find.byKey(const Key('save_router_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('shows validation error for invalid port', (tester) async {
      await tester.pumpWidget(_buildAddScreen(repo: repo));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('router_name_field')),
        'My Router',
      );
      await tester.enterText(
        find.byKey(const Key('router_host_field')),
        '192.168.88.1',
      );
      await tester.enterText(
        find.byKey(const Key('router_password_field')),
        'pass',
      );

      // Clear port and enter invalid value.
      await tester.tap(find.byKey(const Key('router_port_field')));
      await tester.enterText(find.byKey(const Key('router_port_field')), '0');

      await tester.tap(find.byKey(const Key('save_router_btn')));
      await tester.pumpAndSettle();

      expect(find.text('Port must be 1–65535'), findsOneWidget);
    });

    testWidgets('password toggle shows/hides text', (tester) async {
      await tester.pumpWidget(_buildAddScreen(repo: repo));
      await tester.pumpAndSettle();

      // Find the toggle button and tap it.
      await tester.tap(find.byKey(const Key('toggle_password_btn')));
      await tester.pumpAndSettle();

      // The password field should now be visible (obscureText = false).
      final field = tester.widget<TextField>(
        find
            .descendant(
              of: find.byKey(const Key('router_password_field')),
              matching: find.byType(TextField),
            )
            .first,
      );
      expect(field.obscureText, isFalse);
    });

    testWidgets('valid form submission saves router to repository', (
      tester,
    ) async {
      // Build a route stack so we can pop back to a home route.
      final goRouter = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: Text('Home'),
            ),
            routes: [
              GoRoute(
                path: 'add',
                builder: (_, _) => const AddRouterScreen(),
              ),
            ],
          ),
        ],
        initialLocation: '/add',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [routerRepositoryProvider.overrideWithValue(repo)],
          child: MaterialApp.router(routerConfig: goRouter),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('router_name_field')),
        'New Router',
      );
      await tester.enterText(
        find.byKey(const Key('router_host_field')),
        '192.168.88.1',
      );
      await tester.enterText(
        find.byKey(const Key('router_username_field')),
        'admin',
      );
      await tester.enterText(
        find.byKey(const Key('router_password_field')),
        'password123',
      );

      await tester.tap(find.byKey(const Key('save_router_btn')));
      await tester.pumpAndSettle();

      // Should have navigated back (no add screen visible).
      expect(find.byKey(const Key('save_router_btn')), findsNothing);

      // Verify router was saved.
      final routers = await repo.listRouters();
      expect(routers, hasLength(1));
      expect(routers.first.name, 'New Router');
    });
  });
}
