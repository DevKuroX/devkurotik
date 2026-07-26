/// Unit tests for RouterInfo — AMENDMENT_001 Deliverable B.
library;

import 'package:test/test.dart';

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

void main() {
  group('RouterInfo.fromApiMaps — all fields present', () {
    late RouterInfo info;

    setUp(() {
      info = RouterInfo.fromApiMaps(
        identityMap: {'name': 'main-router'},
        resourceMap: {
          'version': '7.15.1 (stable)',
          'board-name': 'CCR1036-12G-4S',
          'architecture-name': 'tile',
          'cpu-count': '4',
          'total-memory': '1073741824',
          'platform': 'MikroTik',
        },
        detectedAt: DateTime(2026, 7, 26, 12, 0),
      );
    });

    test('identity is set correctly', () {
      expect(info.identity, 'main-router');
    });

    test('version is parsed', () {
      expect(info.version.major, 7);
      expect(info.version.minor, 15);
      expect(info.version.patch, 1);
    });

    test('board is set', () {
      expect(info.board, 'CCR1036-12G-4S');
    });

    test('architecture is set', () {
      expect(info.architecture, 'tile');
    });

    test('cpuCount is parsed', () {
      expect(info.cpuCount, 4);
    });

    test('totalMemoryBytes is parsed', () {
      expect(info.totalMemoryBytes, 1073741824);
    });

    test('platform is set', () {
      expect(info.platform, 'MikroTik');
    });

    test('detectedAt is preserved', () {
      expect(info.detectedAt, DateTime(2026, 7, 26, 12, 0));
    });
  });

  group('RouterInfo.isChr detection', () {
    test('board == "CHR" → isChr = true', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {'board-name': 'CHR'},
        detectedAt: DateTime.now(),
      );
      expect(info.isChr, isTrue);
    });

    test('board == "chr" (lowercase) → isChr = true (case-insensitive)', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {'board-name': 'chr'},
        detectedAt: DateTime.now(),
      );
      expect(info.isChr, isTrue);
    });

    test('board == "CHR Amazon EC2 t3.small" → isChr = true (real CHR v7 value)',
        () {
      // Discovered from live CHR v7 test: board-name is "CHR Amazon EC2 t3.small".
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {'board-name': 'CHR Amazon EC2 t3.small'},
        detectedAt: DateTime.now(),
      );
      expect(info.isChr, isTrue);
    });

    test('board == "CCR1036-12G-4S" → isChr = false', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {'board-name': 'CCR1036-12G-4S'},
        detectedAt: DateTime.now(),
      );
      expect(info.isChr, isFalse);
    });

    test('missing board-name → isChr = false', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {},
        detectedAt: DateTime.now(),
      );
      expect(info.isChr, isFalse);
    });
  });

  group('RouterInfo.isVirtual detection', () {
    test('CHR board → isVirtual = true', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {'board-name': 'CHR'},
        detectedAt: DateTime.now(),
      );
      expect(info.isVirtual, isTrue);
    });

    test('x86_64 architecture → isVirtual = true', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {
          'board-name': 'PC',
          'architecture-name': 'x86_64',
        },
        detectedAt: DateTime.now(),
      );
      expect(info.isVirtual, isTrue);
    });

    test('x86 in architecture → isVirtual = true', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {'architecture-name': 'x86'},
        detectedAt: DateTime.now(),
      );
      expect(info.isVirtual, isTrue);
    });

    test('physical MIPS board → isVirtual = false', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {
          'board-name': 'RB750Gr3',
          'architecture-name': 'mipsbe',
        },
        detectedAt: DateTime.now(),
      );
      expect(info.isVirtual, isFalse);
    });
  });

  group('RouterInfo.fromApiMaps — graceful degradation (missing fields)', () {
    test('all empty maps → safe defaults, no throw', () {
      expect(
        () => RouterInfo.fromApiMaps(
          identityMap: {},
          resourceMap: {},
          detectedAt: DateTime.now(),
        ),
        returnsNormally,
      );
    });

    test('missing identity name → empty string', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {},
        detectedAt: DateTime.now(),
      );
      expect(info.identity, isEmpty);
    });

    test('missing version → RouterVersion.unknown', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {},
        detectedAt: DateTime.now(),
      );
      expect(info.version.isUnknown, isTrue);
    });

    test('missing cpu-count → 0', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {},
        detectedAt: DateTime.now(),
      );
      expect(info.cpuCount, 0);
    });

    test('non-numeric cpu-count → 0', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {'cpu-count': 'N/A'},
        detectedAt: DateTime.now(),
      );
      expect(info.cpuCount, 0);
    });

    test('missing total-memory → 0', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {},
        detectedAt: DateTime.now(),
      );
      expect(info.totalMemoryBytes, 0);
    });
  });

  group('RouterInfo.toString', () {
    test('does not expose sensitive data', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {'name': 'test'},
        resourceMap: {'board-name': 'CHR', 'version': '7.15.1 (stable)'},
        detectedAt: DateTime.now(),
      );
      final str = info.toString();
      expect(str, contains('test'));
      expect(str, contains('CHR'));
      // Password must not be referenced.
      expect(str, isNot(contains('password')));
    });
  });
}
