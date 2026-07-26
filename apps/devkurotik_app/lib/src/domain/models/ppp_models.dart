/// Phase 7 — PPP domain models.
///
/// Covers PPP secrets, PPP profiles, and PPP active sessions.
///
/// ## Source Gap Documentation
///
/// The Mikhmon v3 PHP source only contains `/ppp/active/remove` in
/// `process/removepactive.php`. PPP secret and profile endpoints
/// (`/ppp/secret/print`, `/ppp/secret/add`, `/ppp/secret/set`,
/// `/ppp/secret/remove`, `/ppp/profile/print`) are **not implemented**
/// in the Mikhmon source but are documented in FEATURE_MATRIX.md Module 12
/// as 🟠 High priority. This implementation is derived directly from
/// the RouterOS API specification and audited endpoint mapping.
///
/// All models are immutable value types. No credentials stored here.
library;

// ---------------------------------------------------------------------------
// PppService type enum
// ---------------------------------------------------------------------------

/// PPP service type.
enum PppServiceType {
  /// Any PPP service.
  any,

  /// PPPoE (Point-to-Point Protocol over Ethernet).
  pppoe,

  /// L2TP (Layer 2 Tunneling Protocol).
  l2tp,

  /// PPTP (Point-to-Point Tunneling Protocol).
  pptp,

  /// SSTP (Secure Socket Tunneling Protocol).
  sstp,

  /// OpenVPN.
  ovpn;

  /// RouterOS `service` field value.
  String get rosValue {
    switch (this) {
      case PppServiceType.any:
        return 'any';
      case PppServiceType.pppoe:
        return 'pppoe';
      case PppServiceType.l2tp:
        return 'l2tp';
      case PppServiceType.pptp:
        return 'pptp';
      case PppServiceType.sstp:
        return 'sstp';
      case PppServiceType.ovpn:
        return 'ovpn';
    }
  }

  /// Parse from RouterOS API value.
  static PppServiceType fromRos(String? value) {
    switch (value?.toLowerCase()) {
      case 'pppoe':
        return PppServiceType.pppoe;
      case 'l2tp':
        return PppServiceType.l2tp;
      case 'pptp':
        return PppServiceType.pptp;
      case 'sstp':
        return PppServiceType.sstp;
      case 'ovpn':
        return PppServiceType.ovpn;
      default:
        return PppServiceType.any;
    }
  }

  String get displayName {
    switch (this) {
      case PppServiceType.any:
        return 'Any';
      case PppServiceType.pppoe:
        return 'PPPoE';
      case PppServiceType.l2tp:
        return 'L2TP';
      case PppServiceType.pptp:
        return 'PPTP';
      case PppServiceType.sstp:
        return 'SSTP';
      case PppServiceType.ovpn:
        return 'OpenVPN';
    }
  }
}

// ---------------------------------------------------------------------------
// PppSecret
// ---------------------------------------------------------------------------

/// A PPP secret from `/ppp/secret/print`.
class PppSecret {
  const PppSecret({
    required this.id,
    required this.name,
    this.password = '',
    this.service = PppServiceType.any,
    this.profile = 'default',
    this.disabled = false,
    this.comment,
    this.localAddress,
    this.remoteAddress,
    this.callerId,
    this.lastLoggedOut,
    this.routes,
  });

  /// RouterOS `.id` (e.g. `"*1"`).
  final String id;

  /// Username.
  final String name;

  /// Password (may be empty if not returned by router).
  final String password;

  /// PPP service type.
  final PppServiceType service;

  /// Profile name.
  final String profile;

  /// Whether this secret is disabled.
  final bool disabled;

  /// Optional comment.
  final String? comment;

  /// Local IP address assigned to this connection.
  final String? localAddress;

  /// Remote IP address assigned to the client.
  final String? remoteAddress;

  /// Caller ID restriction (null = no restriction).
  final String? callerId;

  /// Timestamp of last logout.
  final String? lastLoggedOut;

