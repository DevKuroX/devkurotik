/// MikroTik RouterOS API connection implementation.
///
/// Manages a single TCP connection to a RouterOS device and exposes
/// the authenticated command execution API.
///
/// ## Lifecycle
/// ```
/// disconnected → connecting → connected → (lost | disconnecting → disconnected)
/// ```
///
/// ## Thread Safety
/// This class is NOT thread-safe. All operations on a given [MikrotikConnection]
/// instance must be performed from the same Dart isolate.
// ignore_for_file: prefer_initializing_formals
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../auth/routeros_auth.dart';
import '../exceptions/routeros_exception.dart';
import '../logging/mikrotik_logger.dart';
import '../protocol/routeros_protocol.dart';
import '../utils/mikrotik_credentials.dart';
import 'connection_state.dart';
import 'retry_policy.dart';

/// A single TCP connection to a RouterOS API endpoint.
///
/// Handles connection, authentication, command I/O, and graceful disconnection.
final class MikrotikConnection {
  final MikrotikCredentials _credentials;
  final RetryConfig _retryConfig;
  final Duration _connectTimeout;

  Socket? _socket;
  ConnectionState _state = ConnectionState.disconnected;

  // Read buffer — accumulates bytes until complete sentences can be parsed
  final _readBuffer = <int>[];

  // Pending response completer — resolves when a complete !done or !trap is received
  Completer<List<RouterosSentence>>? _pendingResponse;

  MikrotikConnection({
    required MikrotikCredentials credentials,
    RetryConfig retryConfig = RetryConfig.defaultConfig,
    Duration connectTimeout = const Duration(seconds: 3),
  }) : _credentials = credentials,
       _retryConfig = retryConfig,
       _connectTimeout = connectTimeout;

  // ─── State ─────────────────────────────────────────────────────────────────

  /// The current connection state.
  ConnectionState get state => _state;

  /// Whether the connection is established and authenticated.
  bool get isConnected => _state == ConnectionState.connected;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Establishes a TCP connection and authenticates with RouterOS.
  ///
  /// Applies retry logic per [_retryConfig].
  ///
  /// Throws [RouterosConnectionException] if the connection cannot be established.
  /// Throws [RouterosAuthException] if authentication fails.
  /// Throws [RouterosRetryExhaustedException] if all retry attempts fail.
  Future<void> connect() async {
    if (_state == ConnectionState.connected) return;
    if (_state == ConnectionState.connecting) {
      throw RouterosConnectionException(
        message: 'Connection attempt already in progress',
      );
    }

    _state = ConnectionState.connecting;
    MikrotikLogger.logConnection(
      'Connecting to ${_credentials.host}:${_credentials.port}',
    );

    await withRetry(
      _doConnect,
      config: _retryConfig,
      connectTimeout: _connectTimeout,
      operationName: 'connect to ${_credentials.host}',
    );
  }

  Future<void> _doConnect() async {
    try {
      _socket = await Socket.connect(
        _credentials.host,
        _credentials.port,
        timeout: _connectTimeout,
      );
    } on SocketException catch (e) {
      _state = ConnectionState.disconnected;
      throw RouterosConnectionException(
        message:
            'Failed to connect to ${_credentials.host}:${_credentials.port}: ${e.message}',
      );
    } on TimeoutException {
      _state = ConnectionState.disconnected;
      throw RouterosTimeoutException(
        message: 'Connection timed out after ${_connectTimeout.inSeconds}s',
        timeout: _connectTimeout,
      );
    }

    // Set up socket listener
    _socket!.listen(
      _onData,
      onError: _onSocketError,
      onDone: _onSocketDone,
      cancelOnError: false,
    );

    // Authenticate
    try {
      await RouterosAuth.login(
        username: _credentials.username,
        password: _credentials.password,
        sendAndReceive: _sendSentenceAndReceive,
      );
    } catch (e) {
      await _closeSocket();
      _state = ConnectionState.disconnected;
      rethrow;
    }

    _state = ConnectionState.connected;
    MikrotikLogger.logConnection(
      'Connected and authenticated to ${_credentials.host}',
    );
  }

  /// Sends a graceful disconnect to the router and closes the TCP socket.
  Future<void> disconnect() async {
    if (_state == ConnectionState.disconnected) return;

    _state = ConnectionState.disconnecting;
    MikrotikLogger.logConnection('Disconnecting from ${_credentials.host}');

    try {
      // Attempt graceful /quit (router closes connection after this)
      if (_socket != null) {
        try {
          _socket!.add(encodeSentence(['/quit']));
          await _socket!.flush();
        } catch (_) {
          // Ignore errors during graceful quit
        }
      }
    } finally {
      await _closeSocket();
      _state = ConnectionState.disconnected;
      MikrotikLogger.logConnection('Disconnected from ${_credentials.host}');
    }
  }

