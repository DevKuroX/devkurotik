/// Phase 6 — Profile domain models.
///
/// Defines the on-login metadata specification, expiry modes, and profile
/// structures required for Mikhmon-compatible RouterScript generation.
///
/// CANONICAL SPECIFICATION (derived from Mikhmon v3 adduserprofile.php):
///
/// on-login script comma positions:
///   [0] = RouterScript preamble (`:put ("`)
///   [1] = expiry mode token: rem | ntf | remc | ntfc | (empty for none)
///   [2] = price (IDR amount string, "0" when not set)
///   [3] = validity string (e.g. "1d", "1 Day")
///   [4] = selling price string, "0" when not set
///   [5] = (empty — reserved)
///   [6] = lock setting: "lock" / "nolock" / "Enable" / "Disable" / (empty)
///   [7] = (trailing — reserved)
///
/// None-mode with price uses alternate format:
///   `:put (",," + price + ",,,noexp," + lockStr + ",")`
///
/// Empty on-login ("") when mode=none AND price is empty.
library;

/// Expiry mode as stored in Mikhmon on-login metadata.
enum ExpiryMode {
  /// No expiry. On-login may be empty or contain price-only metadata.
  none,

  /// Remove user when expired.
  /// Mikhmon token: "rem"
  remove,

  /// Set limit-uptime=1s when expired (notice/mark).
  /// Mikhmon token: "ntf"
  notice,

  /// Remove user + record sale when expired.
  /// Mikhmon token: "remc"
  removeRecord,

  /// Set limit-uptime=1s + record sale when expired.
  /// Mikhmon token: "ntfc"
  noticeRecord;

  /// Returns the canonical Mikhmon token for this mode.
  String get token {
    switch (this) {
      case ExpiryMode.none:
        return '0';
      case ExpiryMode.remove:
        return 'rem';
      case ExpiryMode.notice:
        return 'ntf';
      case ExpiryMode.removeRecord:
        return 'remc';
      case ExpiryMode.noticeRecord:
        return 'ntfc';
    }
  }

  /// Returns the human-readable display label for this mode.
  String get displayName {
    switch (this) {
      case ExpiryMode.none:
        return 'None';
      case ExpiryMode.remove:
        return 'Remove';
      case ExpiryMode.notice:
        return 'Notice';
      case ExpiryMode.removeRecord:
        return 'Remove & Record';
      case ExpiryMode.noticeRecord:
        return 'Notice & Record';
    }
  }

  /// Parses a Mikhmon on-login token string to an ExpiryMode.
  ///
  /// Returns [ExpiryMode.none] for null, empty, "0", or unknown tokens.
  static ExpiryMode fromToken(String? token) {
    switch (token) {
      case 'rem':
        return ExpiryMode.remove;
      case 'ntf':
        return ExpiryMode.notice;
      case 'remc':
        return ExpiryMode.removeRecord;
      case 'ntfc':
        return ExpiryMode.noticeRecord;
      default:
        return ExpiryMode.none;
    }
  }

  /// Whether this mode produces a background sweep scheduler.
  bool get requiresScheduler =>
      this != ExpiryMode.none;

  /// Whether this mode records a sale entry on expiry.
  bool get recordsSale =>
      this == ExpiryMode.removeRecord || this == ExpiryMode.noticeRecord;

  /// Whether this mode removes the user on expiry.
  bool get removesUser =>
      this == ExpiryMode.remove || this == ExpiryMode.removeRecord;

  /// Whether this mode sets limit-uptime=1s on expiry (notice).
  bool get marksUser =>
      this == ExpiryMode.notice || this == ExpiryMode.noticeRecord;
}

/// Parsed metadata extracted from a Mikhmon on-login script.
class OnLoginMetadata {
  const OnLoginMetadata({
    required this.mode,
    required this.price,
    required this.validity,
    required this.sellingPrice,
    required this.macLock,
  });

  /// The expiry mode.
  final ExpiryMode mode;

  /// Price string as stored at position [2]. "0" when not set.
  final String price;

