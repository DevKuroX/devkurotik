import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('RouterosException taxonomy', () {
    test('RouterosConnectionException is a RouterosException', () {
      const e = RouterosConnectionException(message: 'connection refused');
      expect(e, isA<RouterosException>());
      expect(e.message, equals('connection refused'));
      expect(e.isFatal, isTrue);
    });

    test('RouterosAuthException is a RouterosException', () {
      const e = RouterosAuthException(message: 'wrong password');
      expect(e, isA<RouterosException>());
      expect(e.message, equals('wrong password'));
      expect(e.isFatal, isTrue);
    });

    test('RouterosCommandException carries trapMessage', () {
      const e = RouterosCommandException(
        message: 'command failed',
        trapMessage: 'no such item',
        category: '0',
      );
      expect(e, isA<RouterosException>());
      expect(e.trapMessage, equals('no such item'));
      expect(e.category, equals('0'));
      expect(e.isFatal, isFalse);
    });

    test('RouterosTimeoutException carries timeout duration', () {
      const duration = Duration(seconds: 3);
      const e = RouterosTimeoutException(
        message: 'timed out',
        timeout: duration,
      );
      expect(e, isA<RouterosException>());
      expect(e.timeout, equals(duration));
      expect(e.isFatal, isTrue);
    });

    test('RouterosRetryExhaustedException carries attempts and lastError', () {
      const last = RouterosConnectionException(message: 'connection failed');
      final e = RouterosRetryExhaustedException(
        message: 'all retries failed',
        attempts: 6,
        lastError: last,
      );
      expect(e, isA<RouterosException>());
      expect(e.attempts, equals(6));
      expect(e.lastError, same(last));
      expect(e.isFatal, isTrue);
    });

    test('RouterosNotConnectedException has default message', () {
      const e = RouterosNotConnectedException();
      expect(e, isA<RouterosException>());
      expect(e.message, isNotEmpty);
      expect(e.isFatal, isFalse);
    });

    test('toString does not expose credentials', () {
      const e = RouterosAuthException(
        message: 'Authentication failed',
        category: 'auth',
      );
      final str = e.toString();
      expect(str, contains('RouterosAuthException'));
      expect(str, isNot(contains('password')));
    });

    test('exceptions can be caught as RouterosException', () {
      void throwConn() =>
          throw const RouterosConnectionException(message: 'test');
      void throwAuth() => throw const RouterosAuthException(message: 'test');

      expect(throwConn, throwsA(isA<RouterosException>()));
      expect(throwAuth, throwsA(isA<RouterosException>()));
    });

    test('RouterosCommandException toString includes trap message', () {
      const e = RouterosCommandException(
        message: 'Command failed',
        trapMessage: 'permission denied',
      );
      expect(e.toString(), contains('permission denied'));
    });

    test('RouterosTimeoutException toString includes timeout seconds', () {
      const e = RouterosTimeoutException(
        message: 'Timed out',
        timeout: Duration(seconds: 5),
      );
      expect(e.toString(), contains('5'));
    });

    test('RouterosRetryExhaustedException toString includes attempts', () {
      const last = RouterosConnectionException(message: 'refused');
      final e = RouterosRetryExhaustedException(
        message: 'Exhausted',
        attempts: 3,
        lastError: last,
      );
      expect(e.toString(), contains('3'));
    });

    test('RouterosException with category shows it in toString', () {
      const e = RouterosConnectionException(
        message: 'Failed',
        category: 'network',
      );
      expect(e.toString(), contains('network'));
    });
  });
}
