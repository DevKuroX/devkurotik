/// Unit tests for RouterRepository using an in-memory Drift database
/// and a fake secure storage implementation (no external mock library needed).
library;

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/data/database/app_database.dart';
import 'package:devkurotik_app/src/data/repositories/router_repository.dart';
import 'package:devkurotik_app/src/domain/models/router_model.dart';

/// In-memory fake for FlutterSecureStorage.
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

  bool contains(String key) => _store.containsKey(key);
  String? get(String key) => _store[key];
}

void main() {
  late AppDatabase db;
  late _FakeSecureStorage fakeSecure;
  late RouterRepository repo;

  const testRouter = RouterModel(
    id: 'abc-123',
    name: 'Test Router',
    host: '192.168.88.1',
    port: 8728,
    username: 'admin',
    group: RouterGroup.office,
    note: 'test note',
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    fakeSecure = _FakeSecureStorage();
    repo = RouterRepository(db: db, secureStorage: fakeSecure);
  });

  tearDown(() async {
    await db.close();
  });

  group('addRouter', () {
    test('stores metadata in Drift and password in secure storage', () async {
      await repo.addRouter(router: testRouter, password: 'secret123');

      final all = await repo.listRouters();
      expect(all, hasLength(1));
      expect(all.first.id, 'abc-123');
      expect(all.first.name, 'Test Router');

      expect(fakeSecure.get('router_pwd_abc-123'), 'secret123');
    });

    test('throws on empty name', () async {
      const bad = RouterModel(
        id: 'bad-id',
        name: '',
        host: '192.168.88.1',
        port: 8728,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );
      await expectLater(
        repo.addRouter(router: bad, password: 'pass'),
        throwsA(isA<RouterValidationException>()),
      );
    });

    test('throws on empty host', () async {
      const bad = RouterModel(
        id: 'bad-id',
        name: 'Router',
        host: '',
        port: 8728,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );
      await expectLater(
        repo.addRouter(router: bad, password: 'pass'),
        throwsA(isA<RouterValidationException>()),
      );
    });

    test('throws on empty username', () async {
      const bad = RouterModel(
        id: 'bad-id',
        name: 'Router',
        host: '10.0.0.1',
        port: 8728,
        username: '',
        group: RouterGroup.ungrouped,
      );
      await expectLater(
        repo.addRouter(router: bad, password: 'pass'),
        throwsA(isA<RouterValidationException>()),
      );
    });

    test('throws on empty password', () async {
      await expectLater(
        repo.addRouter(router: testRouter, password: ''),
        throwsA(isA<RouterValidationException>()),
      );
    });

    test('throws on port 0', () async {
      const bad = RouterModel(
        id: 'bad-id',
        name: 'Router',
        host: '192.168.88.1',
        port: 0,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );
      await expectLater(
        repo.addRouter(router: bad, password: 'pass'),
        throwsA(isA<RouterValidationException>()),
      );
    });

    test('throws on port > 65535', () async {
      const bad = RouterModel(
        id: 'bad-id',
        name: 'Router',
        host: '192.168.88.1',
        port: 65536,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );
      await expectLater(
        repo.addRouter(router: bad, password: 'pass'),
        throwsA(isA<RouterValidationException>()),
      );
    });
  });

  group('updateRouter', () {
    setUp(() async {
      await repo.addRouter(router: testRouter, password: 'secret123');
    });

    test('updates metadata in Drift', () async {
      final updated = testRouter.copyWith(name: 'Updated Router');
      await repo.updateRouter(router: updated);

      final found = await repo.getRouter('abc-123');
      expect(found?.name, 'Updated Router');
    });

    test('updates password in secure storage when provided', () async {
      final updated = testRouter.copyWith(name: 'Updated');
      await repo.updateRouter(router: updated, password: 'newpassword');

      expect(fakeSecure.get('router_pwd_abc-123'), 'newpassword');
    });

    test('does NOT change password when password param is null', () async {
      final updated = testRouter.copyWith(name: 'Updated');
      await repo.updateRouter(router: updated);

      // Original password unchanged.
      expect(fakeSecure.get('router_pwd_abc-123'), 'secret123');
    });

    test('validates router before updating', () async {
      const bad = RouterModel(
        id: 'abc-123',
        name: '',
        host: '192.168.88.1',
        port: 8728,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );
      await expectLater(
        repo.updateRouter(router: bad),
        throwsA(isA<RouterValidationException>()),
      );
    });
  });

  group('deleteRouter', () {
    setUp(() async {
      await repo.addRouter(router: testRouter, password: 'secret123');
    });

    test('removes router from Drift', () async {
      await repo.deleteRouter('abc-123');
      final all = await repo.listRouters();
      expect(all, isEmpty);
    });

    test('deletes password from secure storage', () async {
      await repo.deleteRouter('abc-123');
      expect(fakeSecure.contains('router_pwd_abc-123'), isFalse);
    });

    test('clears last-used if it was this router', () async {
      await fakeSecure.write(key: 'last_used_router_id', value: 'abc-123');
      await repo.deleteRouter('abc-123');
      expect(fakeSecure.contains('last_used_router_id'), isFalse);
    });

    test('does NOT clear last-used if it was a different router', () async {
      await fakeSecure.write(key: 'last_used_router_id', value: 'other-id');
      await repo.deleteRouter('abc-123');
      expect(fakeSecure.get('last_used_router_id'), 'other-id');
    });
  });

  group('getRouter', () {
    test('returns null for missing router', () async {
      final result = await repo.getRouter('nonexistent');
      expect(result, isNull);
    });

    test('returns router after adding', () async {
      await repo.addRouter(router: testRouter, password: 'pass');
      final result = await repo.getRouter('abc-123');
      expect(result?.id, 'abc-123');
      expect(result?.host, '192.168.88.1');
    });

    test('round-trips all fields correctly', () async {
      final withOptionals = testRouter.copyWith(
        group: RouterGroup.staging,
        note: 'a note',
        lastUsedAt: DateTime.fromMillisecondsSinceEpoch(1_000_000),
      );
      await repo.addRouter(router: withOptionals, password: 'pw');
      final found = await repo.getRouter('abc-123');
      expect(found?.group, RouterGroup.staging);
      expect(found?.note, 'a note');
    });
  });

  group('listRouters', () {
    test('returns empty list when no routers', () async {
      final all = await repo.listRouters();
      expect(all, isEmpty);
    });

    test('returns all routers after adding multiple', () async {
      const router2 = RouterModel(
        id: 'xyz-456',
        name: 'Router 2',
        host: '10.0.0.1',
        port: 8728,
        username: 'admin',
        group: RouterGroup.home,
      );

      await repo.addRouter(router: testRouter, password: 'pass1');
      await repo.addRouter(router: router2, password: 'pass2');

      final all = await repo.listRouters();
      expect(all, hasLength(2));
    });

    test('orders by name when no lastUsedAt', () async {
      const routerA = RouterModel(
        id: 'id-b',
        name: 'Alpha',
        host: '10.0.0.1',
        port: 8728,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );
      const routerB = RouterModel(
        id: 'id-a',
        name: 'Zeta',
        host: '10.0.0.2',
        port: 8728,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );
      await repo.addRouter(router: routerB, password: 'p');
      await repo.addRouter(router: routerA, password: 'p');

      final all = await repo.listRouters();
      expect(all.first.name, 'Alpha');
      expect(all.last.name, 'Zeta');
    });
  });

  group('listRoutersByGroup', () {
    test('returns only routers in the specified group', () async {
      const routerHome = RouterModel(
        id: 'home-1',
        name: 'Home Router',
        host: '192.168.1.1',
        port: 8728,
        username: 'admin',
        group: RouterGroup.home,
      );

      await repo.addRouter(router: testRouter, password: 'p1');
      await repo.addRouter(router: routerHome, password: 'p2');

      final officeRouters = await repo.listRoutersByGroup(RouterGroup.office);
      expect(officeRouters, hasLength(1));
      expect(officeRouters.first.group, RouterGroup.office);

      final homeRouters = await repo.listRoutersByGroup(RouterGroup.home);
      expect(homeRouters, hasLength(1));
      expect(homeRouters.first.group, RouterGroup.home);
    });

    test('returns empty when no routers in group', () async {
      await repo.addRouter(router: testRouter, password: 'p1');
      final stagingRouters =
          await repo.listRoutersByGroup(RouterGroup.staging);
      expect(stagingRouters, isEmpty);
    });
  });

  group('getPassword', () {
    test('returns password for stored router', () async {
      await repo.addRouter(router: testRouter, password: 'mysecret');
      final pw = await repo.getPassword('abc-123');
      expect(pw, 'mysecret');
    });

    test('returns null for unknown router', () async {
      final pw = await repo.getPassword('unknown-id');
      expect(pw, isNull);
    });
  });

  group('last-used router', () {
    test('setLastUsedRouter writes to secure storage', () async {
      await repo.addRouter(router: testRouter, password: 'pass');
      await repo.setLastUsedRouter('abc-123');

      expect(fakeSecure.get('last_used_router_id'), 'abc-123');
    });

    test('getLastUsedRouterId returns stored value', () async {
      await fakeSecure.write(key: 'last_used_router_id', value: 'abc-123');
      final id = await repo.getLastUsedRouterId();
      expect(id, 'abc-123');
    });

    test('getLastUsedRouterId returns null when not set', () async {
      final id = await repo.getLastUsedRouterId();
      expect(id, isNull);
    });

    test('getLastUsedRouter returns null when no last-used set', () async {
      final result = await repo.getLastUsedRouter();
      expect(result, isNull);
    });

    test('getLastUsedRouter returns null when router does not exist', () async {
      await fakeSecure.write(key: 'last_used_router_id', value: 'deleted-id');
      final result = await repo.getLastUsedRouter();
      expect(result, isNull);
    });

    test('getLastUsedRouter returns the router model after it is added',
        () async {
      await repo.addRouter(router: testRouter, password: 'pass');
      await repo.setLastUsedRouter('abc-123');

      final result = await repo.getLastUsedRouter();
      expect(result?.id, 'abc-123');
    });

    test('setLastUsedRouter updates lastUsedAt in Drift', () async {
      await repo.addRouter(router: testRouter, password: 'pass');
      await repo.setLastUsedRouter('abc-123');

      final router = await repo.getRouter('abc-123');
      expect(router?.lastUsedAt, isNotNull);
    });
  });

  group('RouterValidationException', () {
    test('toString includes message', () {
      const e = RouterValidationException('test message');
      expect(e.toString(), contains('test message'));
    });

    test('is an Exception', () {
      const e = RouterValidationException('msg');
      expect(e, isA<Exception>());
    });
  });
}
