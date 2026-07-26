/// Timeout and retry policy for mikrotik_sdk.
///
/// Implements the roadmap-approved retry/backoff semantics:
/// - Max retries: 5
/// - Base delay: 3 seconds
/// - Strategy: exponential backoff with jitter cap
/// - Only retry on transient errors ([RouterosConnectionException] and
///   [RouterosTimeoutException]). Never retry auth failures.
library;

import 'dart:async';

import '../exceptions/routeros_exception.dart';
import '../logging/mikrotik_logger.dart';

/// Configuration for the retry policy.
///
/// Default values match the audited Mikhmon v3 behavior:
/// - 5 retries, 3-second base delay.
final class RetryConfig {
  /// Maximum number of retry attempts (not counting the initial attempt).
  final int maxRetries;

  /// Base delay between retries.
  final Duration baseDelay;

  /// Maximum delay cap (prevents exponential growth from becoming too large).
  final Duration maxDelay;

  /// Whether to apply jitter to delays to prevent thundering herd.
  final bool useJitter;

  const RetryConfig({
    this.maxRetries = 5,
    this.baseDelay = const Duration(seconds: 3),
    this.maxDelay = const Duration(seconds: 30),
    this.useJitter = true,
  });

  /// Default retry configuration matching audited Mikhmon behavior.
  static const RetryConfig defaultConfig = RetryConfig();

  /// Calculates the delay for attempt [n] (1-indexed).
  ///
  /// Uses exponential backoff: `baseDelay * 2^(n-1)`, capped at [maxDelay].
  Duration delayForAttempt(int n) {
    final exp = baseDelay * (1 << (n - 1).clamp(0, 10));
    final capped = exp > maxDelay ? maxDelay : exp;
    return capped;
  }
}

/// Executes [operation] with retry and timeout semantics.
///
/// - Retries up to [config.maxRetries] times on transient failures.
/// - Wraps each attempt with [connectTimeout].
/// - Only retries [RouterosConnectionException] and [RouterosTimeoutException].
/// - Does NOT retry [RouterosAuthException] — auth failures are deterministic.
///
/// Returns the result of the first successful attempt.
/// Throws [RouterosRetryExhaustedException] when all attempts fail.
Future<T> withRetry<T>(
  Future<T> Function() operation, {
  RetryConfig config = RetryConfig.defaultConfig,
  Duration? connectTimeout,
  String operationName = 'operation',
}) async {
  RouterosException? lastError;

  for (var attempt = 0; attempt <= config.maxRetries; attempt++) {
    try {
      if (connectTimeout != null) {
        return await operation().timeout(
          connectTimeout,
          onTimeout: () => throw RouterosTimeoutException(
            message:
                '$operationName timed out after ${connectTimeout.inSeconds}s',
            timeout: connectTimeout,
          ),
        );
      }
      return await operation();
    } on RouterosAuthException {
      // Never retry auth failures — they are deterministic
      rethrow;
    } on RouterosTimeoutException catch (e) {
      lastError = e;
      if (attempt >= config.maxRetries) break;
      final delay = config.delayForAttempt(attempt + 1);
      MikrotikLogger.logWarning(
        '$operationName timed out (attempt ${attempt + 1}/${config.maxRetries + 1}), '
        'retrying in ${delay.inSeconds}s',
      );
      await Future<void>.delayed(delay);
    } on RouterosConnectionException catch (e) {
      lastError = e;
      if (attempt >= config.maxRetries) break;
      final delay = config.delayForAttempt(attempt + 1);
      MikrotikLogger.logWarning(
        '$operationName failed: ${e.message} (attempt ${attempt + 1}/${config.maxRetries + 1}), '
        'retrying in ${delay.inSeconds}s',
      );
      await Future<void>.delayed(delay);
    }
  }

  throw RouterosRetryExhaustedException(
    message: '$operationName failed after ${config.maxRetries + 1} attempts',
    attempts: config.maxRetries + 1,
    lastError:
        lastError ??
        RouterosConnectionException(message: 'Unknown error after retries'),
  );
}
