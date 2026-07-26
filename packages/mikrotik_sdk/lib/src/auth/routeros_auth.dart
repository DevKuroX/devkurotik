/// RouterOS authentication logic.
///
/// Implements two authentication modes:
///
/// ## Post-v6.43 (plain text login)
/// Introduced in RouterOS 6.43. Login is performed by sending:
/// ```
/// /login
/// =name=<username>
/// =password=<password>
/// ```
/// The router returns `!done` on success, `!trap` on failure.
///
/// ## Pre-v6.43 (MD5 challenge-response)
/// Used by RouterOS versions before 6.43. Login flow:
/// 1. Send `/login` with no credentials → router returns `=ret=<challenge_hex>`
/// 2. Compute MD5 response: `MD5(\x00 + password + unhex(challenge))`
/// 3. Send `/login =name=<user> =response=00<md5_hex>`
///
/// ## Auto-detection
/// [RouterosAuth] first attempts the post-v6.43 plain login. If the router
/// returns a challenge (`=ret=` in `!done`), it falls back to the pre-v6.43
/// MD5 challenge flow automatically.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../exceptions/routeros_exception.dart';
import '../logging/mikrotik_logger.dart';
import '../protocol/routeros_protocol.dart';

/// Handles RouterOS API authentication.
///
/// Stateless — accepts a [sendAndReceive] callback so it can be used
/// with any underlying transport.
final class RouterosAuth {
  RouterosAuth._();

  /// Authenticates against a RouterOS API session.
  ///
  /// [sendAndReceive] must send a sentence and return the response sentences.
  ///
  /// Automatically detects the RouterOS version and selects the correct auth mode:
  /// - post-v6.43: plain password
  /// - pre-v6.43: MD5 challenge-response
  ///
  /// Throws [RouterosAuthException] on authentication failure.
  static Future<void> login({
    required String username,
    required String password,
    required Future<List<RouterosSentence>> Function(List<String> sentence)
    sendAndReceive,
  }) async {
    MikrotikLogger.logAuth('Attempting login for username=$username');

    // Attempt post-v6.43 plain login
    final response = await sendAndReceive([
      '/login',
      '=name=$username',
      '=password=$password',
    ]);

    for (final sentence in response) {
      if (sentence.isDone) {
        // Check if router returned a challenge (pre-v6.43 mode)
        final challenge = sentence.getAttribute('ret');
        if (challenge != null && challenge.isNotEmpty) {
          MikrotikLogger.logAuth(
            'Router returned challenge — using pre-v6.43 MD5 auth',
          );
          await _md5ChallengeLogin(
            username: username,
            password: password,
            challenge: challenge,
            sendAndReceive: sendAndReceive,
          );
          return;
        }
        // No challenge — post-v6.43 plain login succeeded
        MikrotikLogger.logAuth('Login successful (post-v6.43 plain)');
        return;
      }

      if (sentence.isTrap || sentence.isFatal) {
        final msg = sentence.getAttribute('message') ?? 'Authentication failed';
        MikrotikLogger.logError('Login failed: $msg');
        throw RouterosAuthException(
          message: 'Authentication failed: $msg',
          category: sentence.getAttribute('category'),
        );
      }
    }

    throw RouterosAuthException(
      message: 'Authentication failed: unexpected response',
    );
  }

  /// Performs pre-v6.43 MD5 challenge-response authentication.
  static Future<void> _md5ChallengeLogin({
    required String username,
    required String password,
    required String challenge,
    required Future<List<RouterosSentence>> Function(List<String> sentence)
    sendAndReceive,
  }) async {
    final responseHex = _computeMd5Response(password, challenge);

    final response = await sendAndReceive([
      '/login',
      '=name=$username',
      '=response=00$responseHex',
    ]);

    for (final sentence in response) {
      if (sentence.isDone) {
        MikrotikLogger.logAuth('Login successful (pre-v6.43 MD5)');
        return;
      }
      if (sentence.isTrap || sentence.isFatal) {
        final msg = sentence.getAttribute('message') ?? 'Authentication failed';
        MikrotikLogger.logError('MD5 login failed: $msg');
        throw RouterosAuthException(
          message: 'Authentication failed (MD5): $msg',
          category: sentence.getAttribute('category'),
        );
      }
    }

    throw RouterosAuthException(
      message: 'Authentication failed (MD5): unexpected response',
    );
  }

  /// Computes the MD5 challenge response.
  ///
  /// Formula: `MD5(\x00 + password_utf8 + unhex(challenge))`
  ///
  /// Returns the lowercase hex string of the MD5 digest.
  static String _computeMd5Response(String password, String challenge) {
    final passwordBytes = utf8.encode(password);
    final challengeBytes = _unhex(challenge);

    final input = Uint8List(1 + passwordBytes.length + challengeBytes.length);
    input[0] = 0x00;
    input.setRange(1, 1 + passwordBytes.length, passwordBytes);
    input.setRange(1 + passwordBytes.length, input.length, challengeBytes);

    final digest = md5.convert(input);
    return digest.toString(); // lowercase hex
  }

  /// Converts a hex string to bytes.
  static Uint8List _unhex(String hex) {
    if (hex.length.isOdd) {
      throw ArgumentError('Hex string must have even length: $hex');
    }
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  /// Exposes [_computeMd5Response] for testing purposes only.
  ///
  /// Not part of the public API.
  static String computeMd5ResponseForTest(String password, String challenge) =>
      _computeMd5Response(password, challenge);
}
