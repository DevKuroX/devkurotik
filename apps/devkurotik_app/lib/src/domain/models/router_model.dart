/// Domain model for a MikroTik router.
///
/// Non-secret fields only — password is stored in flutter_secure_storage
/// and never lives in this model outside of the transient add/edit flows.
library;

/// Groups/tags for routers.
enum RouterGroup {
  ungrouped('Ungrouped'),
  production('Production'),
  staging('Staging'),
  testing('Testing'),
  office('Office'),
  home('Home');

  const RouterGroup(this.label);

  /// Human-readable label.
  final String label;

  /// Parse from stored string value.
  static RouterGroup fromString(String value) {
    return RouterGroup.values.firstWhere(
      (g) => g.name == value,
      orElse: () => RouterGroup.ungrouped,
    );
  }
}

/// Connection health state of a router.
enum RouterHealthStatus {
  unknown,
  reachable,
  unreachable,
  authFailed,
  timeout,
}

/// Immutable domain model representing a saved router.
///
/// [password] is intentionally absent — it lives only in secure storage.
class RouterModel {
  const RouterModel({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
    required this.username,
    required this.group,
    this.note,
    this.lastUsedAt,
    this.createdAt,
    this.healthStatus = RouterHealthStatus.unknown,
    this.lastHealthCheckAt,
  });

  /// Stable primary key (UUID or Drift rowid-based string).
  final String id;

  /// Human-readable display name.
  final String name;

  /// IP address or hostname.
  final String host;

  /// RouterOS API port (default 8728).
  final int port;

  /// API username.
  final String username;

  /// Router group/tag.
  final RouterGroup group;

  /// Optional note.
  final String? note;

  /// When this router was last selected/used.
  final DateTime? lastUsedAt;

  /// When this router was created.
  final DateTime? createdAt;

  /// Most recent health status (transient — not persisted).
  final RouterHealthStatus healthStatus;

  /// When health was last checked (transient — not persisted).
  final DateTime? lastHealthCheckAt;

  RouterModel copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    String? username,
    RouterGroup? group,
    String? note,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    RouterHealthStatus? healthStatus,
    DateTime? lastHealthCheckAt,
  }) {
    return RouterModel(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      username: username ?? this.username,
      group: group ?? this.group,
      note: note ?? this.note,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      healthStatus: healthStatus ?? this.healthStatus,
      lastHealthCheckAt: lastHealthCheckAt ?? this.lastHealthCheckAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouterModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'RouterModel(id: $id, name: $name, host: $host, port: $port, '
      'username: $username, group: ${group.name})';
}
