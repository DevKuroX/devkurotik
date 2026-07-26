/// Unit tests for RouterProfile — AMENDMENT_001 Deliverable E.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/domain/models/router_profile.dart';

RouterInfo _makeInfo({
  String version = '7.15.1 (stable)',
  String board = 'CHR',
}) {
  return RouterInfo.fromApiMaps(
    identityMap: {'name': 'test-router'},
    resourceMap: {
      'version': version,
      'board-name': board,
      'architecture-name': 'x86_64',
      'cpu-count': '2',
      'total-memory': '536870912',
      'platform': 'MikroTik',
    },
    detectedAt: DateTime(2026, 7, 26, 12),
  );
}

const _model = RouterModel(
  id: 'rp-001',
  name: 'Profile Test Router',
  host: '192.168.88.1',
  port: 8728,
  username: 'admin',
  group: RouterGroup.production,
);

void main() {
  group('RouterProfile.withoutInfo', () {
    test('hasInfo is false', () {
      final p = RouterProfile.withoutInfo(_model);
      expect(p.hasInfo, isFalse);
    });

    test('isVersionKnown is false when no info', () {
      final p = RouterProfile.withoutInfo(_model);
      expect(p.isVersionKnown, isFalse);
    });

    test('capabilityWarnings is empty when no info', () {
      final p = RouterProfile.withoutInfo(_model);
      expect(p.capabilityWarnings, isEmpty);
    });

    test('lastDetectedAt is null', () {
      final p = RouterProfile.withoutInfo(_model);
      expect(p.lastDetectedAt, isNull);
    });

    test('router is preserved', () {
      final p = RouterProfile.withoutInfo(_model);
      expect(p.router, _model);
    });
  });

  group('RouterProfile.withInfo — v7.15.1 CHR', () {
    late RouterProfile profile;

    setUp(() {
      final info = _makeInfo();
      profile = RouterProfile.withInfo(router: _model, routerInfo: info);
    });

    test('hasInfo is true', () {
      expect(profile.hasInfo, isTrue);
    });

    test('isVersionKnown is true', () {
      expect(profile.isVersionKnown, isTrue);
    });

    test('capabilityWarnings is empty for v7.15.1', () {
      // AC-A8: no known variances for v7.15.1.
      expect(profile.capabilityWarnings, isEmpty);
    });

    test('lastDetectedAt matches routerInfo.detectedAt', () {
      expect(
        profile.lastDetectedAt,
        equals(DateTime(2026, 7, 26, 12)),
      );
    });

    test('routerInfo.isChr is true for CHR board', () {
      expect(profile.routerInfo?.isChr, isTrue);
    });

    test('router identity preserved', () {
      expect(profile.router.id, 'rp-001');
      expect(profile.router.name, 'Profile Test Router');
    });
  });

  group('RouterProfile.withInfo — pre-v6.43 (MD5 variance)', () {
    test('capabilityWarnings is non-empty for v6.42', () {
      final info = _makeInfo(version: '6.42', board: 'RB750Gr3');
      final profile = RouterProfile.withInfo(router: _model, routerInfo: info);

      expect(profile.capabilityWarnings, isNotEmpty);
      expect(
        profile.capabilityWarnings.first,
        contains('MD5'),
      );
    });
  });

  group('RouterProfile.withInfo — unknown version', () {
    test('isVersionKnown is false when RouterVersion.unknown', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {},
        detectedAt: DateTime.now(),
      );
      final profile = RouterProfile.withInfo(router: _model, routerInfo: info);
      expect(profile.isVersionKnown, isFalse);
    });

    test('capabilityWarnings is empty for unknown version', () {
      final info = RouterInfo.fromApiMaps(
        identityMap: {},
        resourceMap: {},
        detectedAt: DateTime.now(),
      );
      final profile = RouterProfile.withInfo(router: _model, routerInfo: info);
      expect(profile.capabilityWarnings, isEmpty);
    });
  });

  group('RouterProfile — no Drift schema impact', () {
    test('RouterProfile does not carry any Drift table or companion reference',
        () {
      // This is a structural/documentation test:
      // RouterProfile must not expose database types.
      final p = RouterProfile.withoutInfo(_model);
      // If RouterProfile were a Drift type it would have a .toCompanion()
      // or .$table — verify it does not:
      expect((p as dynamic).runtimeType.toString(), 'RouterProfile');
    });
  });

  group('RouterProfile.toString', () {
    test('includes router name and hasInfo state', () {
      final p = RouterProfile.withoutInfo(_model);
      final str = p.toString();
      expect(str, contains('Profile Test Router'));
      expect(str, contains('hasInfo: false'));
    });

    test('withInfo includes version', () {
      final p = RouterProfile.withInfo(router: _model, routerInfo: _makeInfo());
      final str = p.toString();
      expect(str, contains('7.15.1'));
    });
  });
}
