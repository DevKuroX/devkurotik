/// RouterInfo — identity snapshot of a connected RouterOS device.
///
/// Constructed by [CapabilityDetector] from live API responses.
/// All fields degrade gracefully if the corresponding API key is absent.
/// Never stores or exposes router credentials.
library;

import 'router_version.dart';

/// Immutable identity snapshot of a RouterOS device captured at detection time.
///
/// Fields are sourced from two RouterOS API commands:
/// - `/system/identity/print`  → [identity]
/// - `/system/resource/print`  → all remaining fields
///
/// All fields have safe defaults — construction never throws on missing data.
final class RouterInfo {
  const RouterInfo({
    required this.identity,
    required this.version,
    required this.board,
    required this.architecture,
    required this.cpuCount,
    required this.totalMemoryBytes,
    required this.platform,
    required this.detectedAt,
  });

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Router identity name (`/system/identity → name`).
  ///
  /// Defaults to empty string if the command returns no `name` key.
  final String identity;

  /// Parsed RouterOS firmware version.
  ///
  /// Defaults to [RouterVersion.unknown] if the version field is absent or
  /// unparseable.
  final RouterVersion version;

  /// Hardware board name (`/system/resource → board-name`).
  ///
  /// Value `"CHR"` indicates a Cloud Hosted Router.
  /// Defaults to empty string.
  final String board;

  /// CPU architecture (`/system/resource → architecture-name`).
  ///
  /// Example values: `"x86_64"`, `"arm"`, `"mipsbe"`, `"tile"`.
  /// Defaults to empty string.
  final String architecture;

  /// Number of CPUs (`/system/resource → cpu-count`).
  ///
  /// Defaults to 0 if absent.
  final int cpuCount;

  /// Total RAM in bytes (`/system/resource → total-memory`).
  ///
  /// Defaults to 0 if absent.
  final int totalMemoryBytes;

  /// Platform name (`/system/resource → platform`).
  ///
  /// Typically `"MikroTik"`.  Defaults to empty string.
  final String platform;

  /// Wall-clock time when this snapshot was captured.
  final DateTime detectedAt;

  // ---------------------------------------------------------------------------
  // Derived properties (no extra API calls)
  // ---------------------------------------------------------------------------

  /// True if this router is a Cloud Hosted Router (CHR).
  ///
  /// Detection: `board` starts with `"CHR"` (case-insensitive).
  ///
  /// Real CHR v7 on AWS returns `"CHR Amazon EC2 t3.small"` — so prefix
  /// matching is used rather than exact equality.
  bool get isChr => board.toUpperCase().startsWith('CHR');

  /// True if this router is running on virtualised / x86 hardware.
  ///
  /// Detection: [isChr] OR [architecture] contains "x86".
  bool get isVirtual =>
      isChr || architecture.toLowerCase().contains('x86');

  // ---------------------------------------------------------------------------
  // Factory: safe construction from raw API response maps
  // ---------------------------------------------------------------------------

  /// Build a [RouterInfo] from the raw response maps returned by the API.
  ///
  /// - [identityMap]  — first entry of `/system/identity/print`
  /// - [resourceMap]  — first entry of `/system/resource/print`
  /// - [detectedAt]   — wall clock at time of detection
  ///
  /// Missing keys produce field defaults — never throws.
  factory RouterInfo.fromApiMaps({
    required Map<String, String> identityMap,
    required Map<String, String> resourceMap,
    required DateTime detectedAt,
  }) {
    final rawVersion = resourceMap['version'] ?? '';
    final cpuStr = resourceMap['cpu-count'] ?? '0';
    final memStr = resourceMap['total-memory'] ?? '0';

    return RouterInfo(
      identity: identityMap['name'] ?? '',
      version: rawVersion.isNotEmpty
          ? RouterVersion.parse(rawVersion)
          : RouterVersion.unknown,
      board: resourceMap['board-name'] ?? '',
      architecture: resourceMap['architecture-name'] ?? '',
      cpuCount: int.tryParse(cpuStr) ?? 0,
      totalMemoryBytes: int.tryParse(memStr) ?? 0,
      platform: resourceMap['platform'] ?? '',
      detectedAt: detectedAt,
    );
  }

  // ---------------------------------------------------------------------------
  // Object overrides
  // ---------------------------------------------------------------------------

  @override
  String toString() =>
      'RouterInfo(identity: $identity, version: $version, '
      'board: $board, isChr: $isChr, arch: $architecture)';
}
