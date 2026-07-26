/// Phase 4 — Unit tests for HotspotUser and related models.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/hotspot_models.dart';
import 'package:devkurotik_app/src/domain/services/hotspot_service.dart';

void main() {
  // ---------------------------------------------------------------------------
  // HotspotUser.fromApiMap
  // ---------------------------------------------------------------------------
  group('HotspotUser.fromApiMap', () {
    test('parses basic user', () {
      final map = {
        '.id': '*1',
        'name': 'user001',
        'password': 'pass001',
        'profile': 'daily',
        'disabled': 'false',
        'server': 'hotspot1',
      };
      final user = HotspotUser.fromApiMap(map);
      expect(user.id, '*1');
      expect(user.name, 'user001');
      expect(user.password, 'pass001');
      expect(user.profile, 'daily');
      expect(user.disabled, isFalse);
      expect(user.server, 'hotspot1');
    });

    test('parses disabled user', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*2',
        'name': 'user002',
        'profile': 'weekly',
        'disabled': 'true',
      });
      expect(user.disabled, isTrue);
    });

    test('parses user with comment', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*3',
        'name': 'u3',
        'profile': 'p1',
        'disabled': 'false',
        'comment': 'vc-abc123-Jan01-batch1',
      });
      expect(user.comment, 'vc-abc123-Jan01-batch1');
      expect(user.batchCode, 'vc-abc123-Jan01-batch1');
    });

    test('parses user with expired limit-uptime', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*4',
        'name': 'u4',
        'profile': 'p1',
        'disabled': 'false',
        'limit-uptime': '1s',
      });
      expect(user.isExpired, isTrue);
    });

    test('normal limit-uptime is not expired', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*5',
        'name': 'u5',
        'profile': 'p1',
        'disabled': 'false',
        'limit-uptime': '1h',
      });
      expect(user.isExpired, isFalse);
    });

    test('parses bytes in/out', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*6',
        'name': 'u6',
        'profile': 'p1',
        'disabled': 'false',
        'bytes-in': '1048576',
        'bytes-out': '524288',
      });
      expect(user.bytesIn, 1048576);
      expect(user.bytesOut, 524288);
    });

    test('parses MAC address', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*7',
        'name': 'u7',
        'profile': 'p1',
        'disabled': 'false',
        'mac-address': 'AA:BB:CC:DD:EE:FF',
      });
      expect(user.macAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('empty bytes fields return null', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*8',
        'name': 'u8',
        'profile': 'p1',
        'disabled': 'false',
        'bytes-in': '',
      });
      expect(user.bytesIn, isNull);
    });

    test('isVoucher when name equals password', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*9',
        'name': 'abc123',
        'password': 'abc123',
        'profile': 'p1',
        'disabled': 'false',
      });
      expect(user.isVoucher, isTrue);
    });

    test('isVoucher false when name != password', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*10',
        'name': 'user001',
        'password': 'pass001',
        'profile': 'p1',
        'disabled': 'false',
      });
      expect(user.isVoucher, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotProfile.fromApiMap
  // ---------------------------------------------------------------------------
  group('HotspotProfile.fromApiMap', () {
    test('parses basic profile', () {
      final profile = HotspotProfile.fromApiMap({
        '.id': '*1',
        'name': 'daily',
        'rate-limit': '512k/1M',
        'shared-users': '1',
      });
      expect(profile.id, '*1');
      expect(profile.name, 'daily');
      expect(profile.rateLimit, '512k/1M');
      expect(profile.sharedUsers, 1);
    });

    test('displayName includes validity when present', () {
      const profile = HotspotProfile(
        id: '*1',
        name: '1H',
        validity: '1 Hour',
      );
      expect(profile.displayName, '1H (1 Hour)');
    });

    test('displayName is just name when no validity', () {
      const profile = HotspotProfile(id: '*1', name: 'daily');
      expect(profile.displayName, 'daily');
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotActive.fromApiMap
  // ---------------------------------------------------------------------------
  group('HotspotActive.fromApiMap', () {
    test('parses active session', () {
      final session = HotspotActive.fromApiMap({
        '.id': '*1',
        'user': 'user001',
        'server': 'hotspot1',
        'mac-address': 'AA:BB:CC:DD:EE:FF',
        'address': '10.10.10.5',
        'uptime': '45m10s',
        'login-by': 'login',
        'bytes-in': '1048576',
        'bytes-out': '524288',
      });
      expect(session.id, '*1');
      expect(session.user, 'user001');
      expect(session.server, 'hotspot1');
      expect(session.macAddress, 'AA:BB:CC:DD:EE:FF');
      expect(session.address, '10.10.10.5');
      expect(session.uptime, '45m10s');
      expect(session.loginBy, 'login');
      expect(session.bytesIn, 1048576);
      expect(session.bytesOut, 524288);
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotCookie.fromApiMap
  // ---------------------------------------------------------------------------
  group('HotspotCookie.fromApiMap', () {
    test('parses cookie', () {
      final cookie = HotspotCookie.fromApiMap({
        '.id': '*1',
        'user': 'user001',
        'mac-address': 'AA:BB:CC:DD:EE:FF',
        'domain': 'hotspot.example.com',
        'expires-in': '23h59m',
      });
      expect(cookie.user, 'user001');
      expect(cookie.domain, 'hotspot.example.com');
      expect(cookie.expiresIn, '23h59m');
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotHost.fromApiMap
  // ---------------------------------------------------------------------------
  group('HotspotHost.fromApiMap', () {
    test('parses authorized host', () {
      final host = HotspotHost.fromApiMap({
        '.id': '*1',
        'mac-address': 'AA:BB:CC:DD:EE:FF',
        'address': '10.10.10.5',
        'authorized': 'true',
        'bypassed': 'false',
      });
      expect(host.authorized, isTrue);
      expect(host.bypassed, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotUserCreate.toApiParams
  // ---------------------------------------------------------------------------
  group('HotspotUserCreate.toApiParams', () {
    test('includes required fields', () {
      const params = HotspotUserCreate(
        name: 'user001',
        password: 'pass001',
        profile: 'daily',
      );
      final map = params.toApiParams();
      expect(map['name'], 'user001');
      expect(map['password'], 'pass001');
      expect(map['profile'], 'daily');
      expect(map['server'], 'all');
    });

    test('omits optional fields when null', () {
      const params = HotspotUserCreate(
        name: 'u1',
        password: 'p1',
        profile: 'daily',
      );
      final map = params.toApiParams();
      expect(map.containsKey('limit-uptime'), isFalse);
      expect(map.containsKey('comment'), isFalse);
      expect(map.containsKey('mac-address'), isFalse);
      expect(map.containsKey('disabled'), isFalse);
    });

    test('includes optional fields when provided', () {
      const params = HotspotUserCreate(
        name: 'u1',
        password: 'p1',
        profile: 'daily',
        limitUptime: '1h',
        comment: 'batch1',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        disabled: true,
      );
      final map = params.toApiParams();
      expect(map['limit-uptime'], '1h');
      expect(map['comment'], 'batch1');
      expect(map['mac-address'], 'AA:BB:CC:DD:EE:FF');
      expect(map['disabled'], 'yes');
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotUserUpdate.toApiParams
  // ---------------------------------------------------------------------------
  group('HotspotUserUpdate.toApiParams', () {
    test('empty update returns empty map', () {
      const update = HotspotUserUpdate();
      expect(update.toApiParams(), isEmpty);
    });

    test('updates only provided fields', () {
      const update = HotspotUserUpdate(disabled: false);
      final map = update.toApiParams();
      expect(map['disabled'], 'no');
      expect(map.length, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotUserValidation
  // ---------------------------------------------------------------------------
  group('HotspotUserValidation', () {
    group('validateName', () {
      test('rejects empty name', () {
        expect(HotspotUserValidation.validateName(''), isNotNull);
      });

      test('rejects name > 64 chars', () {
        expect(
          HotspotUserValidation.validateName('a' * 65),
          isNotNull,
        );
      });

      test('accepts valid alphanumeric name', () {
        expect(HotspotUserValidation.validateName('user001'), isNull);
      });

      test('accepts name with hyphen and dot', () {
        expect(HotspotUserValidation.validateName('user.001-abc'), isNull);
      });

      test('rejects name with space', () {
        expect(HotspotUserValidation.validateName('user 001'), isNotNull);
      });

      test('rejects name with special chars', () {
        expect(HotspotUserValidation.validateName('user@#\$'), isNotNull);
      });

      test('accepts @ in name', () {
        // RouterOS allows @ in username
        expect(HotspotUserValidation.validateName('user@domain'), isNull);
      });
    });

    group('validatePassword', () {
      test('rejects empty password', () {
        expect(HotspotUserValidation.validatePassword(''), isNotNull);
      });

      test('rejects password > 64 chars', () {
        expect(
          HotspotUserValidation.validatePassword('p' * 65),
          isNotNull,
        );
      });

      test('accepts valid password', () {
        expect(HotspotUserValidation.validatePassword('pass001'), isNull);
      });
    });

    group('validateProfile', () {
      test('rejects empty profile', () {
        expect(HotspotUserValidation.validateProfile(''), isNotNull);
      });

      test('accepts valid profile name', () {
        expect(HotspotUserValidation.validateProfile('daily'), isNull);
      });
    });

    group('validateLimitUptime', () {
      test('accepts null (optional)', () {
        expect(HotspotUserValidation.validateLimitUptime(null), isNull);
      });

      test('accepts empty string (optional)', () {
        expect(HotspotUserValidation.validateLimitUptime(''), isNull);
      });

      test('accepts 1h', () {
        expect(HotspotUserValidation.validateLimitUptime('1h'), isNull);
      });

      test('accepts 2h30m', () {
        expect(HotspotUserValidation.validateLimitUptime('2h30m'), isNull);
      });

      test('accepts 1d', () {
        expect(HotspotUserValidation.validateLimitUptime('1d'), isNull);
      });

      test('accepts 1w2d3h4m5s', () {
        expect(
          HotspotUserValidation.validateLimitUptime('1w2d3h4m5s'),
          isNull,
        );
      });

      test('rejects invalid format "1 hour"', () {
        expect(
          HotspotUserValidation.validateLimitUptime('1 hour'),
          isNotNull,
        );
      });
    });

    group('validateMacAddress', () {
      test('accepts null (optional)', () {
        expect(HotspotUserValidation.validateMacAddress(null), isNull);
      });

      test('accepts empty (optional)', () {
        expect(HotspotUserValidation.validateMacAddress(''), isNull);
      });

      test('accepts valid MAC', () {
        expect(
          HotspotUserValidation.validateMacAddress('AA:BB:CC:DD:EE:FF'),
          isNull,
        );
      });

      test('accepts lowercase MAC', () {
        expect(
          HotspotUserValidation.validateMacAddress('aa:bb:cc:dd:ee:ff'),
          isNull,
        );
      });

      test('rejects invalid MAC format (missing colons)', () {
        expect(
          HotspotUserValidation.validateMacAddress('AABBCCDDEEFF'),
          isNotNull,
        );
      });

      test('rejects short MAC', () {
        expect(
          HotspotUserValidation.validateMacAddress('AA:BB:CC'),
          isNotNull,
        );
      });
    });

    group('validate (full)', () {
      test('valid params pass validation', () {
        const params = HotspotUserCreate(
          name: 'user001',
          password: 'pass001',
          profile: 'daily',
        );
        final result = HotspotUserValidation.validate(params);
        expect(result.isValid, isTrue);
      });

      test('empty name fails', () {
        const params = HotspotUserCreate(
          name: '',
          password: 'pass001',
          profile: 'daily',
        );
        final result = HotspotUserValidation.validate(params);
        expect(result.isValid, isFalse);
        expect(result.nameError, isNotNull);
      });
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotService.decodeExpiry
  // ---------------------------------------------------------------------------
  group('HotspotService.decodeExpiry', () {
    test('returns null for user with no comment', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*1',
        'name': 'u1',
        'profile': 'p1',
        'disabled': 'false',
      });
      expect(HotspotService.decodeExpiry(user), isNull);
    });

    test('returns null for batch code comment', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*1',
        'name': 'u1',
        'profile': 'p1',
        'disabled': 'false',
        'comment': 'vc-abc123-date-batch',
      });
      // batch code does not match expiry pattern
      expect(HotspotService.decodeExpiry(user), isNull);
    });

    test('decodes expiry stamp from comment', () {
      // Simulate post-login comment: "Jan/01/2020 14:30:00 vc-abc"
      final user = HotspotUser.fromApiMap({
        '.id': '*1',
        'name': 'u1',
        'profile': 'p1',
        'disabled': 'false',
        'comment': 'Jan/01/2020 14:30:00 vc-abc123',
      });
      final expiry = HotspotService.decodeExpiry(user);
      expect(expiry, isNotNull);
      expect(expiry!.isExpired, isTrue); // year 2020 is past
      expect(expiry.rawStamp, 'Jan/01/2020 14:30:00');
    });

    test('future expiry is not expired', () {
      final user = HotspotUser.fromApiMap({
        '.id': '*1',
        'name': 'u1',
        'profile': 'p1',
        'disabled': 'false',
        'comment': 'Dec/31/2099 23:59:00 vc-abc123',
      });
      final expiry = HotspotService.decodeExpiry(user);
      expect(expiry, isNotNull);
      expect(expiry!.isExpired, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotService.auditEntry
  // ---------------------------------------------------------------------------
  group('HotspotService.auditEntry', () {
    test('generates structured audit entry', () {
      final entry = HotspotService.auditEntry(
        action: 'DELETE',
        routerId: 'router-1',
        subject: 'user001',
        detail: 'bulk delete by comment',
      );
      expect(entry, contains('DELETE'));
      expect(entry, contains('router=router-1'));
      expect(entry, contains('subject=user001'));
      expect(entry, contains('bulk delete by comment'));
    });

    test('entry does not expose passwords', () {
      final entry = HotspotService.auditEntry(
        action: 'DELETE',
        routerId: 'router-1',
        subject: 'user001',
      );
      expect(entry, isNot(contains('password')));
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotData computed properties
  // ---------------------------------------------------------------------------
  group('HotspotData', () {
    test('totalUsers, disabledUsers, expiredUsers', () {
      final data = HotspotData(
        routerId: 'r1',
        users: [
          HotspotUser.fromApiMap({
            '.id': '*1', 'name': 'u1', 'profile': 'p1', 'disabled': 'false',
          }),
          HotspotUser.fromApiMap({
            '.id': '*2', 'name': 'u2', 'profile': 'p1', 'disabled': 'true',
          }),
          HotspotUser.fromApiMap({
            '.id': '*3', 'name': 'u3', 'profile': 'p1',
            'disabled': 'false', 'limit-uptime': '1s',
          }),
        ],
        profiles: [],
        activeSessions: [
          HotspotActive.fromApiMap({
            '.id': '*1', 'user': 'u1', 'server': 's1',
            'mac-address': 'AA:BB:CC:DD:EE:FF', 'address': '10.0.0.1',
          }),
        ],
        fetchedAt: DateTime.now(),
      );

      expect(data.totalUsers, 3);
      expect(data.activeUsers, 1);
      expect(data.disabledUsers, 1);
      expect(data.expiredUsers, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotUserFilter
  // ---------------------------------------------------------------------------
  group('HotspotUserFilter filtering logic', () {
    final users = [
      HotspotUser.fromApiMap({
        '.id': '*1', 'name': 'u1', 'profile': 'daily', 'disabled': 'false',
        'comment': 'batch-A',
      }),
      HotspotUser.fromApiMap({
        '.id': '*2', 'name': 'u2', 'profile': 'weekly', 'disabled': 'false',
      }),
      HotspotUser.fromApiMap({
        '.id': '*3', 'name': 'u3', 'profile': 'daily', 'disabled': 'false',
        'limit-uptime': '1s',
      }),
    ];

    test('byProfile filters correctly', () {
      final filtered =
          users.where((u) => u.profile == 'daily').toList();
      expect(filtered.length, 2);
    });

    test('byComment filters correctly', () {
      final filtered =
          users.where((u) => u.comment?.contains('batch-A') ?? false).toList();
      expect(filtered.length, 1);
      expect(filtered.first.name, 'u1');
    });

    test('expired filters correctly', () {
      final filtered = users.where((u) => u.isExpired).toList();
      expect(filtered.length, 1);
      expect(filtered.first.name, 'u3');
    });

    test('search by name', () {
      const q = 'u1';
      final filtered = users
          .where((u) => u.name.toLowerCase().contains(q))
          .toList();
      expect(filtered.length, 1);
      expect(filtered.first.id, '*1');
    });
  });
}