  /// Static routes (comma-separated).
  final String? routes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PppSecret && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PppSecret(id: $id, name: $name, service: ${service.rosValue}, '
      'profile: $profile, disabled: $disabled)';

  /// Parse from RouterOS API map.
  factory PppSecret.fromApiMap(Map<String, String> map) {
    return PppSecret(
      id: map['.id'] ?? '',
      name: map['name'] ?? '',
      password: map['password'] ?? '',
      service: PppServiceType.fromRos(map['service']),
      profile: map['profile'] ?? 'default',
      disabled: map['disabled'] == 'true',
      comment: _nullIfEmpty(map['comment']),
      localAddress: _nullIfEmpty(map['local-address']),
      remoteAddress: _nullIfEmpty(map['remote-address']),
      callerId: _nullIfEmpty(map['caller-id']),
      lastLoggedOut: _nullIfEmpty(map['last-logged-out']),
      routes: _nullIfEmpty(map['routes']),
    );
  }

  PppSecret copyWith({
    String? id,
    String? name,
    String? password,
    PppServiceType? service,
    String? profile,
    bool? disabled,
    String? comment,
    String? localAddress,
    String? remoteAddress,
    String? callerId,
    String? lastLoggedOut,
    String? routes,
  }) {
    return PppSecret(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      service: service ?? this.service,
      profile: profile ?? this.profile,
      disabled: disabled ?? this.disabled,
      comment: comment ?? this.comment,
      localAddress: localAddress ?? this.localAddress,
      remoteAddress: remoteAddress ?? this.remoteAddress,
      callerId: callerId ?? this.callerId,
      lastLoggedOut: lastLoggedOut ?? this.lastLoggedOut,
      routes: routes ?? this.routes,
    );
  }
}

// ---------------------------------------------------------------------------
// PppProfile
// ---------------------------------------------------------------------------

/// A PPP profile from `/ppp/profile/print`.
class PppProfile {
  const PppProfile({
    required this.id,
    required this.name,
    this.localAddress,
    this.remoteAddress,
    this.rateLimit,
    this.sessionTimeout,
    this.idleTimeout,
    this.onlyOne = false,
    this.comment,
  });

  final String id;
  final String name;

  /// Local IP or pool name for this profile.
  final String? localAddress;

  /// Remote IP or pool name.
  final String? remoteAddress;

  /// Rate limit string (e.g. `"512k/1M"`).
  final String? rateLimit;

  /// Session timeout.
  final String? sessionTimeout;

  /// Idle timeout.
  final String? idleTimeout;

  /// Allow only one session per secret.
  final bool onlyOne;

  final String? comment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PppProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PppProfile(id: $id, name: $name)';

  factory PppProfile.fromApiMap(Map<String, String> map) {
    return PppProfile(
      id: map['.id'] ?? '',
      name: map['name'] ?? '',
      localAddress: _nullIfEmpty(map['local-address']),
      remoteAddress: _nullIfEmpty(map['remote-address']),
      rateLimit: _nullIfEmpty(map['rate-limit']),
      sessionTimeout: _nullIfEmpty(map['session-timeout']),
      idleTimeout: _nullIfEmpty(map['idle-timeout']),
      onlyOne: map['only-one'] == 'yes' || map['only-one'] == 'true',
      comment: _nullIfEmpty(map['comment']),
    );
  }
}

// ---------------------------------------------------------------------------
// PppActive
// ---------------------------------------------------------------------------

/// An active PPP session from `/ppp/active/print`.
class PppActive {
  const PppActive({
    required this.id,
    required this.name,
    required this.service,
    required this.address,
    this.uptime,
    this.callerId,
    this.encoding,
    this.sessionId,
    this.limitBytesIn,
    this.limitBytesOut,
    this.comment,
  });

  /// RouterOS `.id`.
  final String id;

  /// Username.
  final String name;

  /// Connection type (pppoe, l2tp, pptp, sstp, ovpn).
  final String service;

  /// Client IP address.
  final String address;

  /// Session uptime string.
  final String? uptime;

  /// Caller ID (phone number / MAC for PPPoE).
  final String? callerId;

  /// Encryption algorithm.
  final String? encoding;

  /// Unique session identifier.
  final String? sessionId;

  final int? limitBytesIn;
  final int? limitBytesOut;

  final String? comment;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PppActive && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'PppActive(id: $id, name: $name, service: $service, address: $address)';

  factory PppActive.fromApiMap(Map<String, String> map) {
    return PppActive(
      id: map['.id'] ?? '',
      name: map['name'] ?? '',
      service: map['service'] ?? '',
      address: map['address'] ?? '',
      uptime: _nullIfEmpty(map['uptime']),
      callerId: _nullIfEmpty(map['caller-id']),
      encoding: _nullIfEmpty(map['encoding']),
      sessionId: _nullIfEmpty(map['session-id']),
      limitBytesIn: _parseInt(map['limit-bytes-in']),
      limitBytesOut: _parseInt(map['limit-bytes-out']),
      comment: _nullIfEmpty(map['comment']),
    );
  }
}

// ---------------------------------------------------------------------------
// PppSecretCreate / PppSecretUpdate
// ---------------------------------------------------------------------------

/// Parameters for creating a new PPP secret.
class PppSecretCreate {
  const PppSecretCreate({
    required this.name,
    required this.password,
    this.service = PppServiceType.any,
    this.profile = 'default',
    this.disabled = false,
    this.comment,
    this.localAddress,
    this.remoteAddress,
    this.callerId,
    this.routes,
  });

