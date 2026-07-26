/// Phase 4 — Hotspot domain models.
///
/// All models are immutable value types. No credentials stored here.
/// RouterOS fields use their original API key names where possible.
library;

// ---------------------------------------------------------------------------
// Enumerations
// ---------------------------------------------------------------------------

/// Filter modes for hotspot user list.
enum HotspotUserFilter {
  /// All users (no filter).
  all,

  /// Filter by a specific profile name.
  byProfile,

  /// Filter by comment prefix (batch code).
  byComment,

  /// Only users with limit-uptime=1s (effectively expired/used up).
  expired,
}

/// Sort modes for the user list.
enum HotspotUserSort {
  /// Sort by username A→Z.
  nameAsc,

  /// Sort by username Z→A.
  nameDesc,

  /// Sort by profile name.
  profile,

  /// Disabled users last.
  status,
}

/// Filter modes for hotspot hosts.
enum HostFilter {
  all,
  authorized,
  bypassed,
}

// ---------------------------------------------------------------------------
// HotspotUser
// ---------------------------------------------------------------------------

/// A single hotspot user from `/ip/hotspot/user/print`.
///
/// The [comment] field may encode either:
///   - batch code: `"vc-RANDCODE-DATE-COMMENT"` (before first login)
///   - expiry stamp: `"Jan/01/2025 14:30:00 vc-RANDCODE"` (after login)
class HotspotUser {
  const HotspotUser({
    required this.id,
    required this.name,
    required this.profile,
    required this.disabled,
    this.password = '',
    this.server = 'all',
    this.limitUptime,
    this.limitBytesTotal,
    this.comment,
    this.macAddress,
    this.ipAddress,
    this.bytesIn,
    this.bytesOut,
    this.packetsIn,
    this.packetsOut,
    this.uptime,
  });

  /// RouterOS `.id` (e.g. `"*1"`).
  final String id;

  /// Username.
  final String name;

  /// Profile name.
  final String profile;

  /// Whether user is disabled.
  final bool disabled;

  /// Password (may be empty if not returned by router).
  final String password;

  /// Server name (`"all"` = any server).
  final String server;

  /// Upload/download limit string (e.g. `"1h"`, `"1d"`).
  final String? limitUptime;

  /// Byte limit (total).
  final int? limitBytesTotal;

  /// Comment field (dual-use: batch code OR expiry stamp).
  final String? comment;

  /// MAC address binding (null = no lock).
  final String? macAddress;

  /// IP address assigned (null = dynamic).
  final String? ipAddress;

  /// Bytes downloaded by the user (lifetime counter).
  final int? bytesIn;

  /// Bytes uploaded by the user (lifetime counter).
  final int? bytesOut;

  /// Packets received.
  final int? packetsIn;

  /// Packets sent.
  final int? packetsOut;

  /// Session uptime string (from active record).
  final String? uptime;

  /// Whether the user is a voucher (name == password or single-string mode).
  bool get isVoucher =>
      password.isNotEmpty && password == name;

  /// Whether the user appears to be expired (limit-uptime = 1s sentinel).
  bool get isExpired => limitUptime == '1s';

  /// Batch code decoded from [comment] field (before first login).
  String? get batchCode {
    final c = comment;
    if (c == null || c.isEmpty) return null;
    // Format: "vc-RANDCODE-DATE-COMMENT"
    if (c.startsWith('vc-')) return c;
    return null;
  }

  /// Whether there is an active session for this user (requires join with
  /// active list — not stored directly; callers may set via [copyWith]).
  bool get hasActiveSession => false; // augmented externally

