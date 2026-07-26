/// Integration test credential loader.
///
/// Credentials are loaded from environment variables or local secret files.
/// NEVER hardcode credentials in test files.
///
/// ## Usage
///
/// Set environment variables before running tests:
/// ```bash
/// export CHR_V7_HOST=54.147.121.92
/// export CHR_V7_USER=admin
/// export CHR_V7_PASSWORD=<password>
/// export CHR_V7_PORT=8728
///
/// export CHR_V6_HOST=139.162.35.252
/// export CHR_V6_USER=admin
/// export CHR_V6_PASSWORD=<password>
/// export CHR_V6_PORT=8728
///
/// dart test test/integration_chr_test.dart
/// ```
///
/// Without env vars, the loader falls back to reading `chr.txt` /
/// `chr6.txt` from the repository root (these files are gitignored).
library;

import 'dart:io';

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

String _env(String key) => Platform.environment[key] ?? '';

/// Read a named field from a chr credential file.
/// File format: "FieldName: value" per line.
String _fileField(String filePath, String fieldName) {
  try {
    final f = File(filePath);
    if (!f.existsSync()) return '';
    for (final line in f.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.startsWith('$fieldName:')) {
        return trimmed.substring(fieldName.length + 1).trim();
      }
    }
  } catch (_) {}
  return '';
}

/// Resolve repository root by walking up from __current script directory.
String _repoRoot() {
  // integration tests live in packages/mikrotik_sdk/test/
  // repository root is 3 levels up
  var dir = Directory.current;
  // Try to find the repo root by looking for a .git directory
  for (var i = 0; i < 6; i++) {
    if (Directory('${dir.path}/.git').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  // Fallback: assume current dir is repo root
  return Directory.current.path;
}

// ---------------------------------------------------------------------------
// CHR v7 credentials
// ---------------------------------------------------------------------------

/// CHR v7 host (IP or hostname).
/// Source: env `CHR_V7_HOST` → chr.txt `IP` field → hard-fail.
String get chrV7Host {
  final v = _env('CHR_V7_HOST');
  if (v.isNotEmpty) return v;
  final fromFile = _fileField('${_repoRoot()}/chr.txt', 'IP');
  if (fromFile.isNotEmpty) return fromFile;
  throw StateError(
    'CHR_V7_HOST not set. '
    'Set env var CHR_V7_HOST or ensure chr.txt exists at repo root.',
  );
}

/// CHR v7 username.
String get chrV7User {
  final v = _env('CHR_V7_USER');
  if (v.isNotEmpty) return v;
  final fromFile = _fileField('${_repoRoot()}/chr.txt', 'Username');
  return fromFile.isNotEmpty ? fromFile : 'admin';
}

/// CHR v7 password.
/// Source: env `CHR_V7_PASSWORD` → chr.txt `Password` field → hard-fail.
String get chrV7Password {
  final v = _env('CHR_V7_PASSWORD');
  if (v.isNotEmpty) return v;
  final fromFile = _fileField('${_repoRoot()}/chr.txt', 'Password');
  if (fromFile.isNotEmpty) return fromFile;
  throw StateError(
    'CHR_V7_PASSWORD not set. '
    'Set env var CHR_V7_PASSWORD or ensure chr.txt exists at repo root.',
  );
}

/// CHR v7 API port.
int get chrV7Port {
  final v = _env('CHR_V7_PORT');
  if (v.isNotEmpty) return int.tryParse(v) ?? 8728;
  final fromFile = _fileField('${_repoRoot()}/chr.txt', 'Port');
  return int.tryParse(fromFile) ?? 8728;
}

// ---------------------------------------------------------------------------
// CHR v6 credentials
// ---------------------------------------------------------------------------

/// CHR v6 host (IP or hostname).
String get chrV6Host {
  final v = _env('CHR_V6_HOST');
  if (v.isNotEmpty) return v;
  final fromFile = _fileField('${_repoRoot()}/chr6.txt', 'IP');
  if (fromFile.isNotEmpty) return fromFile;
  throw StateError(
    'CHR_V6_HOST not set. '
    'Set env var CHR_V6_HOST or ensure chr6.txt exists at repo root.',
  );
}

/// CHR v6 username.
String get chrV6User {
  final v = _env('CHR_V6_USER');
  if (v.isNotEmpty) return v;
  final fromFile = _fileField('${_repoRoot()}/chr6.txt', 'Username');
  return fromFile.isNotEmpty ? fromFile : 'admin';
}

/// CHR v6 password.
String get chrV6Password {
  final v = _env('CHR_V6_PASSWORD');
  if (v.isNotEmpty) return v;
  final fromFile = _fileField('${_repoRoot()}/chr6.txt', 'Password');
  if (fromFile.isNotEmpty) return fromFile;
  throw StateError(
    'CHR_V6_PASSWORD not set. '
    'Set env var CHR_V6_PASSWORD or ensure chr6.txt exists at repo root.',
  );
}

/// CHR v6 API port.
int get chrV6Port {
  final v = _env('CHR_V6_PORT');
  if (v.isNotEmpty) return int.tryParse(v) ?? 8728;
  final fromFile = _fileField('${_repoRoot()}/chr6.txt', 'Port');
  return int.tryParse(fromFile) ?? 8728;
}
