/// RouterOS random string generation utilities.
///
/// Ported from Mikhmon v3 `lib/routeros_api.class.php` rand functions:
/// `randN`, `randUC`, `randLC`, `randULC`, `randNLC`, `randNUC`, `randNULC`.
///
/// Uses [Random.secure()] — cryptographically suitable for voucher codes.
library;

import 'dart:math';

/// Generates random strings for RouterOS credential and voucher use.
///
/// All methods use [Random.secure()] for cryptographically random output.
/// Character sets exclude ambiguous characters (0/O, 1/l/I) to improve
/// human readability when printed on vouchers.
abstract final class RouterosRandom {
  // Character sets — ambiguous chars excluded for readability
  static const String _digits = '23456789';
  static const String _lower = 'abcdefghjkmnpqrstuvwxyz';
  static const String _upper = 'ABCDEFGHJKMNPQRSTUVWXYZ';

  static final Random _random = Random.secure();

  RouterosRandom._();

  /// Generates a random string of [length] digits only.
  ///
  /// Charset: `23456789` (excludes 0 and 1 for readability).
  static String digits(int length) => _generate(_digits, length);

  /// Generates a random string of [length] uppercase letters only.
  static String upper(int length) => _generate(_upper, length);

  /// Generates a random string of [length] lowercase letters only.
  static String lower(int length) => _generate(_lower, length);

  /// Generates a random string of [length] mixed-case letters.
  static String mixed(int length) => _generate('$_lower$_upper', length);

  /// Generates a random string of [length] digits and lowercase letters.
  static String digitLower(int length) => _generate('$_digits$_lower', length);

  /// Generates a random string of [length] digits and uppercase letters.
  static String digitUpper(int length) => _generate('$_digits$_upper', length);

  /// Generates a random string of [length] digits, lowercase, and uppercase.
  static String digitMixed(int length) =>
      _generate('$_digits$_lower$_upper', length);

  static String _generate(String charset, int length) {
    if (length <= 0) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(charset[_random.nextInt(charset.length)]);
    }
    return buffer.toString();
  }
}
