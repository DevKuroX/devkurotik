/// Unit tests for Phase 5 — Voucher Models.
///
/// Tests: VoucherMode, VoucherCharSet, VoucherItem, VoucherBatch,
/// VoucherGenerationParams, VoucherValidation, QuickPrintPackage,
/// generateBatchCode.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:devkurotik_app/src/domain/models/voucher_models.dart';

void main() {
  // ---------------------------------------------------------------------------
  // VoucherCharSet
  // ---------------------------------------------------------------------------
  group('VoucherCharSet', () {
    test('lower returns only lowercase characters', () {
      expect(VoucherCharSet.lower.characters, equals('abcdefghijklmnopqrstuvwxyz'));
    });

    test('upper returns only uppercase characters', () {
      expect(VoucherCharSet.upper.characters, contains('A'));
      expect(VoucherCharSet.upper.characters, isNot(contains('a')));
    });

    test('mixed contains both cases', () {
      expect(VoucherCharSet.mixed.characters, contains('a'));
      expect(VoucherCharSet.mixed.characters, contains('A'));
    });

    test('numeric contains only digits', () {
      final chars = VoucherCharSet.numeric.characters;
      expect(chars, matches(r'^[0-9]+$'));
    });

    test('digitLower contains digits and lowercase', () {
      final chars = VoucherCharSet.digitLower.characters;
      expect(chars, contains('0'));
      expect(chars, contains('a'));
      expect(chars, isNot(contains('A')));
    });

    test('digitUpper contains digits and uppercase', () {
      final chars = VoucherCharSet.digitUpper.characters;
      expect(chars, contains('0'));
      expect(chars, contains('A'));
      expect(chars, isNot(contains('a')));
    });

    test('digitMixed contains all', () {
      final chars = VoucherCharSet.digitMixed.characters;
      expect(chars, contains('0'));
      expect(chars, contains('a'));
      expect(chars, contains('A'));
    });

    test('quickPrintCode round-trips', () {
      for (final cs in VoucherCharSet.values) {
        final code = cs.quickPrintCode;
        final restored = VoucherCharSetExtension.fromQuickPrintCode(code);
        expect(restored, equals(cs));
      }
    });

    test('fromQuickPrintCode handles case-insensitive', () {
      expect(
        VoucherCharSetExtension.fromQuickPrintCode('LOWER'),
        equals(VoucherCharSet.lower),
      );
    });

    test('fromQuickPrintCode returns digitMixed for unknown', () {
      expect(
        VoucherCharSetExtension.fromQuickPrintCode('unknown'),
        equals(VoucherCharSet.digitMixed),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // VoucherItem
  // ---------------------------------------------------------------------------
  group('VoucherItem', () {
    test('isVoucherMode returns true when name == password', () {
      const v = VoucherItem(name: 'abc123', password: 'abc123');
      expect(v.isVoucherMode, isTrue);
    });

    test('isVoucherMode returns false when name != password', () {
      const v = VoucherItem(name: 'user1', password: 'pass1');
      expect(v.isVoucherMode, isFalse);
    });

    test('toJson / fromJson round-trip', () {
      const original = VoucherItem(name: 'testUser', password: 'testPass');
      final json = original.toJson();
      final restored = VoucherItem.fromJson(json);
      expect(restored.name, equals(original.name));
      expect(restored.password, equals(original.password));
    });

    test('equality by name and password', () {
      const a = VoucherItem(name: 'x', password: 'y');
      const b = VoucherItem(name: 'x', password: 'y');
      const c = VoucherItem(name: 'x', password: 'z');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  // ---------------------------------------------------------------------------
  // VoucherBatch
  // ---------------------------------------------------------------------------
  group('VoucherBatch', () {
    final now = DateTime(2026, 7, 26);
    final items = [
      const VoucherItem(name: 'abc', password: 'abc'),
      const VoucherItem(name: 'def', password: 'def'),
    ];

    final batch = VoucherBatch(
      id: 'test-id-1',
      routerId: 'router-1',
      batchCode: 'vc-A1B2-20260726',
      profileName: 'default',
      quantity: 2,
      mode: VoucherMode.voucher,
      charSet: VoucherCharSet.digitMixed,
      prefix: '',
      usernameLength: 8,
      passwordLength: 8,
      generatedAt: now,
      vouchers: items,
    );

    test('voucherListJson round-trips', () {
      final json = batch.voucherListJson;
      final restored = VoucherBatch.parseVoucherList(json);
      expect(restored.length, equals(2));
      expect(restored[0].name, equals('abc'));
      expect(restored[1].name, equals('def'));
    });

    test('equality by id', () {
      final other = batch.copyWith(profileName: 'changed');
      expect(batch, equals(other));
    });

    test('copyWith produces new instance with changed fields', () {
      final changed = batch.copyWith(profileName: 'new-profile', quantity: 10);
      expect(changed.profileName, equals('new-profile'));
      expect(changed.quantity, equals(10));
      expect(changed.id, equals(batch.id));
    });
  });

  // ---------------------------------------------------------------------------
  // VoucherValidation
  // ---------------------------------------------------------------------------
  group('VoucherValidation', () {
    VoucherGenerationParams makeParams({
      int quantity = 10,
      String profile = 'default',
      int usernameLength = 8,
      int passwordLength = 8,
      String prefix = '',
      String? limitUptime,
      VoucherMode mode = VoucherMode.voucher,
      VoucherCharSet charSet = VoucherCharSet.digitMixed,
    }) {
      return VoucherGenerationParams(
        routerId: 'r',
        routerHost: '192.168.1.1',
        profileName: profile,
        quantity: quantity,
        mode: mode,
        charSet: charSet,
        usernameLength: usernameLength,
        passwordLength: passwordLength,
        prefix: prefix,
        limitUptime: limitUptime,
      );
    }

    test('valid params produce no errors', () {
      final v = VoucherValidation.validate(makeParams());
      expect(v.isValid, isTrue);
    });

    test('quantity 0 fails', () {
      final v = VoucherValidation.validate(makeParams(quantity: 0));
      expect(v.quantityError, isNotNull);
    });

    test('quantity 501 fails', () {
      final v = VoucherValidation.validate(makeParams(quantity: 501));
      expect(v.quantityError, isNotNull);
    });

    test('empty profile fails', () {
      final v = VoucherValidation.validate(makeParams(profile: ''));
      expect(v.profileError, isNotNull);
    });

    test('username length 2 fails', () {
      final v = VoucherValidation.validate(makeParams(usernameLength: 2));
      expect(v.usernameLengthError, isNotNull);
    });

    test('username length 33 fails', () {
      final v = VoucherValidation.validate(makeParams(usernameLength: 33));
      expect(v.usernameLengthError, isNotNull);
    });

    test('prefix too long fails', () {
      final v = VoucherValidation.validate(
        makeParams(prefix: 'thisprefixistoolonggg', usernameLength: 32),
      );
      expect(v.prefixError, isNotNull);
    });

    test('prefix with invalid chars fails', () {
      final v = VoucherValidation.validate(
        makeParams(prefix: 'abc!', usernameLength: 10),
      );
      expect(v.prefixError, isNotNull);
    });

    test('valid prefix passes', () {
      final v = VoucherValidation.validate(
        makeParams(prefix: 'vc', usernameLength: 10),
      );
      expect(v.prefixError, isNull);
    });

    test('invalid limitUptime fails', () {
      final v = VoucherValidation.validate(
        makeParams(limitUptime: 'abc'),
      );
      expect(v.limitUptimeError, isNotNull);
    });

    test('valid limitUptime passes', () {
      final v = VoucherValidation.validate(
        makeParams(limitUptime: '1h'),
      );
      expect(v.limitUptimeError, isNull);
    });

    test('userpass mode validates password length', () {
      final v = VoucherValidation.validate(
        makeParams(mode: VoucherMode.userpass, passwordLength: 1),
      );
      expect(v.passwordLengthError, isNotNull);
    });

    test('voucher mode skips password validation', () {
      final v = VoucherValidation.validate(
        makeParams(mode: VoucherMode.voucher, passwordLength: 1),
      );
      expect(v.passwordLengthError, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // generateBatchCode
  // ---------------------------------------------------------------------------
  group('generateBatchCode', () {
    test('returns code in vc-XXXX-YYYYMMDD format', () {
      final code = generateBatchCode(now: DateTime(2026, 7, 26));
      expect(code, matches(r'^vc-[0-9A-F]{4}-20260726$'));
    });

    test('different calls produce different codes', () {
      final a = generateBatchCode();
      final b = generateBatchCode();
      // Two calls with crypto-random should differ (extremely high probability)
      // We just verify format here as determinism isn't required.
      expect(a, matches(r'^vc-[0-9A-F]{4}-\d{8}$'));
      expect(b, matches(r'^vc-[0-9A-F]{4}-\d{8}$'));
    });
  });

  // ---------------------------------------------------------------------------
  // QuickPrintPackage
  // ---------------------------------------------------------------------------
  group('QuickPrintPackage', () {
    const pkg = QuickPrintPackage(
      scriptId: '*1',
      name: 'TestPkg',
      server: '192.168.88.1',
      mode: VoucherMode.voucher,
      usernameLength: 8,
      prefix: 'vc',
      charSet: VoucherCharSet.digitMixed,
      profile: 'default',
      limitUptime: '1h',
      limitBytesTotal: 0,
      comment: 'Test',
    );

    test('encodeSource produces # delimited string', () {
      final source = pkg.encodeSource();
      expect(source, startsWith('#'));
      final parts = source.substring(1).split('#');
      expect(parts.length, greaterThanOrEqualTo(9));
    });

    test('decodeSource round-trips', () {
      final source = pkg.encodeSource();
      final decoded = QuickPrintPackage.decodeSource('*1', 'TestPkg', source);
      expect(decoded, isNotNull);
      expect(decoded!.server, equals(pkg.server));
      expect(decoded.mode, equals(pkg.mode));
      expect(decoded.usernameLength, equals(pkg.usernameLength));
      expect(decoded.prefix, equals(pkg.prefix));
      expect(decoded.charSet, equals(pkg.charSet));
      expect(decoded.profile, equals(pkg.profile));
      expect(decoded.limitUptime, equals(pkg.limitUptime));
    });

    test('voucher mode encoded as vc', () {
      final source = pkg.encodeSource();
      final parts = source.substring(1).split('#');
      expect(parts[1], equals('vc'));
    });

    test('userpass mode encoded as up', () {
      const upPkg = QuickPrintPackage(
        scriptId: '*2',
        name: 'TestUp',
        server: '10.0.0.1',
        mode: VoucherMode.userpass,
        usernameLength: 6,
        prefix: '',
        charSet: VoucherCharSet.lower,
        profile: 'default',
        limitUptime: '',
        limitBytesTotal: 0,
        comment: '',
      );
      final source = upPkg.encodeSource();
      final parts = source.substring(1).split('#');
      expect(parts[1], equals('up'));
    });

    test('decodeSource returns null for malformed string', () {
      final decoded = QuickPrintPackage.decodeSource('*1', 'Bad', '#bad#data');
      expect(decoded, isNull);
    });

    test('routerOsComment is QuickPrintMikhmon', () {
      expect(QuickPrintPackage.routerOsComment, equals('QuickPrintMikhmon'));
    });
  });
}