  /// Sends a RouterOS command and returns all response rows.
  ///
  /// Returns a list of attribute maps from `!re` sentences.
  /// Throws [RouterosCommandException] if the router returns `!trap`.
  /// Throws [RouterosNotConnectedException] if not connected.
  Future<List<Map<String, String>>> command(
    String path, {
    Map<String, String> query = const {},
    Map<String, String> params = const {},
    bool countOnly = false,
    List<String>? proplist,
  }) async {
    if (!isConnected) {
      throw const RouterosNotConnectedException();
    }

    final words = _buildCommandWords(
      path,
      query: query,
      params: params,
      countOnly: countOnly,
      proplist: proplist,
    );

    MikrotikLogger.logCommand(
      'Sending command: $path (${words.length - 1} args)',
    );

    final sentences = await _sendSentenceAndReceive(words);
    return _parseCommandResponse(sentences);
  }

  /// Sends a fire-and-forget RouterOS command (no response expected).
  ///
  /// Used for commands like `/system/reboot`, `/system/shutdown`.
  Future<void> execute(String path) async {
    if (!isConnected) {
      throw const RouterosNotConnectedException();
    }

    MikrotikLogger.logCommand('Executing: $path');
    _socket!.add(encodeSentence([path]));
    await _socket!.flush();
  }

  // ─── Internal I/O ──────────────────────────────────────────────────────────

  void _onData(List<int> data) {
    _readBuffer.addAll(data);
    _tryParseResponses();
  }

  void _onSocketError(Object error, StackTrace stack) {
    MikrotikLogger.logError('Socket error: $error', error, stack);
    _state = ConnectionState.lost;
    _pendingResponse?.completeError(
      RouterosConnectionException(message: 'Socket error: $error'),
    );
    _pendingResponse = null;
  }

  void _onSocketDone() {
    if (_state == ConnectionState.disconnecting) return;
    MikrotikLogger.logConnection('Socket closed by remote');
    _state = ConnectionState.lost;
    _pendingResponse?.completeError(
      const RouterosConnectionException(message: 'Socket closed by remote'),
    );
    _pendingResponse = null;
  }

  void _tryParseResponses() {
    final bytes = Uint8List.fromList(_readBuffer);
    final sentences = parseSentences(bytes);

    if (sentences.isEmpty) return;

    // Check if we have a terminal sentence (!done, !trap, !fatal)
    final hasDone = sentences.any((s) => s.isDone || s.isTrap || s.isFatal);
    if (!hasDone) return; // Need more data

    // We have a complete response
    _readBuffer.clear();
    _pendingResponse?.complete(sentences);
    _pendingResponse = null;
  }

  Future<List<RouterosSentence>> _sendSentenceAndReceive(
    List<String> words,
  ) async {
    if (_socket == null) {
      throw const RouterosConnectionException(
        message: 'Socket not initialized',
      );
    }

    final completer = Completer<List<RouterosSentence>>();
    _pendingResponse = completer;

    // Log command words with redaction
    MikrotikLogger.logProtocol('TX: ${MikrotikLogger.redactWords(words)}');

    _socket!.add(encodeSentence(words));
    await _socket!.flush();

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pendingResponse = null;
        throw RouterosTimeoutException(
          message: 'Command response timed out',
          timeout: const Duration(seconds: 10),
        );
      },
    );
  }

  List<Map<String, String>> _parseCommandResponse(
    List<RouterosSentence> sentences,
  ) {
    final results = <Map<String, String>>[];

    for (final sentence in sentences) {
      if (sentence.isRe) {
        results.add(sentence.toMap());
      } else if (sentence.isTrap || sentence.isFatal) {
        final trapMsg = sentence.getAttribute('message') ?? 'Unknown error';
        throw RouterosCommandException(
          message: 'RouterOS command failed: $trapMsg',
          trapMessage: trapMsg,
          category: sentence.getAttribute('category'),
        );
      }
      // !done is ignored — signals end of response, no payload
    }

    return results;
  }

  List<String> _buildCommandWords(
    String path, {
    required Map<String, String> query,
    required Map<String, String> params,
    required bool countOnly,
    List<String>? proplist,
  }) {
    final words = <String>[path];

    for (final entry in query.entries) {
      words.add('?${entry.key}=${entry.value}');
    }

    for (final entry in params.entries) {
      words.add('=${entry.key}=${entry.value}');
    }

    if (countOnly) {
      words.add('=count-only=');
    }

    if (proplist != null && proplist.isNotEmpty) {
      words.add('=.proplist=${proplist.join(',')}');
    }

    return words;
  }

  Future<void> _closeSocket() async {
    try {
      await _socket?.close();
    } catch (_) {
      // Ignore close errors
    } finally {
      _socket = null;
    }
  }
}
