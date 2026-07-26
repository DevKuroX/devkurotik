/// mikrotik_sdk — MikroTik RouterOS binary API transport for DevKuroTik.
///
/// ## Overview
///
/// This package provides:
/// - [MikrotikClient] — primary API client for RouterOS command execution
/// - [MikrotikConnection] — low-level TCP connection and auth management
/// - [MikrotikConnectionPool] — connection reuse across multiple operations
/// - [RouterosException] and subclasses — typed error taxonomy
/// - [MikrotikCredentials] — connection parameter model
/// - [RouterosRandom] — cryptographically random string generation
/// - [RouterosFormat] — RouterOS value display formatting
///
/// ## Usage
///
/// ```dart
/// import 'package:mikrotik_sdk/mikrotik_sdk.dart';
///
/// final client = MikrotikClient(
///   host: '192.168.1.1',
///   username: 'admin',
///   password: 'secret',
/// );
///
/// await client.connect();
/// final users = await client.command('/ip/hotspot/user/print');
/// await client.disconnect();
/// ```
///
/// ## Supported RouterOS Versions
///
/// - RouterOS v6.43+ (plain text authentication)
/// - RouterOS pre-v6.43 (MD5 challenge-response authentication, auto-detected)
/// - CHR (Cloud Hosted Router) — same protocol as above
library;

// ─── Primary client ───────────────────────────────────────────────────────────
export 'src/mikrotik_client.dart';

// ─── Connection ───────────────────────────────────────────────────────────────
export 'src/connection/connection_state.dart';
export 'src/connection/mikrotik_connection.dart';
export 'src/connection/mikrotik_connection_pool.dart';
export 'src/connection/retry_policy.dart';

// ─── Authentication ───────────────────────────────────────────────────────────
export 'src/auth/routeros_auth.dart';

// ─── Exceptions ───────────────────────────────────────────────────────────────
export 'src/exceptions/routeros_exception.dart';

// ─── Protocol ────────────────────────────────────────────────────────────────
export 'src/protocol/routeros_protocol.dart';

// ─── Logging ─────────────────────────────────────────────────────────────────
export 'src/logging/mikrotik_logger.dart';

// ─── Utilities ────────────────────────────────────────────────────────────────
export 'src/utils/mikrotik_credentials.dart';
export 'src/utils/routeros_format.dart';
export 'src/utils/routeros_random.dart';
