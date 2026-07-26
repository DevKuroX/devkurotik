// ignore_for_file: prefer_const_constructors
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:devkurotik_app/src/domain/models/voucher_models.dart';
import 'package:devkurotik_app/src/domain/services/voucher_generator_service.dart';

void main() {
  const service = VoucherGeneratorService();

  VoucherGenerationParams makeParams({
    int quantity = 5,
    VoucherMode mode = VoucherMode.voucher,
    VoucherCharSet charSet = VoucherCharSet.digitMixed,
    int usernameLength = 8,
    int passwordLength = 8,
    String prefix = '',
  }) {
    return VoucherGenerationParams(
      routerId: 'r',
      routerHost: '192.168.1.1',
      profileName: 'default',
      quantity: quantity,
      mode: mode,
      charSet: charSet,
      usernameLength: usernameLength,
      passwordLength: passwordLength,
      prefix: prefix,
    );
  }

  // ---------------------------------------------------------------------------
  // Basic generation
  // ---------------------------------------------------------------------------

  group('VoucherGeneratorService.generate', () {
    test('returns correct quantity', () {
      final items = service.generate(makeParams(quantity: 10));
      expect(items.length, equals(10));
    });

    test('all names are unique within a batch', () {
      final items = service.generate(makeParams(quantity: 50));
      final names = items.map((i) => i.name).toSet();
      expect(names.length, equals(50));
    });

    test('voucher mode: name == password', () {
      final items = service.generate(makeParams(mode: VoucherMode.voucher));
      for (final item in items) {
        expect(item.name, equals(item.password));
        expect(item.isVoucherMode, isTrue);
      }
    });

    test('userpass mode: name != password (with high probability)', () {
      // With 8 chars from digitMixed the chance of collision is negligible.
      final items = service.generate(
        makeParams(mode: VoucherMode.userpass, quantity: 10),
      );
      var separateCount = 0;
      for (final item in items) {
        if (item.name != item.password) separateCount++;
      }
      // At least 8 of 10 should be different (statistically guaranteed).
      expect(separateCount, greaterThan(6));
    });

    test('username length matches usernameLength', () {
      final items = service.generate(makeParams(usernameLength: 6));
      for (final item in items) {
        expect(item.name.length, equals(6));
      }
    });

    test('userpass password length matches passwordLength', () {
      final items = service.generate(
        makeParams(mode: VoucherMode.userpass, passwordLength: 10),
      );
      for (final item in items) {
        expect(item.password.length, equals(10));
      }
    });

    test('prefix is prepended to username', () {
      final items = service.generate(makeParams(prefix: 'vc', usernameLength: 8));
      for (final item in items) {
        expect(item.name, startsWith('vc'));
        expect(item.name.length, equals(8));
      }
    });

    test('lowercase charset produces lowercase only names', () {
      final items = service.generate(
        makeParams(charSet: VoucherCharSet.lower, usernameLength: 8, quantity: 20),
      );
      for (final item in items) {
        // RouterosRandom.lower excludes ambiguous chars so uses subset of a-z
        expect(item.name, matches(r'^[a-z]+$'));
      }
    });

    test('numeric charset produces numeric only names', () {
      final items = service.generate(
        makeParams(charSet: VoucherCharSet.numeric, usernameLength: 8, quantity: 20),
      );
      for (final item in items) {
        expect(item.name, matches(r'^[0-9]+$'));
      }
    });

    test('generates 500 items without crashing', () {
      final items = service.generate(makeParams(quantity: 500));
      expect(items.length, equals(500));
    });

    test('with seeded rng produces deterministic output', () {
      final rng1 = Random(42);
      final rng2 = Random(42);
      final items1 = service.generate(makeParams(quantity: 5), rng: rng1);
      final items2 = service.generate(makeParams(quantity: 5), rng: rng2);
      expect(items1.map((i) => i.name).toList(),
          equals(items2.map((i) => i.name).toList()));
    });
  });

  // ---------------------------------------------------------------------------
  // VoucherCharSet character generation
  // ---------------------------------------------------------------------------

  group('Character set generation', () {
    test('lower charset generates from lowercase pool', () {
      final items = service.generate(
        makeParams(charSet: VoucherCharSet.lower, quantity: 100),
      );
      final allChars = items.map((i) => i.name).join();
      expect(allChars, matches(r'^[a-z]+$'));
    });

    test('upper charset generates from uppercase pool', () {
      final items = service.generate(
        makeParams(charSet: VoucherCharSet.upper, quantity: 50),
      );
      final allChars = items.map((i) => i.name).join();
      expect(allChars, matches(r'^[A-Z]+$'));
    });

    test('digitUpper charset generates from digits+uppercase pool', () {
      final items = service.generate(
        makeParams(charSet: VoucherCharSet.digitUpper, quantity: 50),
      );
      final allChars = items.map((i) => i.name).join();
      expect(allChars, matches(r'^[0-9A-Z]+$'));
    });
  });
}
