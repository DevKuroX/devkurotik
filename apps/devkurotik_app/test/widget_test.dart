import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/main.dart';
import 'package:devkurotik_app/src/data/database/app_database.dart';
import 'package:devkurotik_app/src/data/repositories/router_repository.dart';
import 'package:devkurotik_app/src/providers/router_providers.dart';

/// In-memory fake FlutterSecureStorage for smoke tests.
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

void main() {
  late AppDatabase db;
  late RouterRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = RouterRepository(db: db, secureStorage: _FakeSecureStorage());
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildApp() => ProviderScope(
    overrides: [routerRepositoryProvider.overrideWithValue(repo)],
    child: const DevKuroTikApp(),
  );

  group('DevKuroTikApp — smoke tests', () {
    testWidgets('app builds without error', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('router list screen renders on startup', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      // AppBar title should say 'Routers'.
      expect(find.text('Routers'), findsOneWidget);
    });

    testWidgets('ProviderScope wraps app correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp());
      expect(find.byType(ProviderScope), findsOneWidget);
    });
  });
}
