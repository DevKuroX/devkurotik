/// Secret-safe logging for mikrotik_sdk.
///
/// All log output from this SDK is routed through [MikrotikLogger], which
/// applies credential redaction before any message reaches a log sink.
///
/// ## Redaction Rules
///
/// The following patterns are always redacted:
/// - `=password=<value>` → `=password=***`
/// - `password` query/attribute values in any form
/// - MD5 challenge response bytes (hex strings in auth context)
/// - Any word explicitly tagged as containing a secret
///
/// ## Usage
///
/// Consumers of the SDK can configure the underlying [Logger] from the
/// `logging` package to attach their own [LogRecord] handler. The SDK
/// logs under the `mikrotik_sdk` logger namespace.
///
/// ```dart
/// Logger.root.onRecord.listen((record) {
///   debugPrint('[${record.level.name}] ${record.message}');
/// });
/// ```
library;

import 'package:logging/logging.dart';

/// Logger for the mikrotik_sdk package.
///
/// All internal SDK logging is routed through this class.
/// Credentials and secrets are redacted before emission.
final class MikrotikLogger {
  static final Logger _logger = Logger('mikrotik_sdk');

  /// Log level for connection events (connect, disconnect, reconnect).
  static const Level connection = Level.INFO;

  /// Log level for authentication events (auth attempt, success).
  static const Level auth = Level.FINE;

  /// Log level for command execution events.
  static const Level command = Level.FINER;

  /// Log level for protocol framing (low-level bytes). Use only in debug.
  static const Level protocol = Level.FINEST;

  // ─── Public logging methods ────────────────────────────────────────────────

  /// Log a connection-level event.
  static void logConnection(String message) =>
      _logger.log(connection, _redact(message));

  /// Log an authentication event. Always redacts the message.
  static void logAuth(String message) => _logger.log(auth, _redact(message));

  /// Log a command execution event.
  static void logCommand(String message) =>
      _logger.log(command, _redact(message));

  /// Log a protocol-level event (framing, bytes).
  static void logProtocol(String message) =>
      _logger.log(protocol, _redact(message));

  /// Log an error. Redacts the message.
  static void logError(String message, [Object? error, StackTrace? stack]) =>
      _logger.warning(_redact(message), error, stack);

  /// Log a warning. Redacts the message.
  static void logWarning(String message) => _logger.warning(_redact(message));

  // ─── Internal redaction ────────────────────────────────────────────────────

  /// Applies credential redaction to [message].
  ///
  /// Patterns redacted:
  /// - `=password=<anything>` → `=password=***`
  /// - `password=<anything>` → `password=***`
  /// - Any word starting with `=password` → `=password=***`
  /// - Hex strings in auth context (challenge patterns)
  static String _redact(String message) {
    var result = message;

    // Redact RouterOS attribute: =password=VALUE
    result = result.replaceAllMapped(
      RegExp(r'(=password=)[^\s,\]]+', caseSensitive: false),
      (m) => '${m.group(1)}***',
    );

    // Redact query parameter: password=VALUE
    result = result.replaceAllMapped(
      RegExp(r'(password=)[^\s,\]&]+', caseSensitive: false),
      (m) => '${m.group(1)}***',
    );

    // Redact MD5 challenge response (00 prefix + 32 hex chars)
    result = result.replaceAllMapped(
      RegExp(r'\\x00[0-9a-fA-F]{32}'),
      (_) => '***md5-response***',
    );

    // Redact plain 32-char hex strings that look like MD5 digests in auth context
    // Only when labelled with auth-related context words
    result = result.replaceAllMapped(
      RegExp(
        r'(response|digest|challenge|hash|md5)[=:\s]+([0-9a-fA-F]{32,64})',
        caseSensitive: false,
      ),
      (m) => '${m.group(1)}=***',
    );

    return result;
  }

  /// Redacts a RouterOS API word if it contains sensitive data.
  ///
  /// Use this when logging individual API words to ensure secrets
  /// are not emitted in protocol-level logs.
  static String redactWord(String word) {
    if (word.startsWith('=password=') || word.startsWith('=.password=')) {
      return '=password=***';
    }
    return _redact(word);
  }

  /// Redacts a list of RouterOS API words for safe logging.
  static List<String> redactWords(List<String> words) =>
      words.map(redactWord).toList();
}