  /// Validity string at position [3] (e.g. "1d", "1 Day", "00:02:30").
  final String validity;

  /// Selling price at position [4]. "0" when not set.
  final String sellingPrice;

  /// Whether MAC lock is enabled.
  final bool macLock;

  /// Returns price as a displayable string (empty string when "0").
  String get displayPrice => price == '0' ? '' : price;

  /// Returns sellingPrice as displayable string.
  String get displaySellingPrice => sellingPrice == '0' ? '' : sellingPrice;

  /// The raw lock token that was stored at position [6].
  String get lockToken => macLock ? 'Enable' : 'Disable';

  @override
  String toString() =>
      'OnLoginMetadata(mode:${mode.token}, price:$price, validity:$validity, '
      'sprice:$sellingPrice, macLock:$macLock)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnLoginMetadata &&
          mode == other.mode &&
          price == other.price &&
          validity == other.validity &&
          sellingPrice == other.sellingPrice &&
          macLock == other.macLock;

  @override
  int get hashCode => Object.hash(mode, price, validity, sellingPrice, macLock);
}

/// Parameters used to generate an on-login script.
class ProfileScriptParams {
  const ProfileScriptParams({
    required this.profileName,
    required this.mode,
    required this.validity,
    this.price = '0',
    this.sellingPrice = '0',
    this.macLock = false,
  });

  final String profileName;
  final ExpiryMode mode;

  /// Validity string as expected by RouterOS scheduler interval field.
  /// Examples: "1d", "00:01:00", "1 Day"
  final String validity;

  final String price;
  final String sellingPrice;
  final bool macLock;

  /// Validates the parameter set before generation.
  ProfileScriptValidationResult validate() {
    final errors = <String>[];

    if (profileName.trim().isEmpty) {
      errors.add('Profile name must not be empty.');
    }
    if (profileName.contains(' ')) {
      errors.add('Profile name must not contain spaces (use hyphens).');
    }

    if (mode != ExpiryMode.none && validity.trim().isEmpty) {
      errors.add('Validity is required for modes other than none.');
    }

    final priceNum = num.tryParse(price);
    if (priceNum == null || priceNum < 0) {
      errors.add('Price must be a non-negative number or "0".');
    }

    final spriceNum = num.tryParse(sellingPrice);
    if (spriceNum == null || spriceNum < 0) {
      errors.add('Selling price must be a non-negative number or "0".');
    }

    return ProfileScriptValidationResult(errors: errors);
  }
}

/// Result of validating [ProfileScriptParams].
class ProfileScriptValidationResult {
  const ProfileScriptValidationResult({required this.errors});

  final List<String> errors;

  bool get isValid => errors.isEmpty;

  @override
  String toString() => isValid
      ? 'ProfileScriptValidationResult(valid)'
      : 'ProfileScriptValidationResult(errors: $errors)';
}

/// Result of generating a profile script set.
class ProfileScriptResult {
  const ProfileScriptResult({
    required this.onLogin,
    required this.bgService,
    required this.mode,
    required this.params,
  });

  /// The on-login RouterScript string to write to the profile.
  final String onLogin;

  /// The background sweep scheduler on-event script.
  /// Empty string when mode is none.
  final String bgService;

  /// The expiry action mode string for the bgService.
  /// "remove" | "set limit-uptime=1s" | "" (for none)
  final String mode;

  /// The params that produced this result.
  final ProfileScriptParams params;

  /// Whether a scheduler should be created/updated.
  bool get requiresScheduler => bgService.isNotEmpty;

  @override
  String toString() =>
      'ProfileScriptResult(mode:${params.mode.token}, '
      'requiresScheduler:$requiresScheduler)';
}

/// A hotspot user profile with its decoded on-login metadata.
class HotspotProfile {
  const HotspotProfile({
    required this.id,
    required this.name,
    this.rateLimit,
    this.addressPool,
    this.sharedUsers = 1,
    this.parentQueue,
    this.rawOnLogin,
    this.metadata,
  });

