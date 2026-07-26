/// RouterVersion — parsed, comparable RouterOS version value object.
///
/// Parses version strings produced by `/system/resource/print` → `version`
/// field.  Examples:
///   "7.15.1 (stable)"  → major=7, minor=15, patch=1, channel="stable"
///   "6.49.10"          → major=6, minor=49, patch=10, channel=""
///   "6.43"             → major=6, minor=43, patch=0,  channel=""
///
/// Malformed or absent version strings degrade to [RouterVersion.unknown]
/// without throwing.
library;

/// A parsed, comparable RouterOS firmware version.
final class RouterVersion implements Comparable<RouterVersion> {
  const RouterVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.channel,
    required this.raw,
  });

  // ---------------------------------------------------------------------------
  // Well-known sentinel
  // ---------------------------------------------------------------------------

  /// Sentinel value used when the version string is absent or unparseable.
  static const RouterVersion unknown = RouterVersion(
    major: 0,
    minor: 0,
    patch: 0,
    channel: 'unknown',
    raw: 'unknown',
  );

  // ---------------------------------------------------------------------------
  // Fields
  // ---------------------------------------------------------------------------

  /// Major version component (e.g. 7 in "7.15.1").
  final int major;

  /// Minor version component (e.g. 15 in "7.15.1").
  final int minor;

  /// Patch version component (e.g. 1 in "7.15.1"; 0 if absent).
  final int patch;

  /// Release channel extracted from the parenthesised suffix.
  ///
  /// Known values: "stable", "long-term", "testing", "development", "".
  final String channel;

  /// Original raw version string as returned by RouterOS, e.g. "7.15.1 (stable)".
  final String raw;

  // ---------------------------------------------------------------------------
  // Factory / parser
  // ---------------------------------------------------------------------------

  /// Parse a RouterOS version string.
  ///
  /// Returns [RouterVersion.unknown] for any input that cannot be parsed.
  factory RouterVersion.parse(String raw) {
    if (raw.isEmpty) return RouterVersion.unknown;

    var work = raw.trim();
    var channel = '';

    // Extract parenthesised channel suffix, e.g. " (stable)".
    final parenStart = work.indexOf('(');
    if (parenStart != -1) {
      final parenEnd = work.indexOf(')', parenStart);
      if (parenEnd != -1) {
        channel = work.substring(parenStart + 1, parenEnd).trim();
      }
      work = work.substring(0, parenStart).trim();
    }

    final parts = work.split('.');
    if (parts.isEmpty) return RouterVersion.unknown;

    final major = int.tryParse(parts[0]);
    if (major == null) return RouterVersion.unknown;

    final minor = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final patch = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;

    return RouterVersion(
      major: major,
      minor: minor,
      patch: patch,
      channel: channel,
      raw: raw.trim(),
    );
  }

  // ---------------------------------------------------------------------------
  // Comparison helpers
  // ---------------------------------------------------------------------------

  /// True if this version is at least [major].[minor].[patch].
  bool isAtLeast(int major, int minor, [int patch = 0]) {
    if (this.major != major) return this.major > major;
    if (this.minor != minor) return this.minor > minor;
    return this.patch >= patch;
  }

  /// True if this version is strictly before [major].[minor].[patch].
  bool isBefore(int major, int minor, [int patch = 0]) =>
      !isAtLeast(major, minor, patch);

  /// True if this is the [unknown] sentinel (major == minor == patch == 0,
  /// channel == "unknown").
  bool get isUnknown => channel == 'unknown' && major == 0 && minor == 0;

  // ---------------------------------------------------------------------------
  // RouterOS-specific capability shortcuts
  // ---------------------------------------------------------------------------

  /// True if this version supports plain-text API authentication (≥ v6.43).
  ///
  /// RouterOS v6.43 introduced the two-step plain login that sends the
  /// password directly without an MD5 challenge.
  bool supportsPlainAuth() => isAtLeast(6, 43);

  /// True if this version requires MD5 challenge-response authentication
  /// (< v6.43).
  bool requiresMd5Auth() => !supportsPlainAuth();

  // ---------------------------------------------------------------------------
  // Comparable / Object
  // ---------------------------------------------------------------------------

  @override
  int compareTo(RouterVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator <(RouterVersion other) => compareTo(other) < 0;
  bool operator <=(RouterVersion other) => compareTo(other) <= 0;
  bool operator >(RouterVersion other) => compareTo(other) > 0;
  bool operator >=(RouterVersion other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is RouterVersion &&
      major == other.major &&
      minor == other.minor &&
      patch == other.patch;

  @override
  int get hashCode => Object.hash(major, minor, patch);

  @override
  String toString() => raw.isNotEmpty ? raw : '$major.$minor.$patch';
}
