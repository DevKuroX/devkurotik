/// Phase 5 — Voucher Engine domain models.
///
/// All models are immutable value types.
/// Voucher passwords are the product being generated — NOT router admin passwords.
library;

import 'dart:convert';
import 'dart:math' as math;

// ---------------------------------------------------------------------------
// Enumerations
// ---------------------------------------------------------------------------

/// Voucher generation mode.
enum VoucherMode {
  /// Username equals password (voucher mode — single string printed).
  voucher,

  /// Username and password are separate (userpass mode).
  userpass,
}

/// Character set for username/password generation.
enum VoucherCharSet {
  /// Lowercase letters only (a–z).
  lower,

  /// Uppercase letters only (A–Z).
  upper,

  /// Mixed case letters (a–z + A–Z).
  mixed,

  /// Digits only (0–9).
  numeric,

  /// Digits + lowercase letters (0–9 + a–z).
  digitLower,

  /// Digits + uppercase letters (0–9 + A–Z).
  digitUpper,

  /// Digits + mixed case letters (0–9 + a–z + A–Z).
  digitMixed,
}

extension VoucherCharSetExtension on VoucherCharSet {
  /// Returns the actual character pool for this charset.
  String get characters {
    switch (this) {
      case VoucherCharSet.lower:
        return 'abcdefghijklmnopqrstuvwxyz';
      case VoucherCharSet.upper:
        return 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      case VoucherCharSet.mixed:
        return 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
      case VoucherCharSet.numeric:
        return '0123456789';
      case VoucherCharSet.digitLower:
        return '0123456789abcdefghijklmnopqrstuvwxyz';
      case VoucherCharSet.digitUpper:
        return '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      case VoucherCharSet.digitMixed:
        return '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    }
  }

  /// Display label for UI.
  String get label {
    switch (this) {
      case VoucherCharSet.lower:
        return 'Lowercase (a–z)';
      case VoucherCharSet.upper:
        return 'Uppercase (A–Z)';
      case VoucherCharSet.mixed:
        return 'Mixed (a–z + A–Z)';
      case VoucherCharSet.numeric:
        return 'Numeric (0–9)';
      case VoucherCharSet.digitLower:
        return 'Digit + Lower';
      case VoucherCharSet.digitUpper:
        return 'Digit + Upper';
      case VoucherCharSet.digitMixed:
        return 'Digit + Mixed';
    }
  }

  /// Quick Print encoding char (from Mikhmon convention).
  String get quickPrintCode {
    switch (this) {
      case VoucherCharSet.lower:
        return 'lower';
      case VoucherCharSet.upper:
        return 'upper';
      case VoucherCharSet.mixed:
        return 'mixed';
      case VoucherCharSet.numeric:
        return 'numeric';
      case VoucherCharSet.digitLower:
        return 'digitLower';
      case VoucherCharSet.digitUpper:
        return 'digitUpper';
      case VoucherCharSet.digitMixed:
        return 'digitMixed';
    }
  }

  /// Parse from Quick Print code string.
  static VoucherCharSet fromQuickPrintCode(String code) {
    switch (code.toLowerCase()) {
      case 'lower':
        return VoucherCharSet.lower;
      case 'upper':
        return VoucherCharSet.upper;
      case 'mixed':
        return VoucherCharSet.mixed;
      case 'numeric':
        return VoucherCharSet.numeric;
      case 'digitlower':
        return VoucherCharSet.digitLower;
      case 'digitupper':
        return VoucherCharSet.digitUpper;
      case 'digitmixed':
        return VoucherCharSet.digitMixed;
      default:
        return VoucherCharSet.digitMixed;
    }
  }
}

/// Voucher rendering template.
enum VoucherTemplate {
  /// Default 220px-wide layout.
  default220,

  /// Thermal 180px-wide compact layout with timestamp.
  thermal180,

  /// Small 160px-wide ultra-compact layout.
  small160,
}

extension VoucherTemplateExtension on VoucherTemplate {
  String get label {
    switch (this) {
      case VoucherTemplate.default220:
        return 'Default (220px)';
      case VoucherTemplate.thermal180:
        return 'Thermal (180px)';
      case VoucherTemplate.small160:
        return 'Small (160px)';
    }
  }