  final String id;
  final String name;
  final String? rateLimit;
  final String? addressPool;
  final int sharedUsers;
  final String? parentQueue;

  /// Raw on-login script as returned by RouterOS API.
  final String? rawOnLogin;

  /// Decoded metadata. Null if on-login is empty or not parseable.
  final OnLoginMetadata? metadata;

  factory HotspotProfile.fromApiMap(Map<String, String> map) {
    final rawOnLogin = map['on-login'];
    OnLoginMetadata? metadata;
    if (rawOnLogin != null) {
      // Parse both empty and non-empty on-login (empty → none mode)
      metadata = OnLoginMetadataParser.parseOrNull(rawOnLogin);
    }
    return HotspotProfile(
      id: map['.id'] ?? '',
      name: map['name'] ?? '',
      rateLimit: map['rate-limit'],
      addressPool: map['address-pool'],
      sharedUsers: int.tryParse(map['shared-users'] ?? '1') ?? 1,
      parentQueue: map['parent-queue'],
      rawOnLogin: rawOnLogin,
      metadata: metadata,
    );
  }

  @override
  String toString() => 'HotspotProfile(id:$id, name:$name, '
      'mode:${metadata?.mode.displayName ?? "unknown"})';
}

/// Parser for Mikhmon on-login script metadata.
///
/// Mikhmon stores metadata as comma-delimited values embedded in a
/// `:put (",...")` RouterScript statement.
///
/// Comma positions:
///   [0] = preamble (before first comma)
///   [1] = expiry mode token
///   [2] = price
///   [3] = validity
///   [4] = selling price
///   [5] = reserved (empty)
///   [6] = lock setting
///   [7] = trailing (empty)
class OnLoginMetadataParser {
  OnLoginMetadataParser._();

  /// Parses the on-login script and returns metadata, or null if not parseable.
  ///
  /// This method is safe: it never throws. Returns null for any unexpected input.
  static OnLoginMetadata? parseOrNull(String onLogin) {
    try {
      return _parse(onLogin);
    } catch (_) {
      return null;
    }
  }

  /// Parses the on-login script and returns metadata.
  ///
  /// Throws [OnLoginParseException] for malformed or non-Mikhmon scripts.
  static OnLoginMetadata parse(String onLogin) {
    final result = _parse(onLogin);
    if (result == null) {
      throw OnLoginParseException(
        'Failed to parse on-login metadata.',
        onLogin,
      );
    }
    return result;
  }

  static OnLoginMetadata? _parse(String onLogin) {
    if (onLogin.isEmpty) {
      return const OnLoginMetadata(
        mode: ExpiryMode.none,
        price: '0',
        validity: '',
        sellingPrice: '0',
        macLock: false,
      );
    }

    // Mikhmon scripts always contain a :put ("...") header with comma positions.
    // Find the first comma-delimited section.
    final parts = onLogin.split(',');
    if (parts.length < 7) {
      return null;
    }

    // Position [1] = expiry mode token
    final modeToken = parts[1].trim();
    final mode = ExpiryMode.fromToken(modeToken.isEmpty ? null : modeToken);

    // Position [2] = price
    final price = parts[2].trim().isEmpty ? '0' : parts[2].trim();

    // Position [3] = validity
    final validity = parts[3].trim();

    // Position [4] = selling price
    final sellingPrice = parts[4].trim().isEmpty ? '0' : parts[4].trim();

    // Position [6] = lock setting
    final lockRaw = parts[6].trim();
    final macLock = lockRaw == 'Enable' || lockRaw == 'lock';

    return OnLoginMetadata(
      mode: mode,
      price: price,
      validity: validity,
      sellingPrice: sellingPrice,
      macLock: macLock,
    );
  }
}

/// Thrown when an on-login script cannot be parsed.
class OnLoginParseException implements Exception {
  const OnLoginParseException(this.message, this.rawScript);

  final String message;
  final String rawScript;

  @override
  String toString() => 'OnLoginParseException: $message';
}
