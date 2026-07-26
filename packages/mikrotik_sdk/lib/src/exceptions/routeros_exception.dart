/// RouterOS exception taxonomy for mikrotik_sdk.
///
/// All exceptions thrown by this SDK are typed subclasses of [RouterosException].
/// This enables downstream code to catch broad or narrow categories of failure.
library;

/// Base exception for all RouterOS errors produced by mikrotik_sdk.
///
/// All SDK exceptions extend this class, allowing callers to catch
/// [RouterosException] to handle any SDK error, or catch specific
/// subclasses for targeted handling.
sealed class RouterosException implements Exception {
  /// Human-readable error message. Never contains credentials.
  final String message;

  /// Optional RouterOS error category string (e.g. `"no such item"`).
  final String? category;

  /// Whether this error is fatal and the connection cannot continue.
  final bool isFatal;

  const RouterosException({
    required this.message,
    this.category,
    this.isFatal = false,
  });

  @override
  String toString() =>
      'RouterosException($runtimeType): $message'
      '${category != null ? " [category: $category]" : ""}';
}

/// Thrown when a TCP connection to the router cannot be established or is lost.
///
/// Examples:
/// - host unreachable
/// - connection refused on port 8728
/// - socket closed unexpectedly
final class RouterosConnectionException extends RouterosException {
  const RouterosConnectionException({
    required super.message,
    super.category,
    super.isFatal = true,
  });
}

/// Thrown when authentication fails.
///
/// Examples:
/// - wrong username or password
/// - MD5 challenge response rejected
/// - plain-text auth rejected on pre-v6.43 router
final class RouterosAuthException extends RouterosException {
  const RouterosAuthException({
    required super.message,
    super.category,
    super.isFatal = true,
  });
}

/// Thrown when a RouterOS command returns a `!trap` or `!fatal` response.
///
/// Examples:
/// - invalid command path
/// - insufficient permissions
/// - command parameter validation failure
final class RouterosCommandException extends RouterosException {
  /// The RouterOS trap message (e.g. `"no such item"`).
  final String trapMessage;

  const RouterosCommandException({
    required super.message,
    required this.trapMessage,
    super.category,
    super.isFatal = false,
  });

  @override
  String toString() =>
      'RouterosCommandException: $message [trap: $trapMessage]';
}

/// Thrown when a connect or command operation exceeds its timeout.
final class RouterosTimeoutException extends RouterosException {
  /// The duration that was exceeded.
  final Duration timeout;

  const RouterosTimeoutException({
    required super.message,
    required this.timeout,
    super.isFatal = true,
  });

  @override
  String toString() =>
      'RouterosTimeoutException: $message [timeout: ${timeout.inSeconds}s]';
}

/// Thrown when all retry attempts have been exhausted.
///
/// Wraps the last underlying exception that caused retries to fail.
final class RouterosRetryExhaustedException extends RouterosException {
  /// Number of attempts that were made before giving up.
  final int attempts;

  /// The last exception that triggered the final retry failure.
  final RouterosException lastError;

  RouterosRetryExhaustedException({
    required super.message,
    required this.attempts,
    required this.lastError,
    super.isFatal = true,
  });

  @override
  String toString() =>
      'RouterosRetryExhaustedException: $message '
      '[attempts: $attempts, last: ${lastError.runtimeType}]';
}

/// Thrown when an operation is attempted on a closed or disconnected client.
final class RouterosNotConnectedException extends RouterosException {
  const RouterosNotConnectedException({
    super.message = 'Not connected to router',
    super.isFatal = false,
  });
}
