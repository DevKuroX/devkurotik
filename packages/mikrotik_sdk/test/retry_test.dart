import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('RetryConfig', () {
    test('default config has 5 retries and 3s base delay', () {
      const config = RetryConfig.defaultConfig;
      expect(config.maxRetries, equals(5));
      expect(config.baseDelay, equals(const Duration(seconds: 3)));
    });

    test('delayForAttempt(1) returns base delay', () {
      const config = RetryConfig(baseDelay: Duration(seconds: 3));
      expect(config.delayForAttempt(1), equals(const Duration(seconds: 3)));
    });

    test('delayForAttempt(2) returns 2x base delay', () {
      const config = RetryConfig(baseDelay: Duration(seconds: 3));
      expect(config.delayForAttempt(2), equals(const Duration(seconds: 6)));
    });

    test('delayForAttempt(3) returns 4x base delay', () {
      const config = RetryConfig(baseDelay: Duration(seconds: 3));
      expect(config.delayForAttempt(3), equals(const Duration(seconds: 12)));
    });

    test('delay is capped at maxDelay', () {
      const config = RetryConfig(
        baseDelay: Duration(seconds: 3),
        maxDelay: Duration(seconds: 10),
      );
      // attempt 4 would be 3 * 2^3 = 24s, but capped at 10s
      expect(config.delayForAttempt(4), equals(const Duration(seconds: 10)));
    });
  });

  group('withRetry', () {
    test('returns result on first successful attempt', () async {
      var calls = 0;
      final result = await withRetry(() async {
        calls++;
        return 'ok';
      });
      expect(result, equals('ok'));
      expect(calls, equals(1));
    });

    test('retries on RouterosConnectionException', () async {
      var calls = 0;
      final config = RetryConfig(maxRetries: 2, baseDelay: Duration.zero);
      final result = await withRetry(() async {
        calls++;
        if (calls < 3) {
          throw const RouterosConnectionException(message: 'refused');
        }
        return 'success';
      }, config: config);
      expect(result, equals('success'));
      expect(calls, equals(3));
    });

    test('retries on RouterosTimeoutException', () async {
      var calls = 0;
      final config = RetryConfig(maxRetries: 1, baseDelay: Duration.zero);
      final result = await withRetry(() async {
        calls++;
        if (calls == 1) {
          throw const RouterosTimeoutException(
            message: 'timed out',
            timeout: Duration(seconds: 3),
          );
        }
        return 'recovered';
      }, config: config);
      expect(result, equals('recovered'));
      expect(calls, equals(2));
    });

    test('does NOT retry RouterosAuthException', () async {
      var calls = 0;
      final config = RetryConfig(maxRetries: 3, baseDelay: Duration.zero);
      await expectLater(
        withRetry(() async {
          calls++;
          throw const RouterosAuthException(message: 'wrong password');
        }, config: config),
        throwsA(isA<RouterosAuthException>()),
      );
      expect(calls, equals(1), reason: 'auth errors must not be retried');
    });

    test(
      'throws RouterosRetryExhaustedException when all retries fail',
      () async {
        final config = RetryConfig(maxRetries: 2, baseDelay: Duration.zero);
        await expectLater(
          withRetry(() async {
            throw const RouterosConnectionException(message: 'refused');
          }, config: config),
          throwsA(isA<RouterosRetryExhaustedException>()),
        );
      },
    );

    test('retry exhausted exception contains attempt count', () async {
      final config = RetryConfig(maxRetries: 2, baseDelay: Duration.zero);
      await expectLater(
        withRetry(() async {
          throw const RouterosConnectionException(message: 'refused');
        }, config: config),
        throwsA(
          predicate<RouterosRetryExhaustedException>((e) {
            expect(e.attempts, equals(3)); // initial + 2 retries
            expect(e.lastError, isA<RouterosConnectionException>());
            return true;
          }),
        ),
      );
    });
  });
}
