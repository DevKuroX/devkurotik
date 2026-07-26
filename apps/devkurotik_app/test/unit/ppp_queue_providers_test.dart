/// Phase 7 — PPP and Queue provider unit tests.
///
/// Smoke tests for service provider instantiation and basic provider behavior.
/// Full integration is covered by live CHR tests.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/services/ppp_service.dart';
import 'package:devkurotik_app/src/domain/services/queue_service.dart';
import 'package:devkurotik_app/src/providers/ppp_providers.dart';
import 'package:devkurotik_app/src/providers/queue_providers.dart';
import 'package:devkurotik_app/src/domain/models/ppp_models.dart';
import 'package:devkurotik_app/src/domain/models/queue_models.dart';

void main() {
  // ── Service providers ─────────────────────────────────────────────────────

  group('pppServiceProvider', () {
    test('returns PppService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(pppServiceProvider);
      expect(service, isA<PppService>());
    });
  });

  group('queueServiceProvider', () {
    test('returns QueueService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(queueServiceProvider);
      expect(service, isA<QueueService>());
    });
  });

  // ── Search providers ──────────────────────────────────────────────────────

  group('pppSearchProvider', () {
    test('starts with empty query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(pppSearchProvider), isEmpty);
    });

    test('setQuery updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pppSearchProvider.notifier).setQuery('john');
      expect(container.read(pppSearchProvider), 'john');
    });

    test('clearQuery resets to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pppSearchProvider.notifier).setQuery('john');
      container.read(pppSearchProvider.notifier).clearQuery();
      expect(container.read(pppSearchProvider), isEmpty);
    });
  });

  group('pppServiceFilterProvider', () {
    test('starts with PppServiceType.any', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(pppServiceFilterProvider), PppServiceType.any);
    });

    test('setFilter changes state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pppServiceFilterProvider.notifier).setFilter(PppServiceType.pppoe);
      expect(container.read(pppServiceFilterProvider), PppServiceType.pppoe);
    });

    test('reset restores any', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(pppServiceFilterProvider.notifier).setFilter(PppServiceType.l2tp);
      container.read(pppServiceFilterProvider.notifier).reset();
      expect(container.read(pppServiceFilterProvider), PppServiceType.any);
    });
  });

  group('queueSearchProvider', () {
    test('starts with empty query', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(queueSearchProvider), isEmpty);
    });

    test('setQuery updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(queueSearchProvider.notifier).setQuery('main');
      expect(container.read(queueSearchProvider), 'main');
    });
  });

  group('queueFilterProvider', () {
    test('starts with SimpleQueueFilter.all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(queueFilterProvider), SimpleQueueFilter.all);
    });

    test('setFilter changes state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(queueFilterProvider.notifier).setFilter(SimpleQueueFilter.enabled);
      expect(container.read(queueFilterProvider), SimpleQueueFilter.enabled);
    });

    test('reset restores all', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(queueFilterProvider.notifier).setFilter(SimpleQueueFilter.disabled);
      container.read(queueFilterProvider.notifier).reset();
      expect(container.read(queueFilterProvider), SimpleQueueFilter.all);
    });
  });

  // ── filteredPppSecretsProvider (with injected data) ───────────────────────

  group('filteredPppSecretsProvider', () {
    final s1 = PppSecret.fromApiMap({
      '.id': '*1', 'name': 'user1', 'service': 'pppoe',
      'profile': 'default', 'disabled': 'false',
    });
    final s2 = PppSecret.fromApiMap({
      '.id': '*2', 'name': 'admin', 'service': 'l2tp',
      'profile': 'admin', 'disabled': 'false',
    });
    final s3 = PppSecret.fromApiMap({
      '.id': '*3', 'name': 'user2', 'service': 'pppoe',
      'profile': 'premium', 'disabled': 'true',
    });

    final data = PppData(
      routerId: 'r1',
      secrets: [s1, s2, s3],
      profiles: [],
      activeSessions: [],
      fetchedAt: DateTime(2026),
    );

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          activePppProvider.overrideWith(() => _FakePppNotifier(data)),
        ],
      );
    }

    test('no filter returns all secrets', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      // Wait for async provider to load
      await container.read(activePppProvider.future);
      final secrets = container.read(filteredPppSecretsProvider);
      expect(secrets, hasLength(3));
    });

    test('service filter=pppoe returns only pppoe secrets', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(activePppProvider.future);
      container.read(pppServiceFilterProvider.notifier).setFilter(PppServiceType.pppoe);
      final secrets = container.read(filteredPppSecretsProvider);
      expect(secrets, hasLength(2));
      for (final s in secrets) {
        expect(s.service, PppServiceType.pppoe);
      }
    });

    test('search by name filters correctly', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(activePppProvider.future);
      container.read(pppSearchProvider.notifier).setQuery('user');
      final secrets = container.read(filteredPppSecretsProvider);
      expect(secrets, hasLength(2));
      expect(secrets.map((s) => s.name), containsAll(['user1', 'user2']));
    });

    test('search by profile filters correctly', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(activePppProvider.future);
      container.read(pppSearchProvider.notifier).setQuery('admin');
      final secrets = container.read(filteredPppSecretsProvider);
      expect(secrets, hasLength(1));
      expect(secrets.first.name, 'admin');
    });
  });

  // ── filteredSimpleQueuesProvider ──────────────────────────────────────────

  group('filteredSimpleQueuesProvider', () {
    final q1 = SimpleQueue.fromApiMap({'.id': '*1', 'name': 'q1', 'disabled': 'false', 'target': '10.0.0.1/32'});
    final q2 = SimpleQueue.fromApiMap({'.id': '*2', 'name': 'main', 'disabled': 'true'});
    final q3 = SimpleQueue.fromApiMap({'.id': '*3', 'name': 'q3', 'disabled': 'false'});

    ProviderContainer makeContainer() {
      return ProviderContainer(
        overrides: [
          activeSimpleQueueProvider.overrideWith(
            () => _FakeQueueNotifier([q1, q2, q3]),
          ),
        ],
      );
    }

    test('no filter returns all queues', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(activeSimpleQueueProvider.future);
      final queues = container.read(filteredSimpleQueuesProvider);
      expect(queues, hasLength(3));
    });

    test('filter=enabled returns only active queues', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(activeSimpleQueueProvider.future);
      container.read(queueFilterProvider.notifier).setFilter(SimpleQueueFilter.enabled);
      final queues = container.read(filteredSimpleQueuesProvider);
      expect(queues, hasLength(2));
    });

    test('filter=disabled returns only disabled queues', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(activeSimpleQueueProvider.future);
      container.read(queueFilterProvider.notifier).setFilter(SimpleQueueFilter.disabled);
      final queues = container.read(filteredSimpleQueuesProvider);
      expect(queues, hasLength(1));
      expect(queues.first.name, 'main');
    });

    test('search filters by name', () async {
      final container = makeContainer();
      addTearDown(container.dispose);
      await container.read(activeSimpleQueueProvider.future);
      container.read(queueSearchProvider.notifier).setQuery('main');
      final queues = container.read(filteredSimpleQueuesProvider);
      expect(queues, hasLength(1));
      expect(queues.first.name, 'main');
    });
  });
}

// ---------------------------------------------------------------------------
// Fake notifiers for testing
// ---------------------------------------------------------------------------

class _FakePppNotifier extends ActivePppNotifier {
  _FakePppNotifier(this._data);
  final PppData _data;

  @override
  Future<PppData?> build() async => _data;
}

class _FakeQueueNotifier extends ActiveSimpleQueueNotifier {
  _FakeQueueNotifier(this._queues);
  final List<SimpleQueue> _queues;

  @override
  Future<List<SimpleQueue>> build() async => _queues;
}
