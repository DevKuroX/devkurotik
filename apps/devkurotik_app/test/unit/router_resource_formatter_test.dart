/// Unit tests for RouterResourceFormatter — Phase 3.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/services/router_resource_formatter.dart';

void main() {
  // ─── cpu() ─────────────────────────────────────────────────────────────────

  group('RouterResourceFormatter.cpu', () {
    test('formats zero load', () {
      expect(RouterResourceFormatter.cpu(0), equals('0%'));
    });

    test('formats 100% load', () {
      expect(RouterResourceFormatter.cpu(100), equals('100%'));
    });

    test('formats mid-range load', () {
      expect(RouterResourceFormatter.cpu(42), equals('42%'));
    });

    test('clamps values below 0 to 0%', () {
      expect(RouterResourceFormatter.cpu(-5), equals('0%'));
    });

    test('clamps values above 100 to 100%', () {
      expect(RouterResourceFormatter.cpu(150), equals('100%'));
    });
  });

  // ─── memory() ──────────────────────────────────────────────────────────────

  group('RouterResourceFormatter.memory', () {
    test('returns — for zero total', () {
      expect(
        RouterResourceFormatter.memory(freeBytes: 0, totalBytes: 0),
        equals('—'),
      );
    });

    test('formats 50% usage', () {
      final result = RouterResourceFormatter.memory(
        freeBytes: 268435456, // 256 MB free
        totalBytes: 536870912, // 512 MB total → 50% used
      );
      expect(result, equals('50% (256 MB / 512 MB)'));
    });

    test('formats 75% usage', () {
      final result = RouterResourceFormatter.memory(
        freeBytes: 134217728, // 128 MB free
        totalBytes: 536870912, // 512 MB total → 75% used
      );
      expect(result, equals('75% (384 MB / 512 MB)'));
    });

    test('formats near-full memory', () {
      final result = RouterResourceFormatter.memory(
        freeBytes: 1048576, // 1 MB free
        totalBytes: 536870912, // 512 MB total → ~100% used
      );
      expect(result, contains('MB'));
    });
  });

  // ─── memoryPercent() ───────────────────────────────────────────────────────

  group('RouterResourceFormatter.memoryPercent', () {
    test('returns — for zero total', () {
      expect(
        RouterResourceFormatter.memoryPercent(freeBytes: 0, totalBytes: 0),
        equals('—'),
      );
    });

    test('returns 50% for half used', () {
      expect(
        RouterResourceFormatter.memoryPercent(
          freeBytes: 268435456,
          totalBytes: 536870912,
        ),
        equals('50%'),
      );
    });

    test('returns 0% for all free', () {
      expect(
        RouterResourceFormatter.memoryPercent(
          freeBytes: 536870912,
          totalBytes: 536870912,
        ),
        equals('0%'),
      );
    });

    test('returns 100% for all used', () {
      expect(
        RouterResourceFormatter.memoryPercent(
          freeBytes: 0,
          totalBytes: 536870912,
        ),
        equals('100%'),
      );
    });
  });

  // ─── uptime() ──────────────────────────────────────────────────────────────

  group('RouterResourceFormatter.uptime', () {
    test('returns — for empty string', () {
      expect(RouterResourceFormatter.uptime(''), equals('—'));
    });

    test('parses full d h m s', () {
      final result = RouterResourceFormatter.uptime('4d12h30m5s');
      expect(result, equals('4d 12h 30m'));
    });

    test('parses hours and minutes (no days)', () {
      final result = RouterResourceFormatter.uptime('2h15m');
      expect(result, equals('2h 15m'));
    });

    test('parses minutes and seconds only', () {
      final result = RouterResourceFormatter.uptime('45m10s');
      expect(result, equals('45m'));
    });

    test('parses seconds only', () {
      final result = RouterResourceFormatter.uptime('30s');
      expect(result, equals('30s'));
    });

    test('parses weeks', () {
      final result = RouterResourceFormatter.uptime('1w2d3h');
      // 1w = 7d + 2d = 9d
      expect(result, equals('9d 3h 0m'));
    });

    test('parses days without hours', () {
      final result = RouterResourceFormatter.uptime('1d0h5m');
      expect(result, equals('1d 0h 5m'));
    });

    test('handles RouterOS-style "3d12h0m0s"', () {
      final result = RouterResourceFormatter.uptime('3d12h0m0s');
      expect(result, equals('3d 12h 0m'));
    });
  });

  // ─── lastSeen() ────────────────────────────────────────────────────────────

  group('RouterResourceFormatter.lastSeen', () {
    final base = DateTime(2026, 1, 1, 12, 0, 0);

    test('returns "Just now" within 10 seconds', () {
      final now = base.add(const Duration(seconds: 5));
      expect(
        RouterResourceFormatter.lastSeen(base, now: now),
        equals('Just now'),
      );
    });

    test('returns seconds ago within 1 minute', () {
      final now = base.add(const Duration(seconds: 30));
      expect(
        RouterResourceFormatter.lastSeen(base, now: now),
        equals('30s ago'),
      );
    });

    test('returns "1 min ago" at exactly 1 minute', () {
      final now = base.add(const Duration(minutes: 1));
      expect(
        RouterResourceFormatter.lastSeen(base, now: now),
        equals('1 min ago'),
      );
    });

    test('returns minutes ago', () {
      final now = base.add(const Duration(minutes: 15));
      expect(
        RouterResourceFormatter.lastSeen(base, now: now),
        equals('15 min ago'),
      );
    });

    test('returns "1 hr ago" at exactly 1 hour', () {
      final now = base.add(const Duration(hours: 1));
      expect(
        RouterResourceFormatter.lastSeen(base, now: now),
        equals('1 hr ago'),
      );
    });

    test('returns hours ago', () {
      final now = base.add(const Duration(hours: 5));
      expect(
        RouterResourceFormatter.lastSeen(base, now: now),
        equals('5 hrs ago'),
      );
    });

    test('returns "1 day ago" at 24 hours', () {
      final now = base.add(const Duration(days: 1));
      expect(
        RouterResourceFormatter.lastSeen(base, now: now),
        equals('1 day ago'),
      );
    });

    test('returns days ago', () {
      final now = base.add(const Duration(days: 3));
      expect(
        RouterResourceFormatter.lastSeen(base, now: now),
        equals('3 days ago'),
      );
    });
  });

  // ─── versionShort() ────────────────────────────────────────────────────────

  group('RouterResourceFormatter.versionShort', () {
    test('strips channel suffix', () {
      expect(
        RouterResourceFormatter.versionShort('7.15.1 (stable)'),
        equals('7.15.1'),
      );
    });

    test('returns version unchanged if no suffix', () {
      expect(
        RouterResourceFormatter.versionShort('6.49.17'),
        equals('6.49.17'),
      );
    });

    test('handles empty string', () {
      expect(RouterResourceFormatter.versionShort(''), equals(''));
    });
  });
}
