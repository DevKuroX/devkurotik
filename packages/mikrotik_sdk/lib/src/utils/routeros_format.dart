/// RouterOS display format utilities.
///
/// Ported from Mikhmon v3 `lib/routeros_api.class.php`:
/// - `formatDTM()` → [RouterosFormat.uptime]
/// - `formatInterval()` → [RouterosFormat.interval]
/// - (implied) bytes formatting → [RouterosFormat.bytes]
/// - (implied) bitrate formatting → [RouterosFormat.bitrate]
library;

/// Formats RouterOS values for display.
abstract final class RouterosFormat {
  RouterosFormat._();

  /// Converts a RouterOS uptime/duration string to `HH:MM:SS` display format.
  ///
  /// Handles RouterOS duration formats:
  /// - `1d2h3m4s` → `26:03:04`
  /// - `2h30m` → `02:30:00`
  /// - `45m` → `00:45:00`
  /// - `30s` → `00:00:30`
  /// - `1w2d3h4m5s` → supported
  ///
  /// Returns `'00:00:00'` if the format cannot be parsed.
  static String uptime(String dtm) {
    if (dtm.isEmpty) return '00:00:00';

    var totalSeconds = 0;

    final weekMatch = RegExp(r'(\d+)w').firstMatch(dtm);
    final dayMatch = RegExp(r'(\d+)d').firstMatch(dtm);
    final hourMatch = RegExp(r'(\d+)h').firstMatch(dtm);
    final minMatch = RegExp(r'(\d+)m').firstMatch(dtm);
    final secMatch = RegExp(r'(\d+)s').firstMatch(dtm);

    if (weekMatch != null) {
      totalSeconds += int.parse(weekMatch.group(1)!) * 7 * 24 * 3600;
    }
    if (dayMatch != null) {
      totalSeconds += int.parse(dayMatch.group(1)!) * 24 * 3600;
    }
    if (hourMatch != null) {
      totalSeconds += int.parse(hourMatch.group(1)!) * 3600;
    }
    if (minMatch != null) {
      totalSeconds += int.parse(minMatch.group(1)!) * 60;
    }
    if (secMatch != null) {
      totalSeconds += int.parse(secMatch.group(1)!);
    }

    if (totalSeconds == 0 &&
        weekMatch == null &&
        dayMatch == null &&
        hourMatch == null &&
        minMatch == null &&
        secMatch == null) {
      return '00:00:00';
    }

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats a byte count into a human-readable string.
  ///
  /// Examples:
  /// - `512` → `'512 B'`
  /// - `1536` → `'1.5 KB'`
  /// - `1048576` → `'1.0 MB'`
  static String bytes(int byteCount) {
    if (byteCount < 0) return '0 B';
    if (byteCount < 1024) return '$byteCount B';
    if (byteCount < 1024 * 1024) {
      return '${(byteCount / 1024).toStringAsFixed(1)} KB';
    }
    if (byteCount < 1024 * 1024 * 1024) {
      return '${(byteCount / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (byteCount < 1024 * 1024 * 1024 * 1024) {
      return '${(byteCount / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    return '${(byteCount / (1024 * 1024 * 1024 * 1024)).toStringAsFixed(1)} TB';
  }

  /// Formats a bits-per-second value into a human-readable bitrate string.
  ///
  /// Examples:
  /// - `512` → `'512 bps'`
  /// - `1500000` → `'1.5 Mbps'`
  static String bitrate(int bitsPerSecond) {
    if (bitsPerSecond < 0) return '0 bps';
    if (bitsPerSecond < 1000) return '$bitsPerSecond bps';
    if (bitsPerSecond < 1000 * 1000) {
      return '${(bitsPerSecond / 1000).toStringAsFixed(1)} Kbps';
    }
    if (bitsPerSecond < 1000 * 1000 * 1000) {
      return '${(bitsPerSecond / (1000 * 1000)).toStringAsFixed(1)} Mbps';
    }
    return '${(bitsPerSecond / (1000 * 1000 * 1000)).toStringAsFixed(1)} Gbps';
  }

  /// Strips trailing unit characters from a RouterOS interval string.
  ///
  /// Example: `'1d00:00:00'` → `'1d00:00:00'` (pass-through for non-trivial formats)
  /// Mainly strips lone unit suffixes like `'5m'` → `'5'` when used as a raw number.
  static String interval(String dtm) {
    if (dtm.isEmpty) return dtm;
    return dtm.replaceAll(RegExp(r'[a-zA-Z]$'), '');
  }
}
