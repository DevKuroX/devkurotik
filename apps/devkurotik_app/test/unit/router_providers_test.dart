/// Unit tests for router Riverpod providers.
library;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/data/database/app_database.dart';
import 'package:devkurotik_app/src/data/repositories/router_repository.dart';
import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/providers/router_providers.dart';

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

ProviderContainer makeContainer(RouterRepository repo) {
  return ProviderContainer(
    overrides: [routerRepositoryProvider.overrideWithValue(repo)],
  );
}

void main() {
  late AppDatabase db;
  late RouterRepository repo;
  late ProviderContainer container;

  const r1 = RouterModel(
    id: 'prov-001',
    name: 'Router A',
    host: '10.0.0.1',
    port: 8728,
    username: 'admin',
    group: RouterGroup.production,
  );

  const r2 = RouterModel(
    id: 'prov-002',
    name: 'Router B',
    host: '10.0.0.2',
    port: 8728,
    username: 'admin',
    group: RouterGroup.staging,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = RouterRepository(db: db, secureStorage: _FakeSecureStorage());
    container = makeContainer(repo);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('routerListProvider', () {
    test('initially empty', () async {
      final list = await container.read(routerListProvider.future);
      expect(list, isEmpty);
    });

    test('addRouter via notifier updates list', () async {
      await container.read(routerListProvider.notifier).addRouter(
        router: r1,
        password: 'pass',
      );
      final list = await container.read(routerListProvider.future);
      expect(list, hasLength(1));
      expect(list.first.id, 'prov-001');
    });

    test('updateRouter via notifier reflects in list', () async {
      await container.read(routerListProvider.notifier).addRouter(
        router: r1,
        password: 'pass',
      );
      final updated = r1.copyWith(name: 'Router A Updated');
      await container.read(routerListProvider.notifier).updateRouter(
        router: updated,
      );
      final list = await container.read(routerListProvider.future);
      expect(list.first.name, 'Router A Updated');
    });

    test('deleteRouter removes from list', () async {
      await container.read(routerListProvider.notifier).addRouter(
        router: r1,
        password: 'pass',
      );
      await container.read(routerListProvider.notifier).addRouter(
        router: r2,
        password: 'pass',
      );
      await container.read(routerListProvider.notifier).deleteRouter('prov-001');
      final list = await container.read(routerListProvider.future);
      expect(list, hasLength(1));
      expect(list.first.id, 'prov-002');
    });

    test('reload refreshes list', () async {
      await repo.addRouter(router: r1, password: 'pass');
      await container.read(routerListProvider.notifier).reload();
      final list = await container.read(routerListProvider.future);
      expect(list, hasLength(1));
    });
  });

  group('activeRouterProvider', () {
    test('initially null', () {
      final active = container.read(activeRouterProvider);
      // May be null or loading (async last-used resolution).
      expect(active, isNull);
    });

    test('selectRouter sets active router', () async {
      await container.read(routerListProvider.notifier).addRouter(
        router: r1,
        password: 'pass',
      );
      await container.read(activeRouterProvider.notifier).selectRouter(r1);
      final active = container.read(activeRouterProvider);
      expect(active?.id, 'prov-001');
    });

    test('clearActive sets active to null', () async {
      await container.read(activeRouterProvider.notifier).selectRouter(r1);
      container.read(activeRouterProvider.notifier).clearActive();
      expect(container.read(activeRouterProvider), isNull);
    });

    test('deleteRouter clears active if it was the deleted router', () async {
      await container.read(routerListProvider.notifier).addRouter(
        router: r1,
        password: 'pass',
      );
      await container.read(routerListProvider.notifier).addRouter(
        router: r2,
        password: 'pass',
      );
      await container.read(activeRouterProvider.notifier).selectRouter(r1);
      await container.read(routerListProvider.notifier).deleteRouter('prov-001');

      final active = container.read(activeRouterProvider);
      expect(active, isNull);
    });
  });

  group('routerHealthProvider', () {
    test('initially empty map', () async {
      final health = await container.read(routerHealthProvider.future);
      expect(health, isEmpty);
    });

    test('checkRouter with no stored password marks authFailed', () async {
      await container.read(routerListProvider.notifier).addRouter(
        router: r1,
        password: 'pass',
      );

      // Use a router with id for which no password exists (different id).
      const orphan = RouterModel(
        id: 'orphan-id',
        name: 'Orphan',
        host: '10.0.0.99',
        port: 8728,
        username: 'admin',
        group: RouterGroup.ungrouped,
      );

      await container.read(routerHealthProvider.notifier).checkRouter(orphan);

      final health = await container.read(routerHealthProvider.future);
      expect(health['orphan-id']?.status, RouterHealthStatus.authFailed);
      expect(health['orphan-id']?.errorMessage, isNotEmpty);
    });
  });
}
