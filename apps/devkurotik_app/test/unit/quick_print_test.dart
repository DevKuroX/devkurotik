// ignore_for_file: prefer_const_constructors
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:devkurotik_app/src/domain/models/voucher_models.dart';

void main() {
  group('QuickPrintPackage encoding', () {
    QuickPrintPackage makePkg({
      VoucherMode mode = VoucherMode.voucher,
      VoucherCharSet charSet = VoucherCharSet.digitMixed,
      String prefix = '',
      String limitUptime = '1h',
      int usernameLength = 8,
      String comment = 'Test',
    }) {
      return QuickPrintPackage(
        scriptId: '*1',
        name: 'TestPackage',
        server: '10.0.0.1',
        mode: mode,
        usernameLength: usernameLength,
        prefix: prefix,
        charSet: charSet,
        profile: 'default',
        limitUptime: limitUptime,
        limitBytesTotal: 0,
        comment: comment,
      );
    }

    test('encodeSource always starts with #', () {
      final source = makePkg().encodeSource();
      expect(source[0], equals('#'));
    });

    test('encodeSource has at least 9 parts separated by #', () {
      final source = makePkg().encodeSource();
      final parts = source.substring(1).split('#');
      expect(parts.length, greaterThanOrEqualTo(9));
    });

    test('voucher mode encoded as vc', () {
      final source = makePkg(mode: VoucherMode.voucher).encodeSource();
      expect(source.substring(1).split('#')[1], equals('vc'));
    });

    test('userpass mode encoded as up', () {
      final source = makePkg(mode: VoucherMode.userpass).encodeSource();
      expect(source.substring(1).split('#')[1], equals('up'));
    });

    test('round-trip: server preserved', () {
      final pkg = makePkg();
      final decoded =
          QuickPrintPackage.decodeSource('*1', 'TestPackage', pkg.encodeSource());
      expect(decoded?.server, equals('10.0.0.1'));
    });

    test('round-trip: mode preserved for voucher', () {
      final decoded = QuickPrintPackage.decodeSource(
        '*1', 'T', makePkg(mode: VoucherMode.voucher).encodeSource());
      expect(decoded?.mode, equals(VoucherMode.voucher));
    });

    test('round-trip: mode preserved for userpass', () {
      final decoded = QuickPrintPackage.decodeSource(
        '*1', 'T', makePkg(mode: VoucherMode.userpass).encodeSource());
      expect(decoded?.mode, equals(VoucherMode.userpass));
    });

    test('round-trip: charSet preserved', () {
      for (final cs in VoucherCharSet.values) {
        final pkg = makePkg(charSet: cs);
        final decoded = QuickPrintPackage.decodeSource(
            '*1', 'T', pkg.encodeSource());
        expect(decoded?.charSet, equals(cs),
            reason: 'charSet=$cs failed round-trip');
      }
    });

    test('round-trip: prefix preserved', () {
      final decoded = QuickPrintPackage.decodeSource(
        '*1', 'T', makePkg(prefix: 'vc').encodeSource());
      expect(decoded?.prefix, equals('vc'));
    });

    test('round-trip: usernameLength preserved', () {
      final decoded = QuickPrintPackage.decodeSource(
        '*1', 'T', makePkg(usernameLength: 12).encodeSource());
      expect(decoded?.usernameLength, equals(12));
    });

    test('round-trip: limitUptime preserved', () {
      final decoded = QuickPrintPackage.decodeSource(
        '*1', 'T', makePkg(limitUptime: '2h30m').encodeSource());
      expect(decoded?.limitUptime, equals('2h30m'));
    });

    test('round-trip: comment preserved', () {
      final decoded = QuickPrintPackage.decodeSource(
        '*1', 'T', makePkg(comment: 'my-batch').encodeSource());
      expect(decoded?.comment, equals('my-batch'));
    });

    test('decodeSource handles source without leading #', () {
      final source = makePkg().encodeSource().substring(1);
      final decoded = QuickPrintPackage.decodeSource('*1', 'T', source);
      expect(decoded, isNotNull);
    });

    test('decodeSource returns null for too-short source', () {
      expect(
        QuickPrintPackage.decodeSource('*1', 'T', '#a#b#c'),
        isNull,
      );
    });

    test('decodeSource returns null for empty source', () {
      expect(QuickPrintPackage.decodeSource('*1', 'T', ''), isNull);
    });
  });
}
