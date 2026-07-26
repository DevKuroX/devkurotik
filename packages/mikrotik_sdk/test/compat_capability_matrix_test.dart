/// Unit tests for CapabilityMatrix — AMENDMENT_001 Deliverable C.
library;

import 'package:test/test.dart';

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

RouterVersion v(String s) => RouterVersion.parse(s);

void main() {
  group('CapabilityMatrix.supportsPlainAuth', () {
    test('v6.43 → true (boundary)', () {
      expect(CapabilityMatrix.supportsPlainAuth(v('6.43')), isTrue);
    });

    test('v6.42 → false (just below)', () {
      expect(CapabilityMatrix.supportsPlainAuth(v('6.42')), isFalse);
    });

    test('v6.49 → true', () {
      expect(CapabilityMatrix.supportsPlainAuth(v('6.49')), isTrue);
    });

    test('v7.15.1 → true', () {
      expect(CapabilityMatrix.supportsPlainAuth(v('7.15.1 (stable)')), isTrue);
    });

    test('unknown → false (safe default)', () {
      expect(CapabilityMatrix.supportsPlainAuth(RouterVersion.unknown), isFalse);
    });
  });

  group('CapabilityMatrix.requiresMd5Auth', () {
    test('v6.42 → true', () {
      expect(CapabilityMatrix.requiresMd5Auth(v('6.42')), isTrue);
    });

    test('v6.43 → false (boundary)', () {
      expect(CapabilityMatrix.requiresMd5Auth(v('6.43')), isFalse);
    });

    test('v7.15.1 → false', () {
      expect(CapabilityMatrix.requiresMd5Auth(v('7.15.1 (stable)')), isFalse);
    });

    test('unknown → true (safe default — assume older auth)', () {
      expect(CapabilityMatrix.requiresMd5Auth(RouterVersion.unknown), isTrue);
    });
  });

  group('CapabilityMatrix.supportsHotspot', () {
    test('v6.0 → true (lower boundary)', () {
      expect(CapabilityMatrix.supportsHotspot(v('6.0')), isTrue);
    });

    test('v6.49 → true', () {
      expect(CapabilityMatrix.supportsHotspot(v('6.49')), isTrue);
    });

    test('v7.15.1 → true', () {
      expect(CapabilityMatrix.supportsHotspot(v('7.15.1 (stable)')), isTrue);
    });

    test('unknown → false (safe default)', () {
      expect(CapabilityMatrix.supportsHotspot(RouterVersion.unknown), isFalse);
    });
  });

  group('CapabilityMatrix.supportsPppoe', () {
    test('v6.0 → true', () {
      expect(CapabilityMatrix.supportsPppoe(v('6.0')), isTrue);
    });

    test('v7.15.1 → true', () {
      expect(CapabilityMatrix.supportsPppoe(v('7.15.1 (stable)')), isTrue);
    });

    test('unknown → false', () {
      expect(CapabilityMatrix.supportsPppoe(RouterVersion.unknown), isFalse);
    });
  });

  group('CapabilityMatrix.supportsApiSsl', () {
    test('v6.49 → true (boundary)', () {
      expect(CapabilityMatrix.supportsApiSsl(v('6.49')), isTrue);
    });

    test('v6.48 → false (just below)', () {
      expect(CapabilityMatrix.supportsApiSsl(v('6.48')), isFalse);
    });

    test('v7.15.1 → true', () {
      expect(CapabilityMatrix.supportsApiSsl(v('7.15.1 (stable)')), isTrue);
    });

    test('unknown → false', () {
      expect(CapabilityMatrix.supportsApiSsl(RouterVersion.unknown), isFalse);
    });
  });

  group('CapabilityMatrix.hasKnownVariance', () {
    test('v7.15.1 → false (no documented variance)', () {
      expect(
        CapabilityMatrix.hasKnownVariance(v('7.15.1 (stable)')),
        isFalse,
      );
    });

    test('v6.42 (pre-plain-auth) → true (MD5 variance noted)', () {
      expect(CapabilityMatrix.hasKnownVariance(v('6.42')), isTrue);
    });

    test('v6.43 (plain auth) → false', () {
      expect(CapabilityMatrix.hasKnownVariance(v('6.43')), isFalse);
    });

    test('unknown → false (no actionable variance for unknown)', () {
      expect(
        CapabilityMatrix.hasKnownVariance(RouterVersion.unknown),
        isFalse,
      );
    });
  });

  group('CapabilityMatrix.varianceNote', () {
    test('v6.42 → non-null note mentioning MD5', () {
      final note = CapabilityMatrix.varianceNote(v('6.42'));
      expect(note, isNotNull);
      expect(note, contains('MD5'));
    });

    test('v7.15.1 → null (no variance)', () {
      expect(
        CapabilityMatrix.varianceNote(v('7.15.1 (stable)')),
        isNull,
      );
    });

    test('unknown → null', () {
      expect(CapabilityMatrix.varianceNote(RouterVersion.unknown), isNull);
    });

    test('v6.43 → null (plain auth, no variance)', () {
      expect(CapabilityMatrix.varianceNote(v('6.43')), isNull);
    });
  });

  group('CapabilityMatrix.summary', () {
    test('v7.15.1 summary has correct keys and types', () {
      final s = CapabilityMatrix.summary(v('7.15.1 (stable)'));
      expect(s['supportsPlainAuth'], isTrue);
      expect(s['requiresMd5Auth'], isFalse);
      expect(s['supportsHotspot'], isTrue);
      expect(s['supportsPppoe'], isTrue);
      expect(s['supportsApiSsl'], isTrue);
      expect(s['hasKnownVariance'], isFalse);
      expect(s['varianceNote'], '');
    });

    test('unknown version summary does not throw', () {
      expect(
        () => CapabilityMatrix.summary(RouterVersion.unknown),
        returnsNormally,
      );
    });
  });
}
