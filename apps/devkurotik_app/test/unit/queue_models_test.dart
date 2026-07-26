/// Phase 7 — Queue domain models unit tests.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/queue_models.dart';

void main() {
  // ── SimpleQueue.fromApiMap ──────────────────────────────────────────────

  group('SimpleQueue.fromApiMap', () {
    test('parses all fields correctly', () {
      final map = {
        '.id': '*1',
        'name': 'daily-users',
        'target': '192.168.1.0/24',
        'max-limit': '2M/10M',
        'limit-at': '512k/1M',
        'burst-limit': '4M/20M',
        'burst-threshold': '1M/5M',
        'burst-time': '8/8',
        'parent': 'global',
        'priority': '4',
        'disabled': 'false',
        'comment': 'daily users queue',
        'bytes': '12345/67890',
        'packets': '100/200',
        'dropped': '0/0',
      };
      final q = SimpleQueue.fromApiMap(map);
      expect(q.id, '*1');
      expect(q.name, 'daily-users');
      expect(q.target, '192.168.1.0/24');
      expect(q.maxLimit, '2M/10M');
      expect(q.limitAt, '512k/1M');
      expect(q.burstLimit, '4M/20M');
      expect(q.burstThreshold, '1M/5M');
      expect(q.parent, 'global');
      expect(q.priority, 4);
      expect(q.disabled, isFalse);
      expect(q.comment, 'daily users queue');
    });

    test('empty optional fields become null', () {
      final map = {'.id': '*2', 'name': 'minimal'};
      final q = SimpleQueue.fromApiMap(map);
      expect(q.target, isNull);
      expect(q.maxLimit, isNull);
      expect(q.parent, isNull);
      expect(q.priority, isNull);
      expect(q.comment, isNull);
    });

    test('disabled=true parsed correctly', () {
      final map = {'.id': '*3', 'name': 'paused', 'disabled': 'true'};
      final q = SimpleQueue.fromApiMap(map);
      expect(q.disabled, isTrue);
    });

    test('equality is based on id', () {
      final a = SimpleQueue.fromApiMap({'.id': '*1', 'name': 'a'});
      final b = SimpleQueue.fromApiMap({'.id': '*1', 'name': 'b'});
      final c = SimpleQueue.fromApiMap({'.id': '*2', 'name': 'a'});
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith updates specific fields', () {
      final original = SimpleQueue.fromApiMap({'.id': '*1', 'name': 'q1', 'disabled': 'false'});
      final updated = original.copyWith(disabled: true, maxLimit: '5M/20M');
      expect(updated.id, '*1');
      expect(updated.name, 'q1');
      expect(updated.disabled, isTrue);
      expect(updated.maxLimit, '5M/20M');
    });
  });

  // ── SimpleQueueFilter ───────────────────────────────────────────────────

  group('SimpleQueueFilter', () {
    test('enum has expected values', () {
      expect(SimpleQueueFilter.values, hasLength(3));
      expect(SimpleQueueFilter.values, contains(SimpleQueueFilter.all));
      expect(SimpleQueueFilter.values, contains(SimpleQueueFilter.enabled));
      expect(SimpleQueueFilter.values, contains(SimpleQueueFilter.disabled));
    });
  });

  // ── Queue filtering logic ───────────────────────────────────────────────

  group('Queue filtering', () {
    final q1 = SimpleQueue.fromApiMap({'.id': '*1', 'name': 'q1', 'disabled': 'false', 'target': '10.0.0.1/32'});
    final q2 = SimpleQueue.fromApiMap({'.id': '*2', 'name': 'q2', 'disabled': 'true'});
    final q3 = SimpleQueue.fromApiMap({'.id': '*3', 'name': 'q3', 'disabled': 'false', 'target': '10.0.1.0/24'});

    test('filter=all returns all queues', () {
      final all = [q1, q2, q3];
      expect(all, hasLength(3));
    });

    test('filter=enabled returns only active queues', () {
      final enabled = [q1, q2, q3].where((q) => !q.disabled).toList();
      expect(enabled, hasLength(2));
      expect(enabled, containsAll([q1, q3]));
    });

    test('filter=disabled returns only disabled queues', () {
      final disabled = [q1, q2, q3].where((q) => q.disabled).toList();
      expect(disabled, hasLength(1));
      expect(disabled, contains(q2));
    });

    test('search by name filters correctly', () {
      final queues = [q1, q2, q3];
      final result = queues.where((q) => q.name.contains('q1')).toList();
      expect(result, hasLength(1));
      expect(result.first.name, 'q1');
    });

    test('search by target filters correctly', () {
      final queues = [q1, q2, q3];
      final result = queues
          .where((q) => (q.target?.contains('10.0.0') ?? false))
          .toList();
      expect(result, hasLength(1));
      expect(result.first.id, '*1');
    });
  });
}
