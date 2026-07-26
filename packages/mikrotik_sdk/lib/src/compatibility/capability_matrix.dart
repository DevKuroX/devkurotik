/// CapabilityMatrix — static, immutable RouterOS version-to-capability table.
///
/// All methods are purely static.  No network calls, no mutable state.
/// Unknown or unsupported versions always produce safe defaults (never throw).
library;

import 'router_version.dart';

/// Immutable capability lookup table for RouterOS version ranges.
///
/// ## Version thresholds (per AMENDMENT_001 Section 4C)
///
/// | Version range  | Flag                  | Notes                          |
/// |----------------|-----------------------|--------------------------------|
/// | < 6.43         | requiresMd5Auth       | MD5 challenge-response         |
/// | ≥ 6.43         | supportsPlainAuth     | Plain-text credential login    |
/// | ≥ 6.0          | supportsHotspot       | Hotspot API available          |
/// | ≥ 6.0          | supportsPppoe         | PPPoE secrets API available    |
/// | ≥ 6.49         | supportsApiSsl        | Port 8729 TLS confirmed stable |
/// | 7.x CHR        | routerboardTrap       | /system/routerboard returns !trap |
///
/// ## Usage
///
/// ```dart
/// final v = RouterVersion.parse('7.15.1 (stable)');
/// print(CapabilityMatrix.supportsPlainAuth(v)); // true
/// print(CapabilityMatrix.requiresMd5Auth(v));   // false
/// ```
abstract final class CapabilityMatrix {
  CapabilityMatrix._();

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// True if [v] supports plain-text API authentication (≥ v6.43).
  static bool supportsPlainAuth(RouterVersion v) => v.supportsPlainAuth();

  /// True if [v] requires MD5 challenge-response authentication (< v6.43).
  static bool requiresMd5Auth(RouterVersion v) => v.requiresMd5Auth();

  // ---------------------------------------------------------------------------
  // Feature availability
  // ---------------------------------------------------------------------------

  /// True if the Hotspot API (`/ip/hotspot/...`) is available.
  ///
  /// Hotspot module has been present since RouterOS v6.0.
  /// Returns false only for [RouterVersion.unknown].
  static bool supportsHotspot(RouterVersion v) {
    if (v.isUnknown) return false;
    return v.isAtLeast(6, 0);
  }

  /// True if the PPPoE secrets API (`/ppp/secret/...`) is available.
  ///
  /// PPPoE has been present since RouterOS v6.0.
  /// Returns false only for [RouterVersion.unknown].
  static bool supportsPppoe(RouterVersion v) {
    if (v.isUnknown) return false;
    return v.isAtLeast(6, 0);
  }

  /// True if the SSL API port (8729) is reliably available.
  ///
  /// API SSL support was confirmed stable from v6.49 onward.
  /// Returns false for unknown versions and anything below v6.49.
  static bool supportsApiSsl(RouterVersion v) {
    if (v.isUnknown) return false;
    return v.isAtLeast(6, 49);
  }

  // ---------------------------------------------------------------------------
  // Known variance / warnings
  // ---------------------------------------------------------------------------

  /// True if this version has a known behavioural variance that callers
  /// should be aware of.
  ///
  /// A variance does not mean the router is unsupported — it means callers
  /// may need to handle an edge-case.  Returns false by default for all
  /// versions that have no documented variance.
  static bool hasKnownVariance(RouterVersion v) =>
      varianceNote(v) != null;

  /// Returns a human-readable description of any known variance for [v], or
  /// `null` if no variance is documented.
  ///
  /// Never throws — unknown versions return `null`.
  static String? varianceNote(RouterVersion v) {
    if (v.isUnknown) return null;

    // CHR / v7.x: /system/routerboard returns !trap (no physical board).
    if (v.isAtLeast(7, 0)) {
      // Only a variance note for the routerboard command — not an error.
      // All other v7 behaviour is standard.
      return null; // No actionable variance for callers above v7.0.
    }

    // Pre-v6.43: MD5 challenge-response required — callers must be aware.
    if (v.requiresMd5Auth()) {
      return 'RouterOS ${v.raw} uses MD5 challenge-response authentication '
          '(pre-v6.43). Ensure mikrotik_sdk MD5 auth path is exercised.';
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // Convenience: full summary for a version
  // ---------------------------------------------------------------------------

  /// Returns a capability summary map for [v].
  ///
  /// Useful for logging / diagnostics.  Never throws.
  static Map<String, Object> summary(RouterVersion v) => {
        'version': v.raw,
        'supportsPlainAuth': supportsPlainAuth(v),
        'requiresMd5Auth': requiresMd5Auth(v),
        'supportsHotspot': supportsHotspot(v),
        'supportsPppoe': supportsPppoe(v),
        'supportsApiSsl': supportsApiSsl(v),
        'hasKnownVariance': hasKnownVariance(v),
        'varianceNote': varianceNote(v) ?? '',
      };
}
