/// Phase 4 — Unit tests for hotspot providers.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/hotspot_models.dart';
import 'package:devkurotik_app/src/providers/hotspot_providers.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Fake HotspotData for testing.
HotspotData _fakeData({String routerId = 'r1'}) {
  return HotspotData(
    routerId: routerId,
    users: [
      HotspotUser.fromApiMap({
        '.id': '*1', 'name': 'user001', 'profile': 'daily', 'disabled': 'false',
        'comment': 'batch-A',
      }),
      HotspotUser.fromApiMap({
        '.id': '*2', 'name': 'user002', 'profile': 'weekly', 'disabled': 'false',
      }),
      HotspotUser.fromApiMap({
        '.id': '*3', 'name': 'user003', 'profile': 'daily', 'disabled': 'true',
      }),
      HotspotUser.fromApiMap({
        '.id': '*4', 'name': 'user004', 'profile': 'daily', 'disabled': 'false',
        'limit-uptime': '1s',
      }),
    ],
    profiles: [
      HotspotProfile.fromApiMap({'.id': '*1', 'name': 'daily'}),
      HotspotProfile.fromApiMap({'.id': '*2', 'name': 'weekly'}),
    ],
    activeSessions: [
      HotspotActive.fromApiMap({
        '.id': '*1', 'user': 'user001', 'server': 'hotspot1',
        'mac-address': 'AA:BB:CC:DD:EE:FF', 'address': '10.0.0.1',
      }),
    ],
    fetchedAt: DateTime.now(),
  );
}

// ---------------------------------------------------------------------------
// Fake notifiers — must extend the real notifier classes
// ---------------------------------------------------------------------------

class _FakeActiveHotspot extends ActiveHotspotNotifier {
  _FakeActiveHotspot(this._data);
  final HotspotData? _data;

  @override
  Future<HotspotData?> build() async => _data;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('HotspotSearchNotifier', () {
    test('initial state is empty string', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(hotspotSearchProvider), '');
    });

