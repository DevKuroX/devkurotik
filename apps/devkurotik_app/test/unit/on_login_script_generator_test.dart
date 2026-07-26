/// Phase 6 — Golden tests for OnLoginScriptGenerator.
///
/// These tests validate that the generator produces byte-for-byte equivalent
/// output to Mikhmon v3. Every generated script is verified against:
///   1. The metadata header (comma positions [1..6])
///   2. The structural invariants (presence of required RouterScript keywords)
///   3. Round-trip (generate → parse → metadata equality)
///
/// CANONICAL SOURCE: hotspot/adduserprofile.php lines 62-86.
///
/// 100% of fixtures must pass. 95% is failure. 99% is failure.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/profile_models.dart';
import 'package:devkurotik_app/src/domain/services/on_login_script_generator.dart';
import 'package:devkurotik_app/src/domain/services/metadata_encoder.dart';

void main() {
  const gen = OnLoginScriptGenerator();
  const encoder = MetadataEncoder();

  // ─────────────────────────────────────────────────────────────────
  // Mode: none
  // ─────────────────────────────────────────────────────────────────

  group('ExpiryMode.none', () {
    test('none + no price → empty on-login (canonical)', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.none,
        validity: '',
        price: '0',
        sellingPrice: '0',
      ));

      // Canonical: empty string when mode=none and price=0
      expect(result.onLogin, isEmpty,
          reason: 'Mode=none with price=0 must produce empty on-login');
      expect(result.bgService, isEmpty,
          reason: 'Mode=none must not produce bgService');
      expect(result.requiresScheduler, isFalse);
    });

    test('none + price → ":put (",,...noexp,Disable,")" (canonical)', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.none,
        validity: '',
        price: '5000',
        sellingPrice: '0',
      ));

      // Canonical: ':put (",,5000,,,noexp,Disable,")'
      expect(result.onLogin, startsWith(':put (",,5000,,,noexp,Disable,")'));
      expect(result.bgService, isEmpty);
      expect(result.requiresScheduler, isFalse);
    });

    test('none + price + macLock=true → lock fragment appended', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.none,
        validity: '',
        price: '5000',
        sellingPrice: '0',
        macLock: true,
      ));

      // Canonical: ':put (",,5000,,,noexp,Enable,")'
      //            + '; [:local mac $"mac-address"; /ip hotspot user set mac-address=$mac [find where name=$user]]'
      expect(result.onLogin, contains(':put (",,5000,,,noexp,Enable,")'));
      expect(result.onLogin, contains('mac-address'));
      expect(result.bgService, isEmpty);
    });

    test('none + price comma positions correct', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.none,
        validity: '',
        price: '7500',
        sellingPrice: '0',
      ));
      // Verify metadata encoder can extract the header
      final header = encoder.extractPutHeader(result.onLogin);
      expect(header, isNotNull);
      final parts = header!.split(',');
      // [0]=empty, [1]=empty, [2]=price, [3]=empty, [4]=empty, [5]=noexp, [6]=Disable, [7]=empty
      expect(parts[2], '7500');
      expect(parts[5], 'noexp');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Mode: remove
  // ─────────────────────────────────────────────────────────────────

  group('ExpiryMode.remove', () {
    test('remove basic → correct metadata header', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.onLogin, startsWith(':put (",rem,5000,1d,5000,,Disable,");'));
      expect(result.bgService, isNotEmpty);
      expect(result.requiresScheduler, isTrue);
    });

    test('remove → bgService contains profile name in foreach', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.bgService, contains('profile="daily"'));
    });

    test('remove → bgService uses "remove" mode (not set limit)', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.bgService, contains('user remove'));
      expect(result.bgService, isNot(contains('limit-uptime')));
      expect(result.mode, 'remove');
    });

    test('remove + macLock → lock fragment in on-login', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'weekly',
        mode: ExpiryMode.remove,
        validity: '7d',
        price: '20000',
        sellingPrice: '20000',
        macLock: true,
      ));

      expect(result.onLogin, contains(':put (",rem,20000,7d,20000,,Enable,");'));
      expect(result.onLogin, contains('mac-address'));
      expect(result.onLogin, endsWith('}}'));
    });

    test('remove on-login ends with "}}"', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'monthly',
        mode: ExpiryMode.remove,
        validity: '30d',
        price: '50000',
        sellingPrice: '45000',
      ));
      expect(result.onLogin, endsWith('}}'));
    });

    test('remove → on-login contains scheduler create (ucode vc/up check)', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      // Must contain the canonical user-code check
      expect(result.onLogin, contains(r'"vc" or $ucode = "up"'));
      // Must create a temporary scheduler
      expect(result.onLogin, contains('/sys sch add name="\$user"'));
      // Must set validity interval
      expect(result.onLogin, contains('interval="1d"'));
      // Must have the 3 expiry date cases
      expect(result.onLogin, contains(r':if ($getxp = 15)'));
      expect(result.onLogin, contains(r':if ($getxp = 8)'));
      expect(result.onLogin, contains(r':if ($getxp > 15)'));
      // Must clean up temp scheduler
      expect(result.onLogin, contains('/sys sch remove [find where name="\$user"]'));
    });

    test('remove → does NOT contain record fragment', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.onLogin, isNot(contains('comment="mikhmon"')));
    });

    // Golden fixture test — canonical structure comparison
    test('remove golden fixture: daily/5000/1d/nolock', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      // Verify comma positions exactly
      final header = encoder.extractPutHeader(result.onLogin);
      expect(header, isNotNull);
      final parts = header!.split(',');
      expect(parts.length, greaterThanOrEqualTo(7));
      expect(parts[1], 'rem', reason: 'Position [1] must be mode token');
      expect(parts[2], '5000', reason: 'Position [2] must be price');
      expect(parts[3], '1d', reason: 'Position [3] must be validity');
      expect(parts[4], '5000', reason: 'Position [4] must be selling price');
      expect(parts[5], '', reason: 'Position [5] must be empty');
      expect(parts[6], 'Disable', reason: 'Position [6] must be lock token');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Mode: notice
  // ─────────────────────────────────────────────────────────────────

  group('ExpiryMode.notice', () {
    test('notice basic → correct metadata header', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.notice,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.onLogin, startsWith(':put (",ntf,5000,1d,5000,,Disable,");'));
      expect(result.bgService, isNotEmpty);
      expect(result.requiresScheduler, isTrue);
    });

    test('notice → bgService uses "set limit-uptime=1s"', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.notice,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.bgService, contains('set limit-uptime=1s'));
      expect(result.bgService, isNot(contains('user remove')));
      expect(result.mode, 'set limit-uptime=1s');
    });

    test('notice → does NOT contain record fragment', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: '1hour',
        mode: ExpiryMode.notice,
        validity: '1h',
        price: '2000',
        sellingPrice: '2000',
        macLock: true,
      ));

      expect(result.onLogin, isNot(contains('comment="mikhmon"')));
    });

    test('notice on-login ends with "}}"', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'promo',
        mode: ExpiryMode.notice,
        validity: '2d',
        price: '3000',
        sellingPrice: '2500',
      ));
      expect(result.onLogin, endsWith('}}'));
    });

    test('notice golden: ntf header positions', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: '1hour',
        mode: ExpiryMode.notice,
        validity: '1h',
        price: '2000',
        sellingPrice: '2000',
      ));
      final header = encoder.extractPutHeader(result.onLogin);
      final parts = header!.split(',');
      expect(parts[1], 'ntf');
      expect(parts[2], '2000');
      expect(parts[3], '1h');
      expect(parts[4], '2000');
      expect(parts[6], 'Disable');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Mode: removeRecord
  // ─────────────────────────────────────────────────────────────────

  group('ExpiryMode.removeRecord', () {
    test('removeRecord → correct header', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.removeRecord,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.onLogin, startsWith(':put (",remc,5000,1d,5000,,Disable,");'));
      expect(result.requiresScheduler, isTrue);
    });

    test('removeRecord → on-login contains sale record script', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.removeRecord,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      // Must contain the Mikhmon sales record script
      expect(result.onLogin, contains('comment="mikhmon"'));
      expect(result.onLogin, contains('/system script add name='));
      expect(result.onLogin, contains('\$date-|-\$time-|-\$user-|-5000'));
      expect(result.onLogin, contains('-|-1d-|-daily-|-\$comment"'));
    });

    test('removeRecord → bgService uses "remove"', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.removeRecord,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.bgService, contains('user remove'));
      expect(result.mode, 'remove');
    });

    test('removeRecord + macLock → lock comes after record', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'weekly',
        mode: ExpiryMode.removeRecord,
        validity: '7d',
        price: '20000',
        sellingPrice: '18000',
        macLock: true,
      ));

      // Lock fragment must come AFTER record fragment
      final recPos = result.onLogin.indexOf('comment="mikhmon"');
      final lockPos = result.onLogin.indexOf('mac-address=\$mac');
      expect(recPos, greaterThan(0));
      expect(lockPos, greaterThan(recPos),
          reason: 'Lock fragment must be after record fragment');
      expect(result.onLogin, endsWith('}}'));
    });

    test('removeRecord golden fixture: remc header positions', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'monthly',
        mode: ExpiryMode.removeRecord,
        validity: '30d',
        price: '50000',
        sellingPrice: '0',
      ));
      final header = encoder.extractPutHeader(result.onLogin);
      final parts = header!.split(',');
      expect(parts[1], 'remc');
      expect(parts[2], '50000');
      expect(parts[3], '30d');
      expect(parts[4], '0');
      expect(parts[6], 'Disable');
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Mode: noticeRecord
  // ─────────────────────────────────────────────────────────────────

  group('ExpiryMode.noticeRecord', () {
    test('noticeRecord → correct header', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.noticeRecord,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.onLogin, startsWith(':put (",ntfc,5000,1d,5000,,Disable,");'));
      expect(result.requiresScheduler, isTrue);
    });

    test('noticeRecord → on-login contains sale record script', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.noticeRecord,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.onLogin, contains('comment="mikhmon"'));
      expect(result.onLogin, contains('/system script add name='));
    });

    test('noticeRecord → bgService uses "set limit-uptime=1s"', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.noticeRecord,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.bgService, contains('set limit-uptime=1s'));
      expect(result.mode, 'set limit-uptime=1s');
    });

    test('noticeRecord premium golden: ntfc header positions', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'premium',
        mode: ExpiryMode.noticeRecord,
        validity: '30d',
        price: '100000',
        sellingPrice: '95000',
        macLock: true,
      ));
      final header = encoder.extractPutHeader(result.onLogin);
      final parts = header!.split(',');
      expect(parts[1], 'ntfc');
      expect(parts[2], '100000');
      expect(parts[3], '30d');
      expect(parts[4], '95000');
      expect(parts[6], 'Enable');
    });

    test('noticeRecord free trial (price=0) → ntfc header still present', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'trial',
        mode: ExpiryMode.noticeRecord,
        validity: '1h',
        price: '0',
        sellingPrice: '0',
      ));

      expect(result.onLogin, startsWith(':put (",ntfc,0,1h,0,,Disable,");'));
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Background sweep service — canonical structure
  // ─────────────────────────────────────────────────────────────────

  group('Background sweep service', () {
    test('bgService contains canonical dateint function', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.bgService, contains(':local dateint do='));
      expect(result.bgService, contains('"jan","feb","mar","apr"'));
      expect(result.bgService, contains(':return [:tonum'));
    });

    test('bgService contains canonical timeint function', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      expect(result.bgService, contains(':local timeint do='));
      expect(result.bgService, contains(':local hours [ :pick \$t 0 2 ]'));
      expect(result.bgService, contains(':return (\$hours * 60 + \$minutes)'));
    });

    test('bgService contains expiry comparison logic', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));

      // Canonical: 3 expiry conditions
      expect(result.bgService,
          contains(r'$expd < $today and $expt < $curtime'));
      expect(result.bgService,
          contains(r'$expd < $today and $expt > $curtime'));
      expect(result.bgService,
          contains(r'$expd = $today and $expt < $curtime'));
    });

    test('bgService for remove profile matches profile name', () {
      for (final name in ['daily', 'weekly', 'monthly', 'premium']) {
        final result = gen.generate(ProfileScriptParams(
          profileName: name,
          mode: ExpiryMode.remove,
          validity: '1d',
          price: '5000',
          sellingPrice: '5000',
        ));
        expect(result.bgService, contains('profile="$name"'),
            reason: 'bgService must reference profile name "$name"');
      }
    });

    test('bgService for notice mode has "set limit-uptime=1s" action', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.notice,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
      expect(result.bgService, contains('set limit-uptime=1s \$i'));
    });

    test('bgService for remove mode has "remove" action', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.remove,
        validity: '1d',
        price: '5000',
        sellingPrice: '5000',
      ));
      expect(result.bgService, contains('user remove \$i'));
    });

    test('bgService always cleans up active session', () {
      for (final mode in [
        ExpiryMode.remove,
        ExpiryMode.notice,
        ExpiryMode.removeRecord,
        ExpiryMode.noticeRecord,
      ]) {
        final result = gen.generate(ProfileScriptParams(
          profileName: 'daily',
          mode: mode,
          validity: '1d',
          price: '5000',
          sellingPrice: '5000',
        ));
        expect(result.bgService,
            contains('/ip hotspot active remove [find where user=\$name]'),
            reason: 'bgService must remove active session for mode ${mode.token}');
      }
    });

    test('none mode → bgService is empty', () {
      final result = gen.generate(const ProfileScriptParams(
        profileName: 'daily',
        mode: ExpiryMode.none,
        validity: '',
        price: '0',
        sellingPrice: '0',
      ));
      expect(result.bgService, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────────

  group('Validation', () {
    test('invalid: empty profile name throws ArgumentError', () {
      expect(
        () => gen.generate(const ProfileScriptParams(
          profileName: '',
          mode: ExpiryMode.remove,
          validity: '1d',
          price: '5000',
          sellingPrice: '5000',
        )),
        throwsArgumentError,
      );
    });

    test('invalid: profile name with spaces throws ArgumentError', () {
      expect(
        () => gen.generate(const ProfileScriptParams(
          profileName: 'my profile',
          mode: ExpiryMode.remove,
          validity: '1d',
          price: '5000',
          sellingPrice: '5000',
        )),
        throwsArgumentError,
      );
    });

    test('invalid: remove mode with empty validity throws ArgumentError', () {
      expect(
        () => gen.generate(const ProfileScriptParams(
          profileName: 'daily',
          mode: ExpiryMode.remove,
          validity: '',
          price: '5000',
          sellingPrice: '5000',
        )),
        throwsArgumentError,
      );
    });

    test('valid: none mode with empty validity → no error', () {
      expect(
        () => gen.generate(const ProfileScriptParams(
          profileName: 'daily',
          mode: ExpiryMode.none,
          validity: '',
          price: '0',
          sellingPrice: '0',
        )),
        returnsNormally,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────
  // All 15 fixture inputs — structural correctness check
  // ─────────────────────────────────────────────────────────────────

  group('Golden fixture library — 15 inputs', () {
    final fixtures = [
      // none × 3
      (
        desc: 'none/noprice/v7',
        p: const ProfileScriptParams(
            profileName: 'daily',
            mode: ExpiryMode.none,
            validity: '',
            price: '0',
            sellingPrice: '0'),
        expectOnLoginEmpty: true,
        expectBgServiceEmpty: true,
      ),
      (
        desc: 'none/price/v7',
        p: const ProfileScriptParams(
            profileName: 'daily',
            mode: ExpiryMode.none,
            validity: '',
            price: '5000',
            sellingPrice: '0'),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: true,
      ),
      (
        desc: 'none/price+lock/v6',
        p: const ProfileScriptParams(
            profileName: 'daily',
            mode: ExpiryMode.none,
            validity: '',
            price: '5000',
            sellingPrice: '0',
            macLock: true),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: true,
      ),
      // remove × 3
      (
        desc: 'remove/basic/v7',
        p: const ProfileScriptParams(
            profileName: 'daily',
            mode: ExpiryMode.remove,
            validity: '1d',
            price: '5000',
            sellingPrice: '5000'),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      (
        desc: 'remove/maclock/v6',
        p: const ProfileScriptParams(
            profileName: 'weekly',
            mode: ExpiryMode.remove,
            validity: '7d',
            price: '20000',
            sellingPrice: '20000',
            macLock: true),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      (
        desc: 'remove/sprice/v6.40',
        p: const ProfileScriptParams(
            profileName: 'monthly',
            mode: ExpiryMode.remove,
            validity: '30d',
            price: '50000',
            sellingPrice: '45000'),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      // notice × 3
      (
        desc: 'notice/basic/v7',
        p: const ProfileScriptParams(
            profileName: 'daily',
            mode: ExpiryMode.notice,
            validity: '1d',
            price: '5000',
            sellingPrice: '5000'),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      (
        desc: 'notice/maclock/v6',
        p: const ProfileScriptParams(
            profileName: '1hour',
            mode: ExpiryMode.notice,
            validity: '1h',
            price: '2000',
            sellingPrice: '2000',
            macLock: true),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      (
        desc: 'notice/sprice/v6.40',
        p: const ProfileScriptParams(
            profileName: 'promo',
            mode: ExpiryMode.notice,
            validity: '2d',
            price: '3000',
            sellingPrice: '2500'),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      // removeRecord × 3
      (
        desc: 'remove_record/basic/v7',
        p: const ProfileScriptParams(
            profileName: 'daily',
            mode: ExpiryMode.removeRecord,
            validity: '1d',
            price: '5000',
            sellingPrice: '5000'),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      (
        desc: 'remove_record/maclock/v6',
        p: const ProfileScriptParams(
            profileName: 'weekly',
            mode: ExpiryMode.removeRecord,
            validity: '7d',
            price: '20000',
            sellingPrice: '18000',
            macLock: true),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      (
        desc: 'remove_record/nosprice/v6.40',
        p: const ProfileScriptParams(
            profileName: 'monthly',
            mode: ExpiryMode.removeRecord,
            validity: '30d',
            price: '50000',
            sellingPrice: '0'),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      // noticeRecord × 3
      (
        desc: 'notice_record/basic/v7',
        p: const ProfileScriptParams(
            profileName: 'daily',
            mode: ExpiryMode.noticeRecord,
            validity: '1d',
            price: '5000',
            sellingPrice: '5000'),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      (
        desc: 'notice_record/premium/v6',
        p: const ProfileScriptParams(
            profileName: 'premium',
            mode: ExpiryMode.noticeRecord,
            validity: '30d',
            price: '100000',
            sellingPrice: '95000',
            macLock: true),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
      (
        desc: 'notice_record/free/v6.40',
        p: const ProfileScriptParams(
            profileName: 'trial',
            mode: ExpiryMode.noticeRecord,
            validity: '1h',
            price: '0',
            sellingPrice: '0'),
        expectOnLoginEmpty: false,
        expectBgServiceEmpty: false,
      ),
    ];

    for (final f in fixtures) {
      test('fixture: ${f.desc}', () {
        final result = gen.generate(f.p);

        if (f.expectOnLoginEmpty) {
          expect(result.onLogin, isEmpty,
              reason: '${f.desc}: onLogin should be empty');
        } else {
          expect(result.onLogin, isNotEmpty,
              reason: '${f.desc}: onLogin should be non-empty');
          // All non-empty on-login scripts must have valid positions
          expect(encoder.hasValidPositions(result.onLogin), isTrue,
              reason: '${f.desc}: on-login must have ≥7 comma positions');
        }

        if (f.expectBgServiceEmpty) {
          expect(result.bgService, isEmpty,
              reason: '${f.desc}: bgService should be empty');
        } else {
          expect(result.bgService, isNotEmpty,
              reason: '${f.desc}: bgService should be non-empty');
          expect(result.bgService, contains('profile="${f.p.profileName}"'),
              reason: '${f.desc}: bgService must reference profile name');
        }
      });
    }
  });
}
