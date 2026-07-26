/// Unit tests for RouterVersion — AMENDMENT_001 Deliverable A.
library;

import 'package:test/test.dart';

import 'package:mikrotik_sdk/mikrotik_sdk.dart';

void main() {
  group('RouterVersion.parse — canonical forms', () {
    test('parses full version with channel: "7.15.1 (stable)"', () {
      final v = RouterVersion.parse('7.15.1 (stable)');
      expect(v.major, 7);
      expect(v.minor, 15);
      expect(v.patch, 1);
      expect(v.channel, 'stable');
      expect(v.raw, '7.15.1 (stable)');
    });

    test('parses full version with long-term channel', () {
      final v = RouterVersion.parse('6.49.17 (long-term)');
      expect(v.major, 6);
      expect(v.minor, 49);
      expect(v.patch, 17);
      expect(v.channel, 'long-term');
    });

    test('parses short form without patch: "6.49"', () {
      final v = RouterVersion.parse('6.49');
      expect(v.major, 6);
      expect(v.minor, 49);
      expect(v.patch, 0);
      expect(v.channel, '');
    });

    test('parses major-only form: "7"', () {
      final v = RouterVersion.parse('7');
      expect(v.major, 7);
      expect(v.minor, 0);
      expect(v.patch, 0);
    });

    test('parses "6.43" correctly (plain-auth boundary)', () {
      final v = RouterVersion.parse('6.43');
      expect(v.major, 6);
      expect(v.minor, 43);
      expect(v.patch, 0);
    });

    test('parses "6.42" correctly (MD5 auth boundary)', () {
      final v = RouterVersion.parse('6.42.12 (stable)');
      expect(v.major, 6);
      expect(v.minor, 42);
      expect(v.patch, 12);
    });

    test('trims surrounding whitespace', () {
      final v = RouterVersion.parse('  7.15.1 (stable)  ');
      expect(v.major, 7);
      expect(v.minor, 15);
    });
  });

  group('RouterVersion.parse — graceful degradation (no throw)', () {
    test('empty string → unknown', () {
      final v = RouterVersion.parse('');
      expect(v, RouterVersion.unknown);
      expect(v.isUnknown, isTrue);
    });

    test('"unknown" string → unknown', () {
      final v = RouterVersion.parse('unknown');
      expect(v.isUnknown, isTrue);
    });

    test('non-numeric major → unknown', () {
      final v = RouterVersion.parse('x.y.z');
      expect(v.isUnknown, isTrue);
    });

    test('partial garbage with numeric prefix does not throw', () {
      expect(() => RouterVersion.parse('7.abc.1'), returnsNormally);
    });
  });

  group('RouterVersion.unknown sentinel', () {
    test('isUnknown is true for the sentinel', () {
      expect(RouterVersion.unknown.isUnknown, isTrue);
    });

    test('isUnknown is false for real versions', () {
      expect(RouterVersion.parse('7.15.1 (stable)').isUnknown, isFalse);
    });
  });

  group('RouterVersion.isAtLeast', () {
    final v7_15_1 = RouterVersion.parse('7.15.1 (stable)');
    final v6_49 = RouterVersion.parse('6.49');
    final v6_43 = RouterVersion.parse('6.43');
    final v6_42 = RouterVersion.parse('6.42');

    test('v7.15.1 isAtLeast(7, 0) → true', () {
      expect(v7_15_1.isAtLeast(7, 0), isTrue);
    });

    test('v7.15.1 isAtLeast(7, 15, 1) → true (exact)', () {
      expect(v7_15_1.isAtLeast(7, 15, 1), isTrue);
    });

    test('v7.15.1 isAtLeast(7, 15, 2) → false (patch too high)', () {
      expect(v7_15_1.isAtLeast(7, 15, 2), isFalse);
    });

    test('v6.49 isAtLeast(7, 0) → false', () {
      expect(v6_49.isAtLeast(7, 0), isFalse);
    });

    test('v6.43 isAtLeast(6, 43) → true (exact boundary)', () {
      expect(v6_43.isAtLeast(6, 43), isTrue);
    });

    test('v6.42 isAtLeast(6, 43) → false (just below)', () {
      expect(v6_42.isAtLeast(6, 43), isFalse);
    });
  });

  group('RouterVersion.isBefore', () {
    final v6_42 = RouterVersion.parse('6.42');
    final v6_43 = RouterVersion.parse('6.43');

    test('v6.42 isBefore(6, 43) → true', () {
      expect(v6_42.isBefore(6, 43), isTrue);
    });

    test('v6.43 isBefore(6, 43) → false (exact boundary)', () {
      expect(v6_43.isBefore(6, 43), isFalse);
    });
  });

  group('RouterVersion — auth mode helpers', () {
    test('v6.42 requiresMd5Auth → true', () {
      expect(RouterVersion.parse('6.42').requiresMd5Auth(), isTrue);
    });

    test('v6.42 supportsPlainAuth → false', () {
      expect(RouterVersion.parse('6.42').supportsPlainAuth(), isFalse);
    });

    test('v6.43 supportsPlainAuth → true', () {
      expect(RouterVersion.parse('6.43').supportsPlainAuth(), isTrue);
    });

    test('v6.43 requiresMd5Auth → false', () {
      expect(RouterVersion.parse('6.43').requiresMd5Auth(), isFalse);
    });

    test('v7.15.1 supportsPlainAuth → true', () {
      expect(RouterVersion.parse('7.15.1 (stable)').supportsPlainAuth(), isTrue);
    });
  });

  group('RouterVersion comparison operators', () {
    final v7 = RouterVersion.parse('7.15.1 (stable)');
    final v6 = RouterVersion.parse('6.49');
    final v6b = RouterVersion.parse('6.49');

    test('v7 > v6', () => expect(v7 > v6, isTrue));
    test('v6 < v7', () => expect(v6 < v7, isTrue));
    test('v6 == v6b (same values)', () => expect(v6 == v6b, isTrue));
    test('v6 <= v6b', () => expect(v6 <= v6b, isTrue));
    test('v7 >= v6', () => expect(v7 >= v6, isTrue));
    test('compareTo is consistent with >', () {
      expect(v7.compareTo(v6) > 0, isTrue);
    });
  });

  group('RouterVersion hashCode and equality', () {
    test('equal versions have same hashCode', () {
      final a = RouterVersion.parse('7.15.1 (stable)');
      final b = RouterVersion.parse('7.15.1 (testing)');
      // Equality is major.minor.patch only — channel is ignored.
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('different versions have different hashCodes', () {
      final a = RouterVersion.parse('6.49');
      final b = RouterVersion.parse('7.0');
      expect(a == b, isFalse);
    });
  });

  group('RouterVersion.toString', () {
    test('returns raw when set', () {
      final v = RouterVersion.parse('7.15.1 (stable)');
      expect(v.toString(), '7.15.1 (stable)');
    });

    test('unknown returns sentinel raw string', () {
      expect(RouterVersion.unknown.toString(), 'unknown');
    });
  });
}