  double get widthMm {
    switch (this) {
      case VoucherTemplate.default220:
        return 58.0; // ~220px at 96dpi
      case VoucherTemplate.thermal180:
        return 48.0; // ~180px at 96dpi
      case VoucherTemplate.small160:
        return 42.0; // ~160px at 96dpi
    }
  }
}

// ---------------------------------------------------------------------------
// VoucherItem
// ---------------------------------------------------------------------------

/// A single generated voucher credential pair.
///
/// The [password] here is the VOUCHER product credential,
/// NOT any router admin password.
class VoucherItem {
  const VoucherItem({required this.name, required this.password});

  /// Voucher username (printed on the voucher).
  final String name;

  /// Voucher password (the product — safe to store locally).
  final String password;

  /// Returns true if mode is voucher (user==pass).
  bool get isVoucherMode => name == password;

  /// Encode as JSON map.
  Map<String, dynamic> toJson() => {'name': name, 'password': password};

  /// Decode from JSON map.
  factory VoucherItem.fromJson(Map<String, dynamic> json) {
    return VoucherItem(
      name: json['name'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoucherItem &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          password == other.password;

  @override
  int get hashCode => Object.hash(name, password);

  @override
  String toString() => 'VoucherItem(name: $name)';
}

// ---------------------------------------------------------------------------
// VoucherBatch
// ---------------------------------------------------------------------------

/// A complete generated voucher batch with all metadata and items.
///
/// Corresponds 1:1 with VoucherBatchTable in SQLite.
class VoucherBatch {
  const VoucherBatch({
    required this.id,
    required this.routerId,
    required this.batchCode,
    required this.profileName,
    required this.quantity,
    required this.mode,
    required this.charSet,
    required this.prefix,
    required this.usernameLength,
    required this.passwordLength,
    required this.generatedAt,
    required this.vouchers,
    this.limitUptime,
    this.comment,
  });

  final String id;
  final String routerId;
  final String batchCode;
  final String profileName;
  final int quantity;
  final VoucherMode mode;
  final VoucherCharSet charSet;
  final String prefix;
  final int usernameLength;
  final int passwordLength;
  final DateTime generatedAt;
  final List<VoucherItem> vouchers;
  final String? limitUptime;
  final String? comment;

  /// Serialize voucher list to JSON string for SQLite storage.
  String get voucherListJson =>
      jsonEncode(vouchers.map((v) => v.toJson()).toList());

  /// Parse voucher list from JSON string.
  static List<VoucherItem> parseVoucherList(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => VoucherItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  VoucherBatch copyWith({
    String? id,
    String? routerId,
    String? batchCode,
    String? profileName,
    int? quantity,
    VoucherMode? mode,
    VoucherCharSet? charSet,
    String? prefix,
    int? usernameLength,
    int? passwordLength,
    DateTime? generatedAt,
    List<VoucherItem>? vouchers,
    String? limitUptime,
    String? comment,
  }) {
    return VoucherBatch(
      id: id ?? this.id,
      routerId: routerId ?? this.routerId,
      batchCode: batchCode ?? this.batchCode,
      profileName: profileName ?? this.profileName,
      quantity: quantity ?? this.quantity,
      mode: mode ?? this.mode,
      charSet: charSet ?? this.charSet,
      prefix: prefix ?? this.prefix,
      usernameLength: usernameLength ?? this.usernameLength,
      passwordLength: passwordLength ?? this.passwordLength,
      generatedAt: generatedAt ?? this.generatedAt,
      vouchers: vouchers ?? this.vouchers,
      limitUptime: limitUptime ?? this.limitUptime,
      comment: comment ?? this.comment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoucherBatch &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'VoucherBatch(id: $id, batchCode: $batchCode, qty: $quantity)';
}

// ---------------------------------------------------------------------------
// VoucherGenerationParams
// ---------------------------------------------------------------------------

/// Parameters for a voucher generation request.
class VoucherGenerationParams {
  const VoucherGenerationParams({
    required this.routerId,
    required this.routerHost,
    required this.profileName,
    required this.quantity,
    required this.mode,
    required this.charSet,
    required this.usernameLength,
    required this.passwordLength,
    this.prefix = '',
    this.limitUptime,
    this.comment,
    this.server = 'all',
  });

  final String routerId;
  final String routerHost;
  final String profileName;
  final int quantity;
  final VoucherMode mode;
  final VoucherCharSet charSet;
  final int usernameLength;
  final int passwordLength;
  final String prefix;
  final String? limitUptime;
  final String? comment;
  final String server;

  VoucherGenerationParams copyWith({
    String? routerId,
    String? routerHost,
    String? profileName,
    int? quantity,
    VoucherMode? mode,
    VoucherCharSet? charSet,
    int? usernameLength,
    int? passwordLength,
    String? prefix,
    String? limitUptime,
    String? comment,
    String? server,
  }) {
    return VoucherGenerationParams(
      routerId: routerId ?? this.routerId,
      routerHost: routerHost ?? this.routerHost,
      profileName: profileName ?? this.profileName,
      quantity: quantity ?? this.quantity,
      mode: mode ?? this.mode,
      charSet: charSet ?? this.charSet,
      usernameLength: usernameLength ?? this.usernameLength,
      passwordLength: passwordLength ?? this.passwordLength,
      prefix: prefix ?? this.prefix,
      limitUptime: limitUptime ?? this.limitUptime,
      comment: comment ?? this.comment,
      server: server ?? this.server,
    );
  }
}

// ---------------------------------------------------------------------------
// VoucherValidation
// ---------------------------------------------------------------------------

/// Validation result for voucher generation params.
class VoucherValidation {
  const VoucherValidation({
    this.quantityError,
    this.profileError,
    this.usernameLengthError,
    this.passwordLengthError,
    this.prefixError,
    this.limitUptimeError,
  });

  final String? quantityError;
  final String? profileError;
  final String? usernameLengthError;
  final String? passwordLengthError;
  final String? prefixError;
  final String? limitUptimeError;

  bool get isValid =>
      quantityError == null &&
      profileError == null &&
      usernameLengthError == null &&
      passwordLengthError == null &&
      prefixError == null &&
      limitUptimeError == null;

  static VoucherValidation validate(VoucherGenerationParams p) {
    return VoucherValidation(
      quantityError: _validateQuantity(p.quantity),
      profileError: _validateProfile(p.profileName),
      usernameLengthError: _validateUsernameLength(
        p.usernameLength,
        p.prefix,
        p.charSet,
      ),
      passwordLengthError:
          p.mode == VoucherMode.userpass
              ? _validatePasswordLength(p.passwordLength, p.charSet)
              : null,
      prefixError: _validatePrefix(p.prefix),
      limitUptimeError: _validateLimitUptime(p.limitUptime),
    );
  }

  static String? _validateQuantity(int qty) {
    if (qty < 1) return 'Quantity must be at least 1.';
    if (qty > 500) return 'Quantity must not exceed 500.';
    return null;
  }

  static String? _validateProfile(String profile) {
    if (profile.trim().isEmpty) return 'Profile must not be empty.';
    return null;
  }

  static String? _validateUsernameLength(
    int length,
    String prefix,
    VoucherCharSet charSet,
  ) {
    final effectiveLength = length - prefix.length;
    if (effectiveLength < 1) {
      return 'Username length must leave at least 1 char after prefix.';
    }
    if (length < 3) return 'Username length must be at least 3.';
    if (length > 32) return 'Username length must not exceed 32.';
    if (charSet.characters.isEmpty) return 'Character set is empty.';
    return null;
  }

  static String? _validatePasswordLength(int length, VoucherCharSet charSet) {
    if (length < 3) return 'Password length must be at least 3.';
    if (length > 32) return 'Password length must not exceed 32.';
    if (charSet.characters.isEmpty) return 'Character set is empty.';
    return null;
  }

  static String? validatePrefix(String prefix) {
    return _validatePrefix(prefix);
  }

  static String? validateLimitUptime(String? lu) {
    return _validateLimitUptime(lu);
  }

  static String? _validatePrefix(String prefix) {
    if (prefix.isEmpty) return null;
    if (prefix.length > 16) return 'Prefix must not exceed 16 characters.';
    final allowed = RegExp(r'^[a-zA-Z0-9._\-]+$');
    if (!allowed.hasMatch(prefix)) {
      return 'Prefix contains invalid characters.';
    }
    return null;
  }

  static String? _validateLimitUptime(String? lu) {
    if (lu == null || lu.isEmpty) return null;
    final pattern = RegExp(
      r'^(\d+w)?(\d+d)?(\d+h)?(\d+m)?(\d+s)?$',
      caseSensitive: false,
    );
    if (!pattern.hasMatch(lu)) {
      return 'Invalid uptime format. Use e.g. 1h, 2h30m, 1d.';
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// QuickPrintPackage
// ---------------------------------------------------------------------------

/// A Quick Print package configuration, stored on the router as a
/// `/system/script` entry with `comment = "QuickPrintMikhmon"`.
///
/// The script `source` field uses # as delimiter:
/// "#server#mode#length#prefix#charSet#profile#limitUptime#limitBytesTotal#comment"
///
/// Positions:
///  [0] = server (router IP, for display)
///  [1] = mode ('vc' = voucher / 'up' = userpass)
///  [2] = usernameLength
///  [3] = prefix
///  [4] = charSet (Quick Print code)
///  [5] = profile
///  [6] = limitUptime
///  [7] = limitBytesTotal (as string integer, "0" = none)
///  [8] = user comment
class QuickPrintPackage {
  const QuickPrintPackage({
    required this.scriptId,
    required this.name,
    required this.server,
    required this.mode,
    required this.usernameLength,
    required this.prefix,
    required this.charSet,
    required this.profile,
    required this.limitUptime,
    required this.limitBytesTotal,
    required this.comment,
  });

  /// RouterOS script `.id`.
  final String scriptId;

  /// RouterOS script name (display name).
  final String name;

  /// Server / router IP display.
  final String server;

  /// Generation mode.
  final VoucherMode mode;

  /// Username (and password in voucher mode) length.
  final int usernameLength;

  /// Username prefix.
  final String prefix;

  /// Character set.
  final VoucherCharSet charSet;

  /// Profile name.
  final String profile;

  /// Limit uptime string.
  final String limitUptime;

  /// Limit bytes total (0 = none).
  final int limitBytesTotal;

  /// User comment.
  final String comment;

  /// The special comment field that marks this as a Quick Print package.
  static const routerOsComment = 'QuickPrintMikhmon';

  /// Encode to the # delimited source field string.
  String encodeSource() {
    final modeCode = mode == VoucherMode.voucher ? 'vc' : 'up';
    return '#$server#$modeCode#$usernameLength#$prefix#${charSet.quickPrintCode}'
        '#$profile#$limitUptime#$limitBytesTotal#$comment';
  }

  /// Decode from # delimited source string.
  static QuickPrintPackage? decodeSource(
    String scriptId,
    String scriptName,
    String source,
  ) {
    // Source starts with '#'
    final raw = source.startsWith('#') ? source.substring(1) : source;
    final parts = raw.split('#');
    if (parts.length < 8) return null;
    final server = parts[0];
    final modeCode = parts[1];
    final usernameLength = int.tryParse(parts[2]) ?? 5;
    final prefix = parts[3];
    final charSet = VoucherCharSetExtension.fromQuickPrintCode(parts[4]);
    final profile = parts[5];
    final limitUptime = parts[6];
    final limitBytesTotal = int.tryParse(parts[7]) ?? 0;
    final comment = parts.length > 8 ? parts[8] : '';
    final mode =
        modeCode == 'vc' ? VoucherMode.voucher : VoucherMode.userpass;
    return QuickPrintPackage(
      scriptId: scriptId,
      name: scriptName,
      server: server,
      mode: mode,
      usernameLength: usernameLength,
      prefix: prefix,
      charSet: charSet,
      profile: profile,
      limitUptime: limitUptime,
      limitBytesTotal: limitBytesTotal,
      comment: comment,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuickPrintPackage &&
          runtimeType == other.runtimeType &&
          scriptId == other.scriptId;

  @override
  int get hashCode => scriptId.hashCode;

  @override
  String toString() => 'QuickPrintPackage(id: $scriptId, name: $name)';
}

// ---------------------------------------------------------------------------
// Private random generation helper (test-injectable)
// ---------------------------------------------------------------------------

/// Generates a random string of [length] from the given [chars].
String generateRandomString(String chars, int length, {math.Random? rng}) {
  final r = rng ?? math.Random.secure();
  return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
}

/// Generates a batch code like "vc-A7F2-20260726".
String generateBatchCode({DateTime? now, math.Random? rng}) {
  final n = now ?? DateTime.now();
  final r = rng ?? math.Random.secure();
  const hexChars = '0123456789ABCDEF';
  final rand = List.generate(4, (_) => hexChars[r.nextInt(16)]).join();
  final date =
      '${n.year}'
      '${n.month.toString().padLeft(2, '0')}'
      '${n.day.toString().padLeft(2, '0')}';
  return 'vc-$rand-$date';
}