  HotspotUser copyWith({
    String? id,
    String? name,
    String? profile,
    bool? disabled,
    String? password,
    String? server,
    String? limitUptime,
    int? limitBytesTotal,
    String? comment,
    String? macAddress,
    String? ipAddress,
    int? bytesIn,
    int? bytesOut,
    int? packetsIn,
    int? packetsOut,
    String? uptime,
  }) {
    return HotspotUser(
      id: id ?? this.id,
      name: name ?? this.name,
      profile: profile ?? this.profile,
      disabled: disabled ?? this.disabled,
      password: password ?? this.password,
      server: server ?? this.server,
      limitUptime: limitUptime ?? this.limitUptime,
      limitBytesTotal: limitBytesTotal ?? this.limitBytesTotal,
      comment: comment ?? this.comment,
      macAddress: macAddress ?? this.macAddress,
      ipAddress: ipAddress ?? this.ipAddress,
      bytesIn: bytesIn ?? this.bytesIn,
      bytesOut: bytesOut ?? this.bytesOut,
      packetsIn: packetsIn ?? this.packetsIn,
      packetsOut: packetsOut ?? this.packetsOut,
      uptime: uptime ?? this.uptime,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotspotUser &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HotspotUser(id: $id, name: $name, profile: $profile, '
      'disabled: $disabled)';

  /// Parse from RouterOS API map (keys without leading `=`).
  factory HotspotUser.fromApiMap(Map<String, String> map) {
    return HotspotUser(
      id: map['.id'] ?? '',
      name: map['name'] ?? '',
      profile: map['profile'] ?? 'default',
      disabled: map['disabled'] == 'true',
      password: map['password'] ?? '',
      server: map['server'] ?? 'all',
      limitUptime: _nullIfEmpty(map['limit-uptime']),
      limitBytesTotal: _parseInt(map['limit-bytes-total']),
      comment: _nullIfEmpty(map['comment']),
      macAddress: _nullIfEmpty(map['mac-address']),
      ipAddress: _nullIfEmpty(map['address']),
      bytesIn: _parseInt(map['bytes-in']),
      bytesOut: _parseInt(map['bytes-out']),
      packetsIn: _parseInt(map['packets-in']),
      packetsOut: _parseInt(map['packets-out']),
      uptime: _nullIfEmpty(map['uptime']),
    );
  }
}

// ---------------------------------------------------------------------------
// HotspotProfile
// ---------------------------------------------------------------------------

/// A hotspot user profile from `/ip/hotspot/user/profile/print`.
class HotspotProfile {
  const HotspotProfile({
    required this.id,
    required this.name,
    this.rateLimit,
    this.addressPool,
    this.sharedUsers = 1,
    this.sessionTimeout,
    this.idleTimeout,
    this.onLogin,
    this.onLogout,
    this.keepaliveTimeout,
    // Decoded Mikhmon metadata from on-login script:
    this.price,
    this.sellingPrice,
    this.validity,
    this.macLock = false,
  });

  final String id;
  final String name;

  /// Rate limit string (e.g. `"512k/1M"`).
  final String? rateLimit;

  /// Address pool name.
  final String? addressPool;

  /// Number of simultaneous sessions allowed.
  final int sharedUsers;

  /// Session timeout (e.g. `"1h"`).
  final String? sessionTimeout;

  /// Idle timeout.
  final String? idleTimeout;

  /// On-login script content.
  final String? onLogin;

  /// On-logout script content.
  final String? onLogout;

  /// Keepalive timeout.
  final String? keepaliveTimeout;

  // ── Mikhmon metadata decoded from on-login script ──────────────────────────

  /// Price (IDR or local currency).
  final double? price;

  /// Selling price.
  final double? sellingPrice;

  /// Validity string (e.g. `"1 Day"`, `"1 Hour"`).
  final String? validity;

  /// MAC address lock on first login.
  final bool macLock;

  /// Human-readable display name (includes validity if available).
  String get displayName {
    if (validity != null && validity!.isNotEmpty) {
      return '$name ($validity)';
    }
    return name;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotspotProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'HotspotProfile(id: $id, name: $name)';

  /// Parse from RouterOS API map.
  factory HotspotProfile.fromApiMap(Map<String, String> map) {
    return HotspotProfile(
      id: map['.id'] ?? '',
      name: map['name'] ?? '',
      rateLimit: _nullIfEmpty(map['rate-limit']),
      addressPool: _nullIfEmpty(map['address-pool']),
      sharedUsers: _parseInt(map['shared-users']) ?? 1,
      sessionTimeout: _nullIfEmpty(map['session-timeout']),
      idleTimeout: _nullIfEmpty(map['idle-timeout']),
      onLogin: _nullIfEmpty(map['on-login']),
      onLogout: _nullIfEmpty(map['on-logout']),
      keepaliveTimeout: _nullIfEmpty(map['keepalive-timeout']),
    );
  }
}

// ---------------------------------------------------------------------------
// HotspotActive
// ---------------------------------------------------------------------------

/// An active hotspot session from `/ip/hotspot/active/print`.
class HotspotActive {
  const HotspotActive({
    required this.id,
    required this.user,
    required this.server,
    required this.macAddress,
    required this.address,
    this.loginBy,
    this.uptime,
    this.idleTime,
    this.bytesIn,
    this.bytesOut,
    this.packetsIn,
    this.packetsOut,
    this.comment,
  });

  /// RouterOS `.id`.
  final String id;

  /// Username.
  final String user;

  /// Hotspot server name.
  final String server;

  /// MAC address.
  final String macAddress;

  /// IP address assigned.
  final String address;

  /// Login method (e.g. `"login"`, `"mac"`, `"cookie"`).
  final String? loginBy;

  /// Session uptime string.
  final String? uptime;

  /// Idle time string.
  final String? idleTime;

  final int? bytesIn;
  final int? bytesOut;
  final int? packetsIn;
  final int? packetsOut;
  final String? comment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotspotActive &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'HotspotActive(id: $id, user: $user, address: $address)';

  /// Parse from RouterOS API map.
  factory HotspotActive.fromApiMap(Map<String, String> map) {
    return HotspotActive(
      id: map['.id'] ?? '',
      user: map['user'] ?? '',
      server: map['server'] ?? '',
      macAddress: map['mac-address'] ?? '',
      address: map['address'] ?? '',
      loginBy: _nullIfEmpty(map['login-by']),
      uptime: _nullIfEmpty(map['uptime']),
      idleTime: _nullIfEmpty(map['idle-time']),
      bytesIn: _parseInt(map['bytes-in']),
      bytesOut: _parseInt(map['bytes-out']),
      packetsIn: _parseInt(map['packets-in']),
      packetsOut: _parseInt(map['packets-out']),
      comment: _nullIfEmpty(map['comment']),
    );
  }
}

// ---------------------------------------------------------------------------
// HotspotCookie
// ---------------------------------------------------------------------------

/// A hotspot cookie from `/ip/hotspot/cookie/print`.
class HotspotCookie {
  const HotspotCookie({
    required this.id,
    required this.user,
    required this.macAddress,
    this.domain,
    this.expiresIn,
  });

  final String id;
  final String user;
  final String macAddress;
  final String? domain;
  final String? expiresIn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotspotCookie &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory HotspotCookie.fromApiMap(Map<String, String> map) {
    return HotspotCookie(
      id: map['.id'] ?? '',
      user: map['user'] ?? '',
      macAddress: map['mac-address'] ?? '',
      domain: _nullIfEmpty(map['domain']),
      expiresIn: _nullIfEmpty(map['expires-in']),
    );
  }
}

// ---------------------------------------------------------------------------
// HotspotHost
// ---------------------------------------------------------------------------

/// A hotspot host from `/ip/hotspot/host/print`.
class HotspotHost {
  const HotspotHost({
    required this.id,
    required this.macAddress,
    required this.address,
    this.server,
    this.comment,
    this.toAddress,
    this.authorized = false,
    this.bypassed = false,
  });

  final String id;
  final String macAddress;
  final String address;
  final String? server;
  final String? comment;
  final String? toAddress;
  final bool authorized;
  final bool bypassed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HotspotHost &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory HotspotHost.fromApiMap(Map<String, String> map) {
    return HotspotHost(
      id: map['.id'] ?? '',
      macAddress: map['mac-address'] ?? '',
      address: map['address'] ?? '',
      server: _nullIfEmpty(map['server']),
      comment: _nullIfEmpty(map['comment']),
      toAddress: _nullIfEmpty(map['to-address']),
      authorized: map['authorized'] == 'true',
      bypassed: map['bypassed'] == 'true',
    );
  }
}

// ---------------------------------------------------------------------------
// HotspotUserCreate / HotspotUserUpdate
// ---------------------------------------------------------------------------

/// Parameters for creating a new hotspot user.
class HotspotUserCreate {
  const HotspotUserCreate({
    required this.name,
    required this.password,
    required this.profile,
    this.server = 'all',
    this.limitUptime,
    this.limitBytesTotal,
    this.comment,
    this.macAddress,
    this.disabled = false,
  });

  final String name;
  final String password;
  final String profile;
  final String server;
  final String? limitUptime;
  final int? limitBytesTotal;
  final String? comment;
  final String? macAddress;
  final bool disabled;

  /// Convert to RouterOS API parameter map.
  Map<String, String> toApiParams() {
    final m = <String, String>{
      'name': name,
      'password': password,
      'profile': profile,
      'server': server,
    };
    if (limitUptime != null && limitUptime!.isNotEmpty) {
      m['limit-uptime'] = limitUptime!;
    }
    if (limitBytesTotal != null && limitBytesTotal! > 0) {
      m['limit-bytes-total'] = limitBytesTotal!.toString();
    }
    if (comment != null && comment!.isNotEmpty) {
      m['comment'] = comment!;
    }
    if (macAddress != null && macAddress!.isNotEmpty) {
      m['mac-address'] = macAddress!;
    }
    if (disabled) {
      m['disabled'] = 'yes';
    }
    return m;
  }
}

/// Parameters for updating an existing hotspot user.
class HotspotUserUpdate {
  const HotspotUserUpdate({
    this.name,
    this.password,
    this.profile,
    this.server,
    this.limitUptime,
    this.limitBytesTotal,
    this.comment,
    this.macAddress,
    this.disabled,
  });

  final String? name;
  final String? password;
  final String? profile;
  final String? server;
  final String? limitUptime;
  final int? limitBytesTotal;
  final String? comment;
  final String? macAddress;
  final bool? disabled;

  /// Convert to RouterOS API parameter map (only non-null fields).
  Map<String, String> toApiParams() {
    final m = <String, String>{};
    if (name != null) m['name'] = name!;
    if (password != null) m['password'] = password!;
    if (profile != null) m['profile'] = profile!;
    if (server != null) m['server'] = server!;
    if (limitUptime != null) m['limit-uptime'] = limitUptime!;
    if (limitBytesTotal != null) {
      m['limit-bytes-total'] = limitBytesTotal!.toString();
    }
    if (comment != null) m['comment'] = comment!;
    if (macAddress != null) m['mac-address'] = macAddress!;
    if (disabled != null) m['disabled'] = disabled! ? 'yes' : 'no';
    return m;
  }
}

// ---------------------------------------------------------------------------
// HotspotData — snapshot for a single router
// ---------------------------------------------------------------------------

/// Snapshot of all hotspot data for one router.
class HotspotData {
  const HotspotData({
    required this.routerId,
    required this.users,
    required this.profiles,
    required this.activeSessions,
    required this.fetchedAt,
  });

  final String routerId;
  final List<HotspotUser> users;
  final List<HotspotProfile> profiles;
  final List<HotspotActive> activeSessions;
  final DateTime fetchedAt;

  int get totalUsers => users.length;
  int get activeUsers => activeSessions.length;
  int get disabledUsers => users.where((u) => u.disabled).length;
  int get expiredUsers => users.where((u) => u.isExpired).length;
}

// ---------------------------------------------------------------------------
// Validation
// ---------------------------------------------------------------------------

/// Validation result for hotspot user form fields.
class HotspotUserValidation {
  const HotspotUserValidation({
    this.nameError,
    this.passwordError,
    this.profileError,
    this.limitUptimeError,
    this.macAddressError,
  });

  final String? nameError;
  final String? passwordError;
  final String? profileError;
  final String? limitUptimeError;
  final String? macAddressError;

  bool get isValid =>
      nameError == null &&
      passwordError == null &&
      profileError == null &&
      limitUptimeError == null &&
      macAddressError == null;

  static HotspotUserValidation validate(HotspotUserCreate params) {
    return HotspotUserValidation(
      nameError: validateName(params.name),
      passwordError: validatePassword(params.password),
      profileError: validateProfile(params.profile),
      limitUptimeError: validateLimitUptime(params.limitUptime),
      macAddressError: validateMacAddress(params.macAddress),
    );
  }

  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Username must not be empty.';
    if (name.length > 64) return 'Username must be at most 64 characters.';
    // RouterOS allows alphanumeric + hyphen + underscore + dot
    final allowed = RegExp(r'^[a-zA-Z0-9._@\-]+$');
    if (!allowed.hasMatch(name)) {
      return 'Username contains invalid characters.';
    }
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Password must not be empty.';
    if (password.length > 64) return 'Password must be at most 64 characters.';
    return null;
  }

  static String? validateProfile(String profile) {
    if (profile.trim().isEmpty) return 'Profile must not be empty.';
    return null;
  }

  static String? validateLimitUptime(String? limitUptime) {
    if (limitUptime == null || limitUptime.isEmpty) return null;
    // RouterOS uptime format: 1d2h3m4s or combinations
    final pattern = RegExp(
      r'^(\d+w)?(\d+d)?(\d+h)?(\d+m)?(\d+s)?$',
      caseSensitive: false,
    );
    if (!pattern.hasMatch(limitUptime)) {
      return 'Invalid limit format. Use e.g. 1h, 2h30m, 1d.';
    }
    return null;
  }

  static String? validateMacAddress(String? mac) {
    if (mac == null || mac.isEmpty) return null;
    final pattern = RegExp(r'^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$');
    if (!pattern.hasMatch(mac)) {
      return 'Invalid MAC address. Use XX:XX:XX:XX:XX:XX format.';
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

String? _nullIfEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

int? _parseInt(String? s) {
  if (s == null || s.isEmpty) return null;
  return int.tryParse(s);
}
