/// Phase 7 — PPP domain models unit tests.
///
/// Covers: PppServiceType, PppSecret.fromApiMap, PppProfile.fromApiMap,
/// PppActive.fromApiMap, PppSecretCreate.toApiParams, PppSecretUpdate.toApiParams,
/// PppData counters, PppSecretValidation.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/ppp_models.dart';

void main() {
  // ── PppServiceType ──────────────────────────────────────────────────────

  group('PppServiceType', () {
    test('fromRos returns correct type for all values', () {
      expect(PppServiceType.fromRos('pppoe'), PppServiceType.pppoe);
      expect(PppServiceType.fromRos('l2tp'), PppServiceType.l2tp);
      expect(PppServiceType.fromRos('pptp'), PppServiceType.pptp);
      expect(PppServiceType.fromRos('sstp'), PppServiceType.sstp);
      expect(PppServiceType.fromRos('ovpn'), PppServiceType.ovpn);
      expect(PppServiceType.fromRos('any'), PppServiceType.any);
      expect(PppServiceType.fromRos(null), PppServiceType.any);
      expect(PppServiceType.fromRos('unknown'), PppServiceType.any);
    });

    test('rosValue matches expected RouterOS strings', () {
      expect(PppServiceType.any.rosValue, 'any');
      expect(PppServiceType.pppoe.rosValue, 'pppoe');
      expect(PppServiceType.l2tp.rosValue, 'l2tp');
      expect(PppServiceType.pptp.rosValue, 'pptp');
      expect(PppServiceType.sstp.rosValue, 'sstp');
      expect(PppServiceType.ovpn.rosValue, 'ovpn');
    });

    test('displayName is human-readable', () {
      expect(PppServiceType.any.displayName, 'Any');
      expect(PppServiceType.pppoe.displayName, 'PPPoE');
      expect(PppServiceType.l2tp.displayName, 'L2TP');
    });

    test('fromRos is case-insensitive', () {
      expect(PppServiceType.fromRos('PPPoE'), PppServiceType.pppoe);
      expect(PppServiceType.fromRos('L2TP'), PppServiceType.l2tp);
    });
  });

  // ── PppSecret.fromApiMap ─────────────────────────────────────────────────

  group('PppSecret.fromApiMap', () {
    test('parses all fields correctly', () {
      final map = {
        '.id': '*1',
        'name': 'user1',
        'password': 'pass1',
        'service': 'pppoe',
        'profile': 'ppprofile',
        'disabled': 'false',
        'comment': 'test comment',
        'local-address': '10.0.0.1',
        'remote-address': '192.168.1.100',
        'caller-id': '08:00:27:00:00:01',
        'last-logged-out': 'jan/01/2025 12:00:00',
        'routes': '10.10.0.0/24',
      };
      final secret = PppSecret.fromApiMap(map);
      expect(secret.id, '*1');
      expect(secret.name, 'user1');
      expect(secret.password, 'pass1');
      expect(secret.service, PppServiceType.pppoe);
      expect(secret.profile, 'ppprofile');
      expect(secret.disabled, isFalse);
      expect(secret.comment, 'test comment');
      expect(secret.localAddress, '10.0.0.1');
      expect(secret.remoteAddress, '192.168.1.100');
      expect(secret.callerId, '08:00:27:00:00:01');
    });

    test('empty optional fields become null', () {
      final map = {
        '.id': '*2',
        'name': 'user2',
        'password': '',
        'service': 'any',
        'profile': 'default',
        'disabled': 'false',
        'comment': '',
        'local-address': '',
        'remote-address': '',
      };
      final secret = PppSecret.fromApiMap(map);
      expect(secret.comment, isNull);
      expect(secret.localAddress, isNull);
      expect(secret.remoteAddress, isNull);
      expect(secret.callerId, isNull);
    });

    test('disabled=true is parsed correctly', () {
      final map = {'.id': '*3', 'name': 'user3', 'disabled': 'true'};
      final secret = PppSecret.fromApiMap(map);
      expect(secret.disabled, isTrue);
    });

    test('equality is based on id', () {
      final a = PppSecret.fromApiMap({'.id': '*1', 'name': 'a'});
      final b = PppSecret.fromApiMap({'.id': '*1', 'name': 'b'});
      final c = PppSecret.fromApiMap({'.id': '*2', 'name': 'a'});
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('copyWith updates specific fields', () {
      final original = PppSecret.fromApiMap({'.id': '*1', 'name': 'user1', 'disabled': 'false'});
      final updated = original.copyWith(disabled: true, comment: 'new');
      expect(updated.id, '*1');
      expect(updated.name, 'user1');
      expect(updated.disabled, isTrue);
      expect(updated.comment, 'new');
    });
  });

  // ── PppProfile.fromApiMap ────────────────────────────────────────────────

  group('PppProfile.fromApiMap', () {
    test('parses fields correctly', () {
      final map = {
        '.id': '*1',
        'name': 'default',
        'rate-limit': '10M/10M',
        'local-address': '10.0.0.1',
        'remote-address': 'vpn-pool',
        'session-timeout': '1d',
        'idle-timeout': '1h',
        'only-one': 'yes',
        'comment': 'main profile',
      };
      final profile = PppProfile.fromApiMap(map);
      expect(profile.id, '*1');
      expect(profile.name, 'default');
      expect(profile.rateLimit, '10M/10M');
      expect(profile.onlyOne, isTrue);
      expect(profile.comment, 'main profile');
    });

    test('empty fields become null', () {
      final map = {'.id': '*2', 'name': 'minimal', 'only-one': 'no'};
      final profile = PppProfile.fromApiMap(map);
      expect(profile.rateLimit, isNull);
      expect(profile.localAddress, isNull);
      expect(profile.onlyOne, isFalse);
    });
  });

  // ── PppActive.fromApiMap ─────────────────────────────────────────────────

  group('PppActive.fromApiMap', () {
    test('parses all fields', () {
      final map = {
        '.id': '*1',
        'name': 'user1',
        'service': 'pppoe',
        'address': '192.168.1.10',
        'uptime': '3h',
        'caller-id': '08:00:27:00:00:01',
        'encoding': 'MPPE128',
        'session-id': 'sess123',
      };
      final active = PppActive.fromApiMap(map);
      expect(active.id, '*1');
      expect(active.name, 'user1');
      expect(active.service, 'pppoe');
      expect(active.address, '192.168.1.10');
      expect(active.uptime, '3h');
      expect(active.callerId, '08:00:27:00:00:01');
      expect(active.encoding, 'MPPE128');
      expect(active.sessionId, 'sess123');
    });
  });

  // ── PppSecretCreate.toApiParams ──────────────────────────────────────────

  group('PppSecretCreate.toApiParams', () {
    test('includes required fields', () {
      const params = PppSecretCreate(
        name: 'user1',
        password: 'pass1',
        service: PppServiceType.pppoe,
        profile: 'default',
      );
      final map = params.toApiParams();
      expect(map['name'], 'user1');
      expect(map['password'], 'pass1');
      expect(map['service'], 'pppoe');
      expect(map['profile'], 'default');
      expect(map.containsKey('disabled'), isFalse);
    });

    test('disabled=true adds disabled=yes', () {
      const params = PppSecretCreate(
        name: 'u',
        password: 'p',
        disabled: true,
      );
      expect(params.toApiParams()['disabled'], 'yes');
    });

    test('optional fields only included when non-empty', () {
      const params = PppSecretCreate(
        name: 'u',
        password: 'p',
        comment: 'test',
        localAddress: '10.0.0.1',
        remoteAddress: '',
      );
      final map = params.toApiParams();
      expect(map['comment'], 'test');
      expect(map['local-address'], '10.0.0.1');
      expect(map.containsKey('remote-address'), isFalse);
    });
  });

  // ── PppSecretUpdate.toApiParams ──────────────────────────────────────────

  group('PppSecretUpdate.toApiParams', () {
    test('empty update produces empty map', () {
      const update = PppSecretUpdate();
      expect(update.toApiParams(), isEmpty);
    });

    test('only non-null fields included', () {
      const update = PppSecretUpdate(
        name: 'newname',
        disabled: false,
        service: PppServiceType.l2tp,
      );
      final map = update.toApiParams();
      expect(map['name'], 'newname');
      expect(map['disabled'], 'no');
      expect(map['service'], 'l2tp');
      expect(map.containsKey('password'), isFalse);
      expect(map.containsKey('profile'), isFalse);
    });
  });

  // ── PppData counters ─────────────────────────────────────────────────────

  group('PppData', () {
    test('counters computed correctly', () {
      final s1 = PppSecret.fromApiMap({'.id': '*1', 'name': 'u1', 'disabled': 'false'});
      final s2 = PppSecret.fromApiMap({'.id': '*2', 'name': 'u2', 'disabled': 'true'});
      final data = PppData(
        routerId: 'r1',
        secrets: [s1, s2],
        profiles: [],
        activeSessions: [],
        fetchedAt: DateTime(2026),
      );
      expect(data.totalSecrets, 2);
      expect(data.disabledSecrets, 1);
      expect(data.activeCount, 0);
    });
  });

  // ── PppSecretValidation ──────────────────────────────────────────────────

  group('PppSecretValidation.validateName', () {
    test('empty name returns error', () {
      expect(PppSecretValidation.validateName(''), isNotNull);
      expect(PppSecretValidation.validateName('  '), isNotNull);
    });

    test('valid names pass', () {
      expect(PppSecretValidation.validateName('user1'), isNull);
      expect(PppSecretValidation.validateName('user_name'), isNull);
      expect(PppSecretValidation.validateName('user.name'), isNull);
      expect(PppSecretValidation.validateName('user@domain'), isNull);
    });

    test('invalid characters rejected', () {
      expect(PppSecretValidation.validateName('user name'), isNotNull);
      expect(PppSecretValidation.validateName('user/name'), isNotNull);
    });

    test('name > 64 chars rejected', () {
      final long = 'a' * 65;
      expect(PppSecretValidation.validateName(long), isNotNull);
    });
  });

  group('PppSecretValidation.validatePassword', () {
    test('empty password returns error', () {
      expect(PppSecretValidation.validatePassword(''), isNotNull);
    });

    test('valid password passes', () {
      expect(PppSecretValidation.validatePassword('pass123'), isNull);
      expect(PppSecretValidation.validatePassword('complex!P@ss'), isNull);
    });

    test('password > 64 chars rejected', () {
      expect(PppSecretValidation.validatePassword('a' * 65), isNotNull);
    });
  });

  group('PppSecretValidation.validateProfile', () {
    test('empty profile returns error', () {
      expect(PppSecretValidation.validateProfile(''), isNotNull);
      expect(PppSecretValidation.validateProfile('  '), isNotNull);
    });

    test('valid profile passes', () {
      expect(PppSecretValidation.validateProfile('default'), isNull);
      expect(PppSecretValidation.validateProfile('my-profile'), isNull);
    });
  });

  group('PppSecretValidation.validateIpOrEmpty', () {
    test('null or empty returns null (valid)', () {
      expect(PppSecretValidation.validateIpOrEmpty(null, 'addr'), isNull);
      expect(PppSecretValidation.validateIpOrEmpty('', 'addr'), isNull);
    });

    test('valid IPv4 passes', () {
      expect(PppSecretValidation.validateIpOrEmpty('192.168.1.1', 'addr'), isNull);
      expect(PppSecretValidation.validateIpOrEmpty('10.0.0.1', 'addr'), isNull);
    });

    test('valid pool name passes', () {
      expect(PppSecretValidation.validateIpOrEmpty('my-pool', 'addr'), isNull);
      expect(PppSecretValidation.validateIpOrEmpty('pool_1', 'addr'), isNull);
    });

    test('invalid value returns error', () {
      expect(PppSecretValidation.validateIpOrEmpty('not valid!', 'addr'), isNotNull);
    });
  });

  group('PppSecretValidation.validate (full)', () {
    test('valid params produces no errors', () {
      const params = PppSecretCreate(
        name: 'user1',
        password: 'pass1',
        profile: 'default',
      );
      final result = PppSecretValidation.validate(params);
      expect(result.isValid, isTrue);
    });

    test('invalid params produces errors', () {
      const params = PppSecretCreate(
        name: '',
        password: '',
        profile: '',
      );
      final result = PppSecretValidation.validate(params);
      expect(result.isValid, isFalse);
      expect(result.nameError, isNotNull);
      expect(result.passwordError, isNotNull);
      expect(result.profileError, isNotNull);
    });
  });
}
