/// MikroTik router credentials model.
///
/// Represents the connection parameters for a single MikroTik router.
/// Passwords are handled as strings here; the actual secure storage
/// (flutter_secure_storage) is managed by the app layer (Phase 2+).
library;

/// Immutable credentials for connecting to a MikroTik RouterOS device.
final class MikrotikCredentials {
  /// Router hostname or IP address.
  final String host;

  /// RouterOS API username.
  final String username;

  /// RouterOS API password.
  ///
  /// Note: The password is held in memory only during an active session.
  /// Persistent storage must use flutter_secure_storage (app layer).
  final String password;

  /// RouterOS API port (default: 8728).
  final int port;

  /// RouterOS SSL API port (default: 8729). Reserved for future use.
  final int sslPort;

  /// Whether to use SSL/TLS. Not implemented in Phase 1.
  final bool useSsl;

  const MikrotikCredentials({
    required this.host,
    required this.username,
    required this.password,
    this.port = 8728,
    this.sslPort = 8729,
    this.useSsl = false,
  });

  /// Creates credentials from a map (e.g. deserialized from storage).
  factory MikrotikCredentials.fromMap(Map<String, dynamic> map) {
    return MikrotikCredentials(
      host: map['host'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      port: (map['port'] as int?) ?? 8728,
      sslPort: (map['sslPort'] as int?) ?? 8729,
      useSsl: (map['useSsl'] as bool?) ?? false,
    );
  }

  /// Serializes to a map.
  ///
  /// WARNING: The returned map contains the plaintext password.
  /// Only use this when writing to a secure storage backend.
  Map<String, dynamic> toMap() => {
    'host': host,
    'username': username,
    'password': password,
    'port': port,
    'sslPort': sslPort,
    'useSsl': useSsl,
  };

  /// Returns a safe string representation with password redacted.
  @override
  String toString() =>
      'MikrotikCredentials(host: $host, username: $username, port: $port)';

  MikrotikCredentials copyWith({
    String? host,
    String? username,
    String? password,
    int? port,
    int? sslPort,
    bool? useSsl,
  }) {
    return MikrotikCredentials(
      host: host ?? this.host,
      username: username ?? this.username,
      password: password ?? this.password,
      port: port ?? this.port,
      sslPort: sslPort ?? this.sslPort,
      useSsl: useSsl ?? this.useSsl,
    );
  }
}
