/// Integration tests for router persistence.
///
/// Tests the full persistence round-trip:
/// add → persist → reload → verify fields
/// Also covers: edit persistence, delete cleanup, last-used tracking.
library;

import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/data/database/app_database.dart';
import 'package:devkurotik_app/src/data/repositories/router_repository.dart';
import 'package:devkurotik_app/src/domain/models/router_model.dart';

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

void main() {
  late AppDatabase db;
  late _FakeSecureStorage secure;
  late RouterRepository repo;

  const r1 = RouterModel(
    id: 'int-001',
    name: 'Production Router',
    host: '10.10.10.1',
    port: 8728,
    username: 'admin',
    group: RouterGroup.production,
    note: 'main router',
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    secure = _FakeSecureStorage();
    repo = RouterRepository(db: db, secureStorage: secure);
  });

  tearDown(() async {
    await db.close();
  });

  group('Add → List round-trip', () {
    test('router survives a full persist + re-read cycle', () async {
      await repo.addRouter(router: r1, password: 'supersecret');

      final reloaded = await repo.getRouter('int-001');
      expect(reloaded, isNotNull);
      expect(reloaded!.name, 'Production Router');
      expect(reloaded.host, '10.10.10.1');
      expect(reloaded.port, 8728);
      expect(reloaded.username, 'admin');
      expect(reloaded.group, RouterGroup.production);
      expect(reloaded.note, 'main router');
    });

    test('password is in secure storage, NOT in Drift row fields', () async {
      await repo.addRouter(router: r1, password: 'supersecret');

      // Password must be in secure storage.
      final pw = await repo.getPassword('int-001');
      expect(pw, 'supersecret');

      // Drift row must NOT contain password in accessible fields.
      // (Confirmed by RouterModel having no password field — structural test.)
      final reloaded = await repo.getRouter('int-001');
      final str = reloaded.toString();
      expect(str, isNot(contains('supersecret')));
    });
  });

  group('Edit → List round-trip', () {
    test('updated fields are reflected on reload', () async {
      await repo.addRouter(router: r1, password: 'pass1');

      final updated = r1.copyWith(
        name: 'Updated Name',
        host: '10.10.10.99',
        group: RouterGroup.staging,
      );
      await repo.updateRouter(router: updated, password: 'pass2');

      final reloaded = await repo.getRouter('int-001');
      expect(reloaded!.name, 'Updated Name');
      expect(reloaded.host, '10.10.10.99');
      expect(reloaded.group, RouterGroup.staging);
    });

    test('password update is reflected in secure storage', () async {
      await repo.addRouter(router: r1, password: 'pass1');
      await repo.updateRouter(router: r1, password: 'pass2');

      final pw = await repo.getPassword('int-001');
      expect(pw, 'pass2');
    });

    test('password unchanged when not passed to updateRouter', () async {
      await repo.addRouter(router: r1, password: 'original');
      await repo.updateRouter(router: r1.copyWith(name: 'New Name'));

      final pw = await repo.getPassword('int-001');
      expect(pw, 'original');
    });
  });

  group('Delete round-trip', () {
    test('router is gone from list after delete', () async {
      await repo.addRouter(router: r1, password: 'pass');
      await repo.deleteRouter('int-001');

      final all = await repo.listRouters();
      expect(all, isEmpty);
    });

    test('password is gone from secure storage after delete', () async {
      await repo.addRouter(router: r1, password: 'pass');
      await repo.deleteRouter('int-001');

      final pw = await repo.getPassword('int-001');
      expect(pw, isNull);
    });

    test('getRouter returns null after delete', () async {
      await repo.addRouter(router: r1, password: 'pass');
      await repo.deleteRouter('int-001');

      final found = await repo.getRouter('int-001');
      expect(found, isNull);
    });
  });

  group('Multi-router management', () {
    const r2 = RouterModel(
      id: 'int-002',
      name: 'Staging Router',
      host: '10.20.20.1',
      port: 8728,
      username: 'admin',
      group: RouterGroup.staging,
    );
    const r3 = RouterModel(
      id: 'int-003',
      name: 'Home Router',
      host: '192.168.1.1',
      port: 8728,
      username: 'admin',
      group: RouterGroup.home,
    );

    test('all three routers are listed independently', () async {
      await repo.addRouter(router: r1, password: 'p1');
      await repo.addRouter(router: r2, password: 'p2');
      await repo.addRouter(router: r3, password: 'p3');

      final all = await repo.listRouters();
      expect(all, hasLength(3));
      expect(all.map((r) => r.id), containsAll(['int-001', 'int-002', 'int-003']));
    });

    test('each router has its own password in secure storage', () async {
      await repo.addRouter(router: r1, password: 'p1');
      await repo.addRouter(router: r2, password: 'p2');
      await repo.addRouter(router: r3, password: 'p3');

      expect(await repo.getPassword('int-001'), 'p1');
      expect(await repo.getPassword('int-002'), 'p2');
      expect(await repo.getPassword('int-003'), 'p3');
    });

    test('deleting one does not affect others', () async {
      await repo.addRouter(router: r1, password: 'p1');
      await repo.addRouter(router: r2, password: 'p2');
      await repo.addRouter(router: r3, password: 'p3');

      await repo.deleteRouter('int-002');

      final all = await repo.listRouters();
      expect(all, hasLength(2));
      expect(all.map((r) => r.id), isNot(contains('int-002')));
      expect(await repo.getPassword('int-002'), isNull);
      // Others intact.
      expect(await repo.getPassword('int-001'), 'p1');
      expect(await repo.getPassword('int-003'), 'p3');
    });
  });

  group('Last-used router persistence', () {
    test('last-used router round-trip', () async {
      await repo.addRouter(router: r1, password: 'pass');
      await repo.setLastUsedRouter('int-001');

      final lastId = await repo.getLastUsedRouterId();
      expect(lastId, 'int-001');

      final lastRouter = await repo.getLastUsedRouter();
      expect(lastRouter?.id, 'int-001');
    });

    test('setLastUsedRouter updates lastUsedAt timestamp', () async {
      await repo.addRouter(router: r1, password: 'pass');

      await repo.setLastUsedRouter('int-001');
      final after = DateTime.now().add(const Duration(milliseconds: 1));

      final router = await repo.getRouter('int-001');
      expect(router?.lastUsedAt, isNotNull);
      expect(router!.lastUsedAt!.isBefore(after), isTrue);
    });

    test('last-used is cleared when the last-used router is deleted', () async {
      await repo.addRouter(router: r1, password: 'pass');
      await repo.setLastUsedRouter('int-001');
      await repo.deleteRouter('int-001');

      final lastId = await repo.getLastUsedRouterId();
      expect(lastId, isNull);
    });
  });

  group('Router grouping persistence', () {
    test('all RouterGroup values persist and reload correctly', () async {
      var idx = 0;
      for (final group in RouterGroup.values) {
        final router = RouterModel(
          id: 'group-test-$idx',
          name: 'Router ${group.name}',
          host: '10.0.0.$idx',
          port: 8728,
          username: 'admin',
          group: group,
        );
        await repo.addRouter(router: router, password: 'pass');
        idx++;
      }

      for (final group in RouterGroup.values) {
        final routers = await repo.listRoutersByGroup(group);
        expect(routers, hasLength(1));
        expect(routers.first.group, group);
      }
    });
  });
}
