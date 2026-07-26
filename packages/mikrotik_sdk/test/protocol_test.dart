import 'dart:typed_data';

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('RouterOS protocol framing', () {
    // ─── encodeLength ──────────────────────────────────────────────────────

    group('encodeLength', () {
      test('encodes 0 as single zero byte', () {
        expect(encodeLength(0), equals(Uint8List.fromList([0x00])));
      });

      test('encodes 1-byte range (1–127)', () {
        expect(encodeLength(1), equals(Uint8List.fromList([0x01])));
        expect(encodeLength(127), equals(Uint8List.fromList([0x7F])));
      });

      test('encodes 2-byte range (128–16383)', () {
        // 128 = 0x80 → encode as 0x80 | (0 << 6 | 0), 0x80 = 10000000 10000000
        final encoded = encodeLength(128);
        expect(encoded.length, equals(2));
        final decoded = decodeLength(encoded, 0);
        expect(decoded.value, equals(128));
        expect(decoded.bytesConsumed, equals(2));
      });

      test('encodes 3-byte range (16384–2097151)', () {
        const val = 16384;
        final encoded = encodeLength(val);
        expect(encoded.length, equals(3));
        final decoded = decodeLength(encoded, 0);
        expect(decoded.value, equals(val));
      });

      test('encodes 4-byte range (2097152–268435455)', () {
        const val = 2097152;
        final encoded = encodeLength(val);
        expect(encoded.length, equals(4));
        final decoded = decodeLength(encoded, 0);
        expect(decoded.value, equals(val));
      });

      test('encodes 5-byte range (268435456+)', () {
        const val = 268435456;
        final encoded = encodeLength(val);
        expect(encoded.length, equals(5));
        final decoded = decodeLength(encoded, 0);
        expect(decoded.value, equals(val));
      });

      test('throws on negative length', () {
        expect(() => encodeLength(-1), throwsArgumentError);
      });
    });

    // ─── decodeLength ──────────────────────────────────────────────────────

    group('decodeLength', () {
      test('decodes 1-byte length', () {
        final result = decodeLength(Uint8List.fromList([0x05]), 0);
        expect(result.value, equals(5));
        expect(result.bytesConsumed, equals(1));
      });

      test('throws on empty buffer', () {
        expect(() => decodeLength(Uint8List(0), 0), throwsArgumentError);
      });

      test('throws on offset past end', () {
        expect(
          () => decodeLength(Uint8List.fromList([0x01]), 1),
          throwsArgumentError,
        );
      });

      test('roundtrip: encode then decode restores original value', () {
        final values = [0, 1, 100, 127, 128, 1000, 16384, 100000, 2097152];
        for (final val in values) {
          final encoded = encodeLength(val);
          final decoded = decodeLength(encoded, 0);
          expect(
            decoded.value,
            equals(val),
            reason: 'roundtrip failed for $val',
          );
          expect(decoded.bytesConsumed, equals(encoded.length));
        }
      });
    });

    // ─── encodeSentence / parseSentences ──────────────────────────────────

    group('encodeSentence', () {
      test('encodes words with zero terminator', () {
        final encoded = encodeSentence(['/login']);
        // Last byte must be 0x00
        expect(encoded.last, equals(0x00));
      });

      test('encodes empty sentence as single zero byte', () {
        final encoded = encodeSentence([]);
        expect(encoded, equals(Uint8List.fromList([0x00])));
      });

      test('encodes multi-word sentence', () {
        final encoded = encodeSentence([
          '/ip/hotspot/user/print',
          '?profile=daily',
        ]);
        expect(encoded.last, equals(0x00));
      });
    });

    group('parseSentences', () {
      test('parses a !done sentence', () {
        final bytes = encodeSentence(['!done']);
        final sentences = parseSentences(bytes);
        expect(sentences.length, equals(1));
        expect(sentences.first.isDone, isTrue);
      });

      test('parses a !trap sentence', () {
        final bytes = encodeSentence([
          '!trap',
          '=category=0',
          '=message=no such item',
        ]);
        final sentences = parseSentences(bytes);
        expect(sentences.length, equals(1));
        expect(sentences.first.isTrap, isTrue);
        expect(sentences.first.getAttribute('message'), equals('no such item'));
      });

      test('parses !re sentence with attributes', () {
        final bytes = encodeSentence([
          '!re',
          '=.id=*1',
          '=name=admin',
          '=profile=default',
        ]);
        final sentences = parseSentences(bytes);
        expect(sentences.length, equals(1));
        expect(sentences.first.isRe, isTrue);
        final map = sentences.first.toMap();
        expect(map['.id'], equals('*1'));
        expect(map['name'], equals('admin'));
        expect(map['profile'], equals('default'));
      });

      test('parses multiple sentences', () {
        final re = encodeSentence(['!re', '=name=user1']);
        final done = encodeSentence(['!done']);
        final combined = Uint8List.fromList([...re, ...done]);
        final sentences = parseSentences(combined);
        expect(sentences.length, equals(2));
        expect(sentences[0].isRe, isTrue);
        expect(sentences[1].isDone, isTrue);
      });

      test('RouterosSentence.replyWord returns first word', () {
        final s = RouterosSentence(['!re', '=name=test']);
        expect(s.replyWord, equals('!re'));
      });

      test('RouterosSentence is !fatal when first word is !fatal', () {
        final s = RouterosSentence(['!fatal', '=message=connection closed']);
        expect(s.isFatal, isTrue);
      });

      test('empty sentence replyWord is empty string', () {
        const s = RouterosSentence([]);
        expect(s.replyWord, equals(''));
      });
    });
  });
}
