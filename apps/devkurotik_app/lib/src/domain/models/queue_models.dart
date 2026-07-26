/// Phase 7 — Queue domain models.
///
/// Covers simple queue management.
///
/// ## Audited Scope
///
/// From API_ENDPOINTS.md:
///   - `/queue/simple/print` — READ (used by adduserprofile.php,
///     userprofilebyname.php, pipbinding.php)
///   - `/queue/simple/remove` — DELETE (used by pipbinding.php cascade)
///
/// Queue Tree (`/queue/tree/*`) is NOT in the audited Mikhmon source
/// and is explicitly out of scope for Phase 7.
///
/// Queue Add/Set is not in the Mikhmon source scope for this phase —
/// queues are managed in RouterOS directly and consumed by profile
/// assignment dropdowns within the app.
///
/// All models are immutable value types.
library;

// ---------------------------------------------------------------------------
// SimpleQueue
// ---------------------------------------------------------------------------

/// A simple queue from `/queue/simple/print`.
class SimpleQueue {
  const SimpleQueue({
    required this.id,
    required this.name,
    this.target,
    this.maxLimit,
    this.limitAt,
    this.burstLimit,
    this.burstThreshold,
    this.burstTime,
    this.parent,
    this.priority,
    this.disabled = false,
    this.comment,
    this.bytes,
    this.packets,
    this.dropped,
  });

  /// RouterOS `.id` (e.g. `"*1"`).
  final String id;

  /// Queue name.
  final String name;

  /// Target IP or subnet (e.g. `"192.168.1.0/24"`).
  final String? target;

  /// Max limit string (e.g. `"512k/1M"` — upload/download).
  final String? maxLimit;

  /// Guaranteed bandwidth.
  final String? limitAt;

  /// Burst limit.
  final String? burstLimit;

  /// Burst threshold.
  final String? burstThreshold;

  /// Burst time.
  final String? burstTime;

  /// Parent queue name (for sub-queues).
  final String? parent;

  /// Priority (1–8).
  final int? priority;

  /// Whether this queue is disabled.
  final bool disabled;

  final String? comment;

  // ── Counters (live from RouterOS) ─────────────────────────────────────────

  final String? bytes;
  final String? packets;
  final String? dropped;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SimpleQueue &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SimpleQueue(id: $id, name: $name, maxLimit: $maxLimit, '
      'target: $target, disabled: $disabled)';

  factory SimpleQueue.fromApiMap(Map<String, String> map) {
    return SimpleQueue(
      id: map['.id'] ?? '',
      name: map['name'] ?? '',
      target: _nullIfEmpty(map['target']),
      maxLimit: _nullIfEmpty(map['max-limit']),
      limitAt: _nullIfEmpty(map['limit-at']),
      burstLimit: _nullIfEmpty(map['burst-limit']),
      burstThreshold: _nullIfEmpty(map['burst-threshold']),
      burstTime: _nullIfEmpty(map['burst-time']),
      parent: _nullIfEmpty(map['parent']),
      priority: _parseInt(map['priority']),
      disabled: map['disabled'] == 'true',
      comment: _nullIfEmpty(map['comment']),
      bytes: _nullIfEmpty(map['bytes']),
      packets: _nullIfEmpty(map['packets']),
      dropped: _nullIfEmpty(map['dropped']),
    );
  }

  SimpleQueue copyWith({
    String? id,
    String? name,
    String? target,
    String? maxLimit,
    String? limitAt,
    String? burstLimit,
    String? burstThreshold,
    String? burstTime,
    String? parent,
    int? priority,
    bool? disabled,
    String? comment,
    String? bytes,
    String? packets,
    String? dropped,
  }) {
    return SimpleQueue(
      id: id ?? this.id,
      name: name ?? this.name,
      target: target ?? this.target,
      maxLimit: maxLimit ?? this.maxLimit,
      limitAt: limitAt ?? this.limitAt,
      burstLimit: burstLimit ?? this.burstLimit,
      burstThreshold: burstThreshold ?? this.burstThreshold,
      burstTime: burstTime ?? this.burstTime,
      parent: parent ?? this.parent,
      priority: priority ?? this.priority,
      disabled: disabled ?? this.disabled,
      comment: comment ?? this.comment,
      bytes: bytes ?? this.bytes,
      packets: packets ?? this.packets,
      dropped: dropped ?? this.dropped,
    );
  }
}

// ---------------------------------------------------------------------------
// SimpleQueueFilter
// ---------------------------------------------------------------------------

/// Filter for the simple queue list.
enum SimpleQueueFilter {
  /// All queues.
  all,

  /// Only enabled queues.
  enabled,

  /// Only disabled queues.
  disabled,
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

String? _nullIfEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

int? _parseInt(String? s) {
  if (s == null || s.isEmpty) return null;
  return int.tryParse(s);
}