  final String name;
  final String password;
  final PppServiceType service;
  final String profile;
  final bool disabled;
  final String? comment;
  final String? localAddress;
  final String? remoteAddress;
  final String? callerId;
  final String? routes;

  /// Convert to RouterOS API parameter map.
  Map<String, String> toApiParams() {
    final m = <String, String>{
      'name': name,
      'password': password,
      'service': service.rosValue,
      'profile': profile,
    };
    if (disabled) m['disabled'] = 'yes';
    if (comment != null && comment!.isNotEmpty) m['comment'] = comment!;
    if (localAddress != null && localAddress!.isNotEmpty) {
      m['local-address'] = localAddress!;
    }
    if (remoteAddress != null && remoteAddress!.isNotEmpty) {
      m['remote-address'] = remoteAddress!;
    }
    if (callerId != null && callerId!.isNotEmpty) {
      m['caller-id'] = callerId!;
    }
    if (routes != null && routes!.isNotEmpty) {
      m['routes'] = routes!;
    }
    return m;
  }
}

/// Parameters for updating an existing PPP secret.
class PppSecretUpdate {
  const PppSecretUpdate({
    this.name,
    this.password,
    this.service,
    this.profile,
    this.disabled,
    this.comment,
    this.localAddress,
    this.remoteAddress,
    this.callerId,
    this.routes,
  });

  final String? name;
  final String? password;
  final PppServiceType? service;
  final String? profile;
  final bool? disabled;
  final String? comment;
  final String? localAddress;
  final String? remoteAddress;
  final String? callerId;
  final String? routes;

  /// Convert to RouterOS API parameter map (only non-null fields).
  Map<String, String> toApiParams() {
    final m = <String, String>{};
    if (name != null) m['name'] = name!;
    if (password != null) m['password'] = password!;
    if (service != null) m['service'] = service!.rosValue;
    if (profile != null) m['profile'] = profile!;
    if (disabled != null) m['disabled'] = disabled! ? 'yes' : 'no';
    if (comment != null) m['comment'] = comment!;
    if (localAddress != null) m['local-address'] = localAddress!;
    if (remoteAddress != null) m['remote-address'] = remoteAddress!;
    if (callerId != null) m['caller-id'] = callerId!;
    if (routes != null) m['routes'] = routes!;
    return m;
  }
}

// ---------------------------------------------------------------------------
// PppData — snapshot for one router
// ---------------------------------------------------------------------------

/// Snapshot of PPP data for one router.
class PppData {
  const PppData({
    required this.routerId,
    required this.secrets,
    required this.profiles,
    required this.activeSessions,
    required this.fetchedAt,
  });

  final String routerId;
  final List<PppSecret> secrets;
  final List<PppProfile> profiles;
  final List<PppActive> activeSessions;
  final DateTime fetchedAt;

  int get totalSecrets => secrets.length;
  int get activeCount => activeSessions.length;
  int get disabledSecrets => secrets.where((s) => s.disabled).length;
}

// ---------------------------------------------------------------------------
// PppSecretValidation
// ---------------------------------------------------------------------------

/// Validation result for PPP secret form fields.
class PppSecretValidation {
  const PppSecretValidation({
    this.nameError,
    this.passwordError,
    this.profileError,
    this.localAddressError,
    this.remoteAddressError,
    this.callerIdError,
  });

  final String? nameError;
  final String? passwordError;
  final String? profileError;
  final String? localAddressError;
  final String? remoteAddressError;
  final String? callerIdError;

  bool get isValid =>
      nameError == null &&
      passwordError == null &&
      profileError == null &&
      localAddressError == null &&
      remoteAddressError == null &&
      callerIdError == null;

  static PppSecretValidation validate(PppSecretCreate params) {
    return PppSecretValidation(
      nameError: validateName(params.name),
      passwordError: validatePassword(params.password),
      profileError: validateProfile(params.profile),
      localAddressError: validateIpOrEmpty(params.localAddress, 'Local address'),
      remoteAddressError: validateIpOrEmpty(params.remoteAddress, 'Remote address'),
      callerIdError: null, // caller-id: any string or empty allowed
    );
  }

  static String? validateName(String name) {
    if (name.trim().isEmpty) return 'Username must not be empty.';
    if (name.length > 64) return 'Username must be at most 64 characters.';
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

  static String? validateIpOrEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) return null;
    // IPv4 or pool name — simple format check for IPv4
    final ipv4Pattern = RegExp(
      r'^(\d{1,3}\.){3}\d{1,3}$',
    );
    // Pool name: alphanumeric + hyphen + underscore allowed
    final poolPattern = RegExp(r'^[a-zA-Z0-9_\-]+$');
    if (!ipv4Pattern.hasMatch(value) && !poolPattern.hasMatch(value)) {
      return '$fieldName must be a valid IPv4 address or pool name.';
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
