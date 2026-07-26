import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('MikrotikLogger credential redaction', () {
    test('redacts =password= attribute', () {
      final result = MikrotikLogger.redactWords([
        '/ip/hotspot/user/add',
        '=name=john',
        '=password=mysecret123',
        '=profile=daily',
      ]);

      expect(result, contains('=name=john'));
      expect(result, contains('=profile=daily'));
      expect(result.any((w) => w.contains('mysecret123')), isFalse);
      expect(result, contains('=password=***'));
    });

    test('redactWord preserves non-sensitive words', () {
      expect(
        MikrotikLogger.redactWord('/ip/hotspot/user/print'),
        equals('/ip/hotspot/user/print'),
      );
      expect(
        MikrotikLogger.redactWord('?profile=daily'),
        equals('?profile=daily'),
      );
      expect(MikrotikLogger.redactWord('=name=admin'), equals('=name=admin'));
    });

    test('redactWord redacts =password= word', () {
      expect(
        MikrotikLogger.redactWord('=password=secret123'),
        equals('=password=***'),
      );
    });

    test('redactWord redacts =.password= word', () {
      expect(
        MikrotikLogger.redactWord('=.password=hidden'),
        equals('=password=***'),
      );
    });

    test('redacts password= in log messages', () {
      // Access through public logging — check via redactWords
      final words = MikrotikLogger.redactWords(['=password=hunter2']);
      expect(words.any((w) => w.contains('hunter2')), isFalse);
    });

    test('does not redact non-sensitive attributes', () {
      final words = MikrotikLogger.redactWords([
        '=name=alice',
        '=uptime=1d00:00:00',
        '=disabled=false',
      ]);
      expect(words[0], equals('=name=alice'));
      expect(words[1], equals('=uptime=1d00:00:00'));
      expect(words[2], equals('=disabled=false'));
    });
  });

  group('MikrotikLogger log methods', () {
    test('logConnection does not throw', () {
      expect(
        () => MikrotikLogger.logConnection('Connected to 192.168.1.1'),
        returnsNormally,
      );
    });

    test('logError does not throw', () {
      expect(() => MikrotikLogger.logError('Socket error'), returnsNormally);
    });

    test('logCommand does not throw', () {
      expect(
        () => MikrotikLogger.logCommand('Sending /ip/hotspot/user/print'),
        returnsNormally,
      );
    });
  });
}
