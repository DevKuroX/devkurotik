/// Unit tests for RouterModel.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/router_model.dart';

void main() {
  group('RouterGroup', () {
    test('fromString returns correct group', () {
      expect(RouterGroup.fromString('production'), RouterGroup.production);
      expect(RouterGroup.fromString('home'), RouterGroup.home);
      expect(RouterGroup.fromString('office'), RouterGroup.office);
    });

    test('fromString returns ungrouped for unknown value', () {
      expect(RouterGroup.fromString('invalid'), RouterGroup.ungrouped);
      expect(RouterGroup.fromString(''), RouterGroup.ungrouped);
    });

    test('all groups have non-empty labels', () {
      for (final g in RouterGroup.values) {
        expect(g.label, isNotEmpty);
      }
    });

    test('round-trip name → fromString', () {
      for (final g in RouterGroup.values) {
        expect(RouterGroup.fromString(g.name), g);
      }
    });
  });

  group('RouterModel', () {
    const model = RouterModel(
      id: 'test-id-1',
      name: 'Office Router',
      host: '192.168.88.1',
      port: 8728,
      username: 'admin',
      group: RouterGroup.office,
    );

    test('equality is id-based', () {
      const other = RouterModel(
        id: 'test-id-1',
        name: 'Different Name',
        host: '10.0.0.1',
        port: 8728,
        username: 'user',
        group: RouterGroup.home,
      );
      expect(model, equals(other));
    });

    test('models with different ids are not equal', () {
      const other = RouterModel(
        id: 'test-id-2',
        name: 'Office Router',
        host: '192.168.88.1',
        port: 8728,
        username: 'admin',
        group: RouterGroup.office,
      );
      expect(model, isNot(equals(other)));
    });

    test('copyWith preserves unchanged fields', () {
      final copy = model.copyWith(name: 'Updated Name');
      expect(copy.id, model.id);
      expect(copy.name, 'Updated Name');
      expect(copy.host, model.host);
      expect(copy.port, model.port);
      expect(copy.username, model.username);
      expect(copy.group, model.group);
    });

    test('copyWith can update all fields', () {
      final updated = model.copyWith(
        id: 'new-id',
        name: 'New',
        host: '10.0.0.1',
        port: 9999,
        username: 'root',
        group: RouterGroup.staging,
        note: 'staging router',
        healthStatus: RouterHealthStatus.reachable,
      );
      expect(updated.id, 'new-id');
      expect(updated.name, 'New');
      expect(updated.host, '10.0.0.1');
      expect(updated.port, 9999);
      expect(updated.username, 'root');
      expect(updated.group, RouterGroup.staging);
      expect(updated.note, 'staging router');
      expect(updated.healthStatus, RouterHealthStatus.reachable);
    });

    test('toString does not contain password', () {
      final str = model.toString();
      expect(str, isNot(contains('password')));
      expect(str, contains('test-id-1'));
      expect(str, contains('Office Router'));
    });

    test('default healthStatus is unknown', () {
      expect(model.healthStatus, RouterHealthStatus.unknown);
    });

    test('hashCode is id-based', () {
      expect(model.hashCode, equals('test-id-1'.hashCode));
    });
  });

  group('RouterHealthStatus', () {
    test('all values are defined', () {
      expect(RouterHealthStatus.values, hasLength(5));
      expect(RouterHealthStatus.values, contains(RouterHealthStatus.unknown));
      expect(RouterHealthStatus.values, contains(RouterHealthStatus.reachable));
      expect(
        RouterHealthStatus.values,
        contains(RouterHealthStatus.unreachable),
      );
      expect(
        RouterHealthStatus.values,
        contains(RouterHealthStatus.authFailed),
      );
      expect(RouterHealthStatus.values, contains(RouterHealthStatus.timeout));
    });
  });
}