    test('setQuery updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(hotspotSearchProvider.notifier).setQuery('abc');
      expect(container.read(hotspotSearchProvider), 'abc');
    });

    test('clearQuery resets to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(hotspotSearchProvider.notifier).setQuery('abc');
      container.read(hotspotSearchProvider.notifier).clearQuery();
      expect(container.read(hotspotSearchProvider), '');
    });
  });

  group('HotspotFilterNotifier', () {
    test('initial state is all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(hotspotFilterProvider),
        HotspotUserFilter.all,
      );
    });

    test('setFilter updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(hotspotFilterProvider.notifier)
          .setFilter(HotspotUserFilter.expired);
      expect(
        container.read(hotspotFilterProvider),
        HotspotUserFilter.expired,
      );
    });

    test('reset returns to all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(hotspotFilterProvider.notifier)
          .setFilter(HotspotUserFilter.byProfile);
      container.read(hotspotFilterProvider.notifier).reset();
      expect(
        container.read(hotspotFilterProvider),
        HotspotUserFilter.all,
      );
    });
  });

  group('HotspotProfileFilterNotifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(hotspotProfileFilterProvider), isNull);
    });

    test('setProfile updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(hotspotProfileFilterProvider.notifier).setProfile('daily');
      expect(container.read(hotspotProfileFilterProvider), 'daily');
    });

    test('clear resets to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(hotspotProfileFilterProvider.notifier).setProfile('daily');
      container.read(hotspotProfileFilterProvider.notifier).clear();
      expect(container.read(hotspotProfileFilterProvider), isNull);
    });
  });

  group('HotspotCommentFilterNotifier', () {
    test('initial state is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(hotspotCommentFilterProvider), isNull);
    });

    test('setComment updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(hotspotCommentFilterProvider.notifier).setComment('batch-A');
      expect(container.read(hotspotCommentFilterProvider), 'batch-A');
    });
  });

  group('filteredHotspotUsersProvider', () {
    test('returns empty list when no data', () {
      final container = ProviderContainer(
        overrides: [
          activeHotspotProvider.overrideWith(
            () => _FakeActiveHotspot(null),
          ),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(filteredHotspotUsersProvider), isEmpty);
    });

    test('returns all users when filter=all and no search', () async {
      final container = ProviderContainer(
        overrides: [
          activeHotspotProvider.overrideWith(
            () => _FakeActiveHotspot(_fakeData()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(activeHotspotProvider.future);
      final users = container.read(filteredHotspotUsersProvider);
      expect(users.length, 4);
    });

    test('filters by profile', () async {
      final container = ProviderContainer(
        overrides: [
          activeHotspotProvider.overrideWith(
            () => _FakeActiveHotspot(_fakeData()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(activeHotspotProvider.future);

      container
          .read(hotspotFilterProvider.notifier)
          .setFilter(HotspotUserFilter.byProfile);
      container
          .read(hotspotProfileFilterProvider.notifier)
          .setProfile('daily');

      final users = container.read(filteredHotspotUsersProvider);
      expect(users.every((u) => u.profile == 'daily'), isTrue);
      expect(users.length, 3);
    });

    test('filters expired users', () async {
      final container = ProviderContainer(
        overrides: [
          activeHotspotProvider.overrideWith(
            () => _FakeActiveHotspot(_fakeData()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(activeHotspotProvider.future);

      container
          .read(hotspotFilterProvider.notifier)
          .setFilter(HotspotUserFilter.expired);

      final users = container.read(filteredHotspotUsersProvider);
      expect(users.every((u) => u.isExpired), isTrue);
      expect(users.length, 1);
    });

    test('search filters by name', () async {
      final container = ProviderContainer(
        overrides: [
          activeHotspotProvider.overrideWith(
            () => _FakeActiveHotspot(_fakeData()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(activeHotspotProvider.future);

      container.read(hotspotSearchProvider.notifier).setQuery('user001');
      final users = container.read(filteredHotspotUsersProvider);
      expect(users.length, 1);
      expect(users.first.name, 'user001');
    });

    test('search filters by comment', () async {
      final container = ProviderContainer(
        overrides: [
          activeHotspotProvider.overrideWith(
            () => _FakeActiveHotspot(_fakeData()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(activeHotspotProvider.future);

      container.read(hotspotSearchProvider.notifier).setQuery('batch-A');
      final users = container.read(filteredHotspotUsersProvider);
      expect(users.length, 1);
      expect(users.first.name, 'user001');
    });

    test('search is case-insensitive', () async {
      final container = ProviderContainer(
        overrides: [
          activeHotspotProvider.overrideWith(
            () => _FakeActiveHotspot(_fakeData()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(activeHotspotProvider.future);

      container.read(hotspotSearchProvider.notifier).setQuery('USER001');
      final users = container.read(filteredHotspotUsersProvider);
      expect(users.length, 1);
    });

    test('filters by comment code', () async {
      final container = ProviderContainer(
        overrides: [
          activeHotspotProvider.overrideWith(
            () => _FakeActiveHotspot(_fakeData()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(activeHotspotProvider.future);

      container
          .read(hotspotFilterProvider.notifier)
          .setFilter(HotspotUserFilter.byComment);
      container
          .read(hotspotCommentFilterProvider.notifier)
          .setComment('batch-A');

      final users = container.read(filteredHotspotUsersProvider);
      expect(users.length, 1);
      expect(users.first.name, 'user001');
    });

    test('combined profile filter + search', () async {
      final container = ProviderContainer(
        overrides: [
          activeHotspotProvider.overrideWith(
            () => _FakeActiveHotspot(_fakeData()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(activeHotspotProvider.future);

      // Filter daily (3 users), then search for "001" (1 result)
      container
          .read(hotspotFilterProvider.notifier)
          .setFilter(HotspotUserFilter.byProfile);
      container
          .read(hotspotProfileFilterProvider.notifier)
          .setProfile('daily');
      container.read(hotspotSearchProvider.notifier).setQuery('001');

      final users = container.read(filteredHotspotUsersProvider);
      expect(users.length, 1);
      expect(users.first.name, 'user001');
    });
  });
}
