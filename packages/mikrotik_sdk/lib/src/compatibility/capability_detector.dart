/// CapabilityDetector — connects to a RouterOS device and returns a RouterInfo.
///
/// Uses only the existing [MikrotikClient] public API.
/// No new dependencies. No caching — each call produces a fresh detection.
library;

import '../mikrotik_client.dart';
import 'router_info.dart';
import 'router_version.dart';

export 'router_info.dart';

/// Service that runs the minimum RouterOS API commands required to produce a
/// [RouterInfo] snapshot.
///
/// ## Command sequence
///
/// 1. Connect and authenticate via [MikrotikClient].
/// 2. `/system/identity/print`  → captures router identity name.
/// 3. `/system/resource/print`  → captures version, board, arch, memory, etc.
/// 4. Disconnect.
/// 5. Construct and return [RouterInfo].
///
/// ## Error propagation
///
/// | Condition                             | Behaviour                      |
/// |---------------------------------------|--------------------------------|
/// | Authentication fails                  | Propagates [RouterosAuthException] |
/// | Connection refused / unreachable      | Propagates [RouterosConnectionException] |
/// | Timeout                               | Propagates [RouterosTimeoutException] |
/// | `/system/resource/print` returns trap | Returns [RouterInfo] with [RouterVersion.unknown] |
/// | Any response field absent             | Uses field default (no throw)  |
///
/// ## Usage
///
/// ```dart
/// final detector = CapabilityDetector();
/// final info = await detector.detect(
///   credentials: MikrotikCredentials(
///     host: '192.168.1.1',
///     username: 'admin',
///     password: 'secret',
///   ),
/// );
/// print(info.version);   // e.g. RouterVersion(7.15.1)
/// print(info.isChr);     // true / false
/// ```
final class CapabilityDetector {
  /// Creates a [CapabilityDetector].
  ///
  /// [timeout] governs the per-connection attempt.  Defaults to 10 seconds.
  const CapabilityDetector({
    this.timeout = const Duration(seconds: 10),
  });

  /// Timeout applied to the detection connection.
  final Duration timeout;

  /// Connect to the router described by [credentials] and return a [RouterInfo].
  ///
  /// Throws [RouterosAuthException], [RouterosConnectionException], or
  /// [RouterosTimeoutException] on unrecoverable failures.
  ///
  /// A trap response from `/system/resource/print` is treated as a
  /// recoverable degradation — [RouterInfo] is returned with
  /// [RouterVersion.unknown] rather than throwing.
  Future<RouterInfo> detect({
    required MikrotikCredentials credentials,
  }) async {
    final client = MikrotikClient.fromCredentials(
      credentials,
      timeout: timeout,
      maxRetries: 0, // Detection is one-shot — caller handles retry policy.
    );

    final detectedAt = DateTime.now();

    try {
      await client.connect();

      // Step 1: identity.
      Map<String, String> identityMap = {};
      try {
        final identityResult = await client.command('/system/identity/print');
        if (identityResult.isNotEmpty) {
          identityMap = identityResult.first;
        }
      } on Exception {
        // Non-fatal — proceed with empty identity.
      }

      // Step 2: resource.
      Map<String, String> resourceMap = {};
      try {
        final resourceResult = await client.command('/system/resource/print');
        if (resourceResult.isNotEmpty) {
          resourceMap = resourceResult.first;
        }
      } on Exception {
        // Non-fatal — proceed with empty resource map (version → unknown).
      }

      return RouterInfo.fromApiMaps(
        identityMap: identityMap,
        resourceMap: resourceMap,
        detectedAt: detectedAt,
      );
    } finally {
      // Always disconnect, even on error.
      try {
        await client.disconnect();
      } on Exception {
        // Ignore disconnect errors during detection cleanup.
      }
    }
  }
}
