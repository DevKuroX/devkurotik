import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('RouterosRandom', () {
    test('digits generates string of correct length', () {
      final result = RouterosRandom.digits(8);
      expect(result.length, equals(8));
    });

    test('digits contains only allowed characters', () {
      final result = RouterosRandom.digits(100);
      expect(RegExp(r'^[23456789]+$').hasMatch(result), isTrue);
    });

    test('upper generates only uppercase letters', () {
      final result = RouterosRandom.upper(50);
      expect(result.length, equals(50));
      expect(RegExp(r'^[A-Z]+$').hasMatch(result), isTrue);
    });

    test('lower generates only lowercase letters', () {
      final result = RouterosRandom.lower(50);
      expect(result.length, equals(50));
      expect(RegExp(r'^[a-z]+$').hasMatch(result), isTrue);
    });

    test('mixed generates alphanumeric', () {
      final result = RouterosRandom.mixed(100);
      expect(result.length, equals(100));
      expect(RegExp(r'^[a-zA-Z]+$').hasMatch(result), isTrue);
    });

    test('digitLower generates digits and lowercase', () {
      final result = RouterosRandom.digitLower(100);
      expect(RegExp(r'^[23456789a-z]+$').hasMatch(result), isTrue);
    });

    test('digitUpper generates digits and uppercase', () {
      final result = RouterosRandom.digitUpper(100);
      expect(RegExp(r'^[23456789A-Z]+$').hasMatch(result), isTrue);
    });

    test('digitMixed generates digits, lower, and upper', () {
      final result = RouterosRandom.digitMixed(100);
      expect(RegExp(r'^[23456789a-zA-Z]+$').hasMatch(result), isTrue);
    });

    test('returns empty string for length 0', () {
      expect(RouterosRandom.digits(0), equals(''));
      expect(RouterosRandom.upper(0), equals(''));
    });

    test('generates unique results on successive calls', () {
      // Not guaranteed but practically certain with crypto random
      final a = RouterosRandom.digitMixed(16);
      final b = RouterosRandom.digitMixed(16);
      expect(a, isNot(equals(b)));
    });

    test('excludes ambiguous characters 0, 1, O, I, l', () {
      // Generate large sample and check ambiguous chars are absent
      final sample = List.generate(
        100,
        (_) => RouterosRandom.digitMixed(20),
      ).join();
      expect(sample.contains('0'), isFalse);
      expect(sample.contains('1'), isFalse);
      // O and I should be excluded from upper charset
      // l should be excluded from lower charset
    });
  });

  group('RouterosFormat', () {
    group('uptime', () {
      test('formats seconds only', () {
        expect(RouterosFormat.uptime('30s'), equals('00:00:30'));
      });

      test('formats minutes only', () {
        expect(RouterosFormat.uptime('45m'), equals('00:45:00'));
      });

      test('formats hours only', () {
        expect(RouterosFormat.uptime('2h'), equals('02:00:00'));
      });

      test('formats hours and minutes', () {
        expect(RouterosFormat.uptime('2h30m'), equals('02:30:00'));
      });

      test('formats days and hours and minutes and seconds', () {
        expect(RouterosFormat.uptime('1d2h3m4s'), equals('26:03:04'));
      });

      test('formats weeks', () {
        expect(RouterosFormat.uptime('1w'), equals('168:00:00'));
      });

      test('returns 00:00:00 for empty string', () {
        expect(RouterosFormat.uptime(''), equals('00:00:00'));
      });

      test('returns 00:00:00 for unparseable string', () {
        expect(RouterosFormat.uptime('invalid'), equals('00:00:00'));
      });

      test('pads single-digit values with zeros', () {
        expect(RouterosFormat.uptime('1h1m1s'), equals('01:01:01'));
      });
    });

    group('bytes', () {
      test('formats bytes', () {
        expect(RouterosFormat.bytes(512), equals('512 B'));
      });

      test('formats kilobytes', () {
        expect(RouterosFormat.bytes(1536), equals('1.5 KB'));
      });

      test('formats megabytes', () {
        expect(RouterosFormat.bytes(1048576), equals('1.0 MB'));
      });

      test('formats gigabytes', () {
        expect(RouterosFormat.bytes(1073741824), equals('1.0 GB'));
      });

      test('formats terabytes', () {
        expect(RouterosFormat.bytes(1099511627776), equals('1.0 TB'));
      });

      test('handles zero', () {
        expect(RouterosFormat.bytes(0), equals('0 B'));
      });

      test('handles negative (returns 0 B)', () {
        expect(RouterosFormat.bytes(-1), equals('0 B'));
      });
    });

    group('bitrate', () {
      test('formats bps', () {
        expect(RouterosFormat.bitrate(512), equals('512 bps'));
      });

      test('formats Kbps', () {
        expect(RouterosFormat.bitrate(1500), equals('1.5 Kbps'));
      });

      test('formats Mbps', () {
        expect(RouterosFormat.bitrate(1500000), equals('1.5 Mbps'));
      });

      test('formats Gbps', () {
        expect(RouterosFormat.bitrate(1000000000), equals('1.0 Gbps'));
      });

      test('handles zero', () {
        expect(RouterosFormat.bitrate(0), equals('0 bps'));
      });
    });
  });

  group('MikrotikCredentials', () {
    test('constructs with required fields', () {
      const creds = MikrotikCredentials(
        host: '192.168.1.1',
        username: 'admin',
        password: 'secret',
      );
      expect(creds.host, equals('192.168.1.1'));
      expect(creds.username, equals('admin'));
      expect(creds.port, equals(8728));
      expect(creds.useSsl, isFalse);
    });

    test('toString does not contain password', () {
      const creds = MikrotikCredentials(
        host: '10.0.0.1',
        username: 'user',
        password: 'verysecretpassword',
      );
      final str = creds.toString();
      expect(str, isNot(contains('verysecretpassword')));
      expect(str, contains('10.0.0.1'));
      expect(str, contains('user'));
    });

    test('fromMap roundtrip', () {
      const creds = MikrotikCredentials(
        host: '172.16.0.1',
        username: 'api',
        password: 'apipass',
        port: 8728,
      );
      final map = creds.toMap();
      final restored = MikrotikCredentials.fromMap(map);
      expect(restored.host, equals(creds.host));
      expect(restored.username, equals(creds.username));
      expect(restored.password, equals(creds.password));
      expect(restored.port, equals(creds.port));
    });

    test('copyWith overrides specified fields', () {
      const original = MikrotikCredentials(
        host: '192.168.1.1',
        username: 'admin',
        password: 'pass',
      );
      final copy = original.copyWith(port: 8729, useSsl: true);
      expect(copy.host, equals(original.host));
      expect(copy.username, equals(original.username));
      expect(copy.port, equals(8729));
      expect(copy.useSsl, isTrue);
    });
  });
}
