/// RouterOS value display formatters for the Phase 3 dashboard.
///
/// All methods are pure, stateless, and unit-testable.
library;

/// Formatters for RouterOS raw values → human-readable display strings.
abstract final class RouterResourceFormatter {
  // ─── CPU ────────────────────────────────────────────────────────────────────

  /// Format a CPU load integer [0–100] as a percentage string.
  ///
  /// ```dart
  /// RouterResourceFormatter.cpu(12);  // "12%"
  /// RouterResourceFormatter.cpu(0);   // "0%"
  /// ```
  static String cpu(int load) {
    final clamped = load.clamp(0, 100);
    return '$clamped%';
  }

  // ─── Memory ─────────────────────────────────────────────────────────────────

  /// Format memory usage as "X% (usedMB / totalMB)".
  ///
  /// ```dart
  /// RouterResourceFormatter.memory(
  ///   freeBytes: 134217728,
  ///   totalBytes: 536870912,
  /// );
  /// // "75% (384 MB / 512 MB)"
  /// ```
  static String memory({
    required int freeBytes,
    required int totalBytes,
  }) {
    if (totalBytes <= 0) return '—';
    final usedBytes = totalBytes - freeBytes;
    final percent = ((usedBytes / totalBytes) * 100).round().clamp(0, 100);
    final usedMb = (usedBytes / (1024 * 1024)).round();
    final totalMb = (totalBytes / (1024 * 1024)).round();
    return '$percent% ($usedMb MB / $totalMb MB)';
  }

  /// Format memory as a short percentage string.
  ///
  /// ```dart
  /// RouterResourceFormatter.memoryPercent(
  ///   freeBytes: 268435456,
  ///   totalBytes: 536870912,
  /// );
  /// // "50%"
  /// ```
  static String memoryPercent({
    required int freeBytes,
    required int totalBytes,
  }) {
    if (totalBytes <= 0) return '—';
    final usedBytes = totalBytes - freeBytes;
    final percent = ((usedBytes / totalBytes) * 100).round().clamp(0, 100);
    return '$percent%';
  }

  // ─── Uptime ─────────────────────────────────────────────────────────────────

  /// Convert a RouterOS uptime string to a human-readable form.
  ///
  /// RouterOS returns values like:
  ///   "4d12h30m5s", "2h15m", "45m10s", "1w2d3h"
  ///
  /// Output examples:
  ///   "4d 12h 30m" — days + hours + minutes (if days > 0)
  ///   "2h 15m"      — hours + minutes (no days)
  ///   "45m 10s"     — minutes + seconds (no hours/days)
  ///   "5s"          — seconds only
  ///   "—"           — empty / unparseable
  static String uptime(String raw) {
    if (raw.isEmpty) return '—';

    int weeks = 0;
    int days = 0;
    int hours = 0;
    int minutes = 0;
    int seconds = 0;

    // Parse each component.
    final pattern = RegExp(r'(\d+)([wdhms])');
    for (final m in pattern.allMatches(raw)) {
      final value = int.parse(m.group(1)!);
      switch (m.group(2)) {
        case 'w':
          weeks = value;
        case 'd':
          days = value;
        case 'h':
          hours = value;
        case 'm':
          minutes = value;
        case 's':
          seconds = value;
      }
    }

    // Normalise weeks → days.
    days += weeks * 7;

    // Build display string: show top-2 significant components.
    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0 || days > 0) {
      if (hours > 0 || parts.isNotEmpty) parts.add('${hours}h');
    }
    if (minutes > 0 || hours > 0 || days > 0) {
      if (minutes > 0 || parts.isNotEmpty) parts.add('${minutes}m');
    }
    if (parts.isEmpty) parts.add('${seconds}s');

    // Cap at 3 components.
    return parts.take(3).join(' ');
  }

  // ─── Last seen ──────────────────────────────────────────────────────────────

  /// Human-readable "last seen" relative to [now].
  ///
  /// ```dart
  /// RouterResourceFormatter.lastSeen(fetchedAt, now: DateTime.now());
  /// // "Just now"  / "2 min ago"  / "1 hr ago"  / "3 hrs ago"
  /// ```
  static String lastSeen(DateTime fetchedAt, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final diff = reference.difference(fetchedAt);

    if (diff.inSeconds < 10) return 'Just now';
    if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
    if (diff.inMinutes == 1) return '1 min ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours == 1) return '1 hr ago';
    if (diff.inHours < 24) return '${diff.inHours} hrs ago';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays} days ago';
  }

  // ─── Version ────────────────────────────────────────────────────────────────

  /// Strip the release channel suffix from a version string.
  ///
  /// ```dart
  /// RouterResourceFormatter.versionShort('7.15.1 (stable)');  // "7.15.1"
  /// RouterResourceFormatter.versionShort('6.49.17');           // "6.49.17"
  /// ```
  static String versionShort(String raw) {
    final idx = raw.indexOf(' ');
    return idx > 0 ? raw.substring(0, idx) : raw;
  }
}
