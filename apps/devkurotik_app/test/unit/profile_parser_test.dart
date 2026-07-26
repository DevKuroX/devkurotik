/// Phase 6 — Parser, round-trip, and malformed input tests.
///
/// Tests:
///   - OnLoginMetadataParser: parse all 5 modes from real on-login strings
///   - Round-trip: params → generate → parse → metadata equivalence
///   - Malformed: all invalid/corrupt inputs handled safely
///   - MetadataEncoder: extractPutHeader, hasValidPositions
///   - ExpiryMode: fromToken, token, helpers
///   - ProfileScriptParams: validate
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/profile_models.dart';
import 'package:devkurotik_app/src/domain/services/on_login_script_generator.dart';
import 'package:devkurotik_app/src/domain/services/metadata_encoder.dart';

void main() {
  const gen = OnLoginScriptGenerator();
  const encoder = MetadataEncoder();

  // ─────────────────────────────────────────────────────────────────
  // ExpiryMode tests
  // ─────────────────────────────────────────────────────────────────

  group('ExpiryMode', () {
    test('fromToken: known tokens', () {
      expect(ExpiryMode.fromToken('rem'), ExpiryMode.remove);
      expect(ExpiryMode.fromToken('ntf'), ExpiryMode.notice);
      expect(ExpiryMode.fromToken('remc'), ExpiryMode.removeRecord);
      expect(ExpiryMode.fromToken('ntfc'), ExpiryMode.noticeRecord);
    });

    test('fromToken: none cases', () {
      expect(ExpiryMode.fromToken('0'), ExpiryMode.none);
      expect(ExpiryMode.fromToken(''), ExpiryMode.none);
      expect(ExpiryMode.fromToken(null), ExpiryMode.none);
      expect(ExpiryMode.fromToken('unknown'), ExpiryMode.none);
    });

    test('token round-trip', () {
      for (final m in ExpiryMode.values) {
        if (m == ExpiryMode.none) {
          expect(ExpiryMode.fromToken(m.token), ExpiryMode.none);
        } else {
          expect(ExpiryMode.fromToken(m.token), m);
        }
      }
    });

    test('displayName covers all modes', () {
      expect(ExpiryMode.none.displayName, 'None');
      expect(ExpiryMode.remove.displayName, 'Remove');
      expect(ExpiryMode.notice.displayName, 'Notice');
      expect(ExpiryMode.removeRecord.displayName, 'Remove & Record');
      expect(ExpiryMode.noticeRecord.displayName, 'Notice & Record');
    });

    test('requiresScheduler: expiry modes need scheduler', () {
      expect(ExpiryMode.none.requiresScheduler, isFalse);
      expect(ExpiryMode.remove.requiresScheduler, isTrue);
      expect(ExpiryMode.notice.requiresScheduler, isTrue);
      expect(ExpiryMode.removeRecord.requiresScheduler, isTrue);
      expect(ExpiryMode.noticeRecord.requiresScheduler, isTrue);
    });

    test('recordsSale: only record modes', () {
      expect(ExpiryMode.none.recordsSale, isFalse);
      expect(ExpiryMode.remove.recordsSale, isFalse);
      expect(ExpiryMode.notice.recordsSale, isFalse);
      expect(ExpiryMode.removeRecord.recordsSale, isTrue);
      expect(ExpiryMode.noticeRecord.recordsSale, isTrue);
    });

    test('removesUser: only remove modes', () {
      expect(ExpiryMode.none.removesUser, isFalse);
      expect(ExpiryMode.remove.removesUser, isTrue);
      expect(ExpiryMode.notice.removesUser, isFalse);
      expect(ExpiryMode.removeRecord.removesUser, isTrue);
      expect(ExpiryMode.noticeRecord.removesUser, isFalse);
    });

    test('marksUser: only notice modes', () {
      expect(ExpiryMode.none.marksUser, isFalse);
      expect(ExpiryMode.remove.marksUser, isFalse);
      expect(ExpiryMode.notice.marksUser, isTrue);
      expect(ExpiryMode.removeRecord.marksUser, isFalse);
      expect(ExpiryMode.noticeRecord.marksUser, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // OnLoginMetadataParser tests
  // ─────────────────────────────────────────────────────────────────

  group('OnLoginMetadataParser', () {
    test('parse empty string → none mode, price=0', () {
      final meta = OnLoginMetadataParser.parse('');
      expect(meta.mode, ExpiryMode.none);
      expect(meta.price, '0');
      expect(meta.validity, '');
      expect(meta.sellingPrice, '0');
      expect(meta.macLock, isFalse);
    });

    test('parse none+price on-login', () {
      const onLogin = ':put (",,5000,,,noexp,Disable,"); ';
      final meta = OnLoginMetadataParser.parseOrNull(onLogin);
      expect(meta, isNotNull);
      expect(meta!.mode, ExpiryMode.none);
      expect(meta.price, '5000');
    });

    test('parse remove on-login', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
      final meta = OnLoginMetadataParser.parse(result.onLogin);
      expect(meta.mode, ExpiryMode.remove);
      expect(meta.price, '5000');
      expect(meta.validity, '1d');
      expect(meta.sellingPrice, '5000');
      expect(meta.macLock, isFalse);
    });

    test('parse notice on-login', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.notice,
        validity: '1d',
        price: '3000',
        sellingPrice: '2500',
      ));
      final meta = OnLoginMetadataParser.parse(result.onLogin);
      expect(meta.mode, ExpiryMode.notice);
      expect(meta.price, '3000');
      expect(meta.sellingPrice, '2500');
    });

    test('parse removeRecord on-login', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.removeRecord,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
      final meta = OnLoginMetadataParser.parse(result.onLogin);
      expect(meta.mode, ExpiryMode.removeRecord);
    });

    test('parse noticeRecord on-login', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.noticeRecord,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
      final meta = OnLoginMetadataParser.parse(result.onLogin);
      expect(meta.mode, ExpiryMode.noticeRecord);
    });

    test('parse macLock=true from on-login', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
        macLock: true,
      ));
      final meta = OnLoginMetadataParser.parse(result.onLogin);
      expect(meta.macLock, isTrue);
    });

    test('parse macLock=false from on-login', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
        macLock: false,
      ));
      final meta = OnLoginMetadataParser.parse(result.onLogin);
      expect(meta.macLock, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Round-trip tests
  // ─────────────────────────────────────────────────────────────────

  group('Round-trip: params → generate → parse', () {
    void roundTrip(ProfileScriptParams params) {
      final result = gen.generate(params);
      final parsed = OnLoginMetadataParser.parseOrNull(result.onLogin);

      expect(parsed, isNotNull,
          reason: 'Mode ${params.mode.token}: parseOrNull must not return null');
      expect(parsed!.mode, params.mode,
          reason: 'Mode ${params.mode.token}: mode round-trip failed');
      expect(parsed.price, params.price.isEmpty ? '0' : params.price,
          reason: 'Mode ${params.mode.token}: price round-trip failed');
      expect(parsed.macLock, params.macLock,
          reason: 'Mode ${params.mode.token}: macLock round-trip failed');
    }

    test('round-trip: none+noprice', () {
      roundTrip(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.none,
        validity: '',
        price: '0',
        sellingPrice: '0',
      ));
    });

    test('round-trip: none+price', () {
      roundTrip(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.none,
        validity: '',
        price: '5000',
        sellingPrice: '0',
      ));
    });

    test('round-trip: remove', () {
      roundTrip(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
    });

    test('round-trip: notice', () {
      roundTrip(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.notice,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
    });

    test('round-trip: removeRecord', () {
      roundTrip(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.removeRecord,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
    });

    test('round-trip: noticeRecord', () {
      roundTrip(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.noticeRecord,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
    });

    test('round-trip: macLock=true through all expiry modes', () {
      for (final mode in [
        ExpiryMode.remove,
        ExpiryMode.notice,
        ExpiryMode.removeRecord,
        ExpiryMode.noticeRecord,
      ]) {
        roundTrip(ProfileScriptParams(
          profileName: 'daily',
          mode: mode,
          validity: '1d',
          price: '5000',
          sellingPrice: '5000',
          macLock: true,
        ));
      }
    });

    test('round-trip: selling price preserved', () {
      const params = ProfileScriptParams(
        profileName: 'monthly',
        mode: ExpiryMode.remove,
        validity: '30d',
        price: '50000',
        sellingPrice: '45000',
      );
      final result = gen.generate(params);
      final parsed = OnLoginMetadataParser.parse(result.onLogin);
      expect(parsed.sellingPrice, '45000');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Malformed input tests
  // ─────────────────────────────────────────────────────────────────

  group('Malformed / invalid inputs', () {
    test('parseOrNull: null-like edge — non-Mikhmon script returns null', () {
      const foreign = '/ip hotspot user set disabled=yes [find where name=test]';
      final meta = OnLoginMetadataParser.parseOrNull(foreign);
      // Fewer than 7 commas → returns null
      expect(meta, isNull);
    });

    test('parseOrNull: truncated header returns null', () {
      const truncated = ':put (",rem,5000';
      // No closing "); → should return null or parse defensively
      // Parser splits on "," — fewer than 7 positions → null
      expect(OnLoginMetadataParser.parseOrNull(truncated), isNull);
    });

    test('parseOrNull: duplicate markers still returns something safely', () {
      // A pathological script with the :put header duplicated
      const dup = ':put (",rem,5000,1d,5000,,Disable,"); :put (",rem,5000,1d,5000,,Disable,");';
      // Should not throw — returns parsed metadata from first occurrence
      expect(() => OnLoginMetadataParser.parseOrNull(dup), returnsNormally);
    });

    test('parseOrNull: completely wrong delimiter (# instead of ,)', () {
      const wrongDelim = ':put ("#rem#5000#1d#5000##Disable#")';
      expect(OnLoginMetadataParser.parseOrNull(wrongDelim), isNull);
    });

    test('parseOrNull: missing metadata section', () {
      const noMeta = r':local x 1; :local y 2; :put [$x]';
      expect(OnLoginMetadataParser.parseOrNull(noMeta), isNull);
    });

    test('parseOrNull: corrupted metadata (only 3 commas)', () {
      const corrupted = ':put (",rem,5000,");';
      expect(OnLoginMetadataParser.parseOrNull(corrupted), isNull);
    });

    test('parse: malformed script throws OnLoginParseException', () {
      expect(
        () => OnLoginMetadataParser.parse(':wrong script content'),
        throwsA(isA<OnLoginParseException>()),
      );
    });

    test('parse: empty input does NOT throw (returns none metadata)', () {
      expect(
        () => OnLoginMetadataParser.parse(''),
        returnsNormally,
      );
    });

    test('parseOrNull: very long garbage string does not crash', () {
      final garbage = 'x' * 10000;
      expect(() => OnLoginMetadataParser.parseOrNull(garbage), returnsNormally);
    });

    test('parseOrNull: null-equivalent empty price defaults to "0"', () {
      // When price position is empty string, parser defaults to "0"
      const script = ':put (",rem,,1d,,,Disable,");';
      final meta = OnLoginMetadataParser.parseOrNull(script);
      // price at [2] is empty → defaults to "0"
      expect(meta?.price, '0');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // MetadataEncoder tests
  // ─────────────────────────────────────────────────────────────────

  group('MetadataEncoder', () {
    test('extractPutHeader from none+price on-login', () {
      const onLogin = ':put (",,5000,,,noexp,Disable,")';
      final header = encoder.extractPutHeader(onLogin);
      expect(header, ',,5000,,,noexp,Disable,');
    });

    test('extractPutHeader from remove on-login', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
      final header = encoder.extractPutHeader(result.onLogin);
      expect(header, isNotNull);
      expect(header, contains('rem'));
      expect(header, contains('5000'));
    });

    test('extractPutHeader: returns null for empty string', () {
      expect(encoder.extractPutHeader(''), isNull);
    });

    test('extractPutHeader: returns null for no :put statement', () {
      const noput = ':local x 1; /ip hotspot user remove \$x';
      expect(encoder.extractPutHeader(noput), isNull);
    });

    test('hasValidPositions: valid on-login returns true', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
      expect(encoder.hasValidPositions(result.onLogin), isTrue);
    });

    test('hasValidPositions: empty on-login returns true (valid empty)', () {
      expect(encoder.hasValidPositions(''), isTrue);
    });

    test('hasValidPositions: truncated header returns false', () {
      expect(encoder.hasValidPositions(':put (",rem,5000,");'), isFalse);
    });

    test('encodeHeader: none + no price → empty', () {
      const meta = OnLoginMetadata(
        mode: ExpiryMode.none,
        price: '0',
        validity: '',
        sellingPrice: '0',
        macLock: false,
      );
      expect(encoder.encodeHeader(meta), isEmpty);
    });

    test('encodeHeader: none + price → noexp format', () {
      const meta = OnLoginMetadata(
        mode: ExpiryMode.none,
        price: '5000',
        validity: '',
        sellingPrice: '0',
        macLock: false,
      );
      final header = encoder.encodeHeader(meta);
      expect(header, contains('noexp'));
      expect(header, contains('5000'));
    });

    test('encodeHeader: remove → contains mode token', () {
      const meta = OnLoginMetadata(
        mode: ExpiryMode.remove,
        price: '5000',
        validity: '1d',
        sellingPrice: '5000',
        macLock: false,
      );
      final header = encoder.encodeHeader(meta, validity: '1d');
      expect(header, startsWith(',rem,'));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // ProfileScriptParams validation
  // ─────────────────────────────────────────────────────────────────

  group('ProfileScriptParams.validate', () {
    test('valid remove params', () {
      final result = const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ).validate();
      expect(result.isValid, isTrue);
    });

    test('valid none+noprice params', () {
      final result = const ProfileScriptParams(
        profileName: 'free',
        mode: ExpiryMode.none,
        validity: '',
        price: '0',
        sellingPrice: '0',
      ).validate();
      expect(result.isValid, isTrue);
    });

    test('invalid: empty name → errors', () {
      final result = const ProfileScriptParams(
        profileName: '',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ).validate();
      expect(result.isValid, isFalse);
      expect(result.errors, isNotEmpty);
    });

    test('invalid: name with spaces → errors', () {
      final result = const ProfileScriptParams(
        profileName: 'my profile',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ).validate();
      expect(result.isValid, isFalse);
    });

    test('invalid: remove+empty validity → errors', () {
      final result = const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '',
        price: '5000',
        sellingPrice: '5000',
      ).validate();
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.contains('Validity')), isTrue);
    });

    test('invalid: negative price → errors', () {
      final result = const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.none,
        validity: '',
        price: '-100',
        sellingPrice: '0',
      ).validate();
      expect(result.isValid, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // HotspotProfile + OnLoginMetadata model tests
  // ─────────────────────────────────────────────────────────────────

  group('HotspotProfile.fromApiMap', () {
    test('parses profile with on-login', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
      final profile = HotspotProfile.fromApiMap({
        '.id': '*1',
        'name': 'daily',
        'rate-limit': '512k/1M',
        'shared-users': '2',
        'on-login': result.onLogin,
      });

      expect(profile.id, '*1');
      expect(profile.name, 'daily');
      expect(profile.rateLimit, '512k/1M');
      expect(profile.sharedUsers, 2);
      expect(profile.metadata, isNotNull);
      expect(profile.metadata!.mode, ExpiryMode.remove);
    });

    test('parses profile with empty on-login', () {
      final profile = HotspotProfile.fromApiMap({
        '.id': '*2',
        'name': 'free',
        'on-login': '',
      });

      expect(profile.metadata, isNotNull);
      expect(profile.metadata!.mode, ExpiryMode.none);
    });

    test('parses profile without on-login field', () {
      final profile = HotspotProfile.fromApiMap({
        '.id': '*3',
        'name': 'basic',
      });

      expect(profile.metadata, isNull);
    });
  });

  group('OnLoginMetadata', () {
    test('displayPrice: "0" returns empty string', () {
      const meta = OnLoginMetadata(
        mode: ExpiryMode.remove,
        price: '0',
        validity: '1d',
        sellingPrice: '0',
        macLock: false,
      );
      expect(meta.displayPrice, isEmpty);
      expect(meta.displaySellingPrice, isEmpty);
    });

    test('displayPrice: non-zero returns the price string', () {
      const meta = OnLoginMetadata(
        mode: ExpiryMode.remove,
        price: '5000',
        validity: '1d',
        sellingPrice: '4500',
        macLock: false,
      );
      expect(meta.displayPrice, '5000');
      expect(meta.displaySellingPrice, '4500');
    });

    test('lockToken reflects macLock', () {
      const enabled = OnLoginMetadata(
        mode: ExpiryMode.remove,
        price: '5000',
        validity: '1d',
        sellingPrice: '5000',
        macLock: true,
      );
      const disabled = OnLoginMetadata(
        mode: ExpiryMode.remove,
        price: '5000',
        validity: '1d',
        sellingPrice: '5000',
        macLock: false,
      );
      expect(enabled.lockToken, 'Enable');
      expect(disabled.lockToken, 'Disable');
    });

    test('equality: same metadata objects are equal', () {
      const a = OnLoginMetadata(
        mode: ExpiryMode.remove,
        price: '5000',
        validity: '1d',
        sellingPrice: '5000',
        macLock: false,
      );
      const b = OnLoginMetadata(
        mode: ExpiryMode.remove,
        price: '5000',
        validity: '1d',
        sellingPrice: '5000',
        macLock: false,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
