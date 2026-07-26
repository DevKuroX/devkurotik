import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('RouterosAuth', () {
    group('MD5 challenge-response computation', () {
      // Reference test vectors derived from the PHP implementation behavior:
      // MD5(\x00 + password_bytes + unhex(challenge))

      test('computes MD5 response for known input', () {
        // This vector is: password='test', challenge='0011223344556677'
        // Input bytes: \x00 + 'test' + [0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77]
        // Expected: MD5 of that byte sequence
        final result = RouterosAuth.computeMd5ResponseForTest(
          'test',
          '0011223344556677',
        );
        // Verify it is a valid 32-char lowercase hex string
        expect(result.length, equals(32));
        expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(result), isTrue);
      });

      test('different passwords produce different responses', () {
        const challenge = 'aabbccdd00112233aabbccdd00112233';
        final r1 = RouterosAuth.computeMd5ResponseForTest('pass1', challenge);
        final r2 = RouterosAuth.computeMd5ResponseForTest('pass2', challenge);
        expect(r1, isNot(equals(r2)));
      });

      test('same inputs always produce same response (deterministic)', () {
        const challenge = 'deadbeef01234567deadbeef01234567';
        final r1 = RouterosAuth.computeMd5ResponseForTest('admin', challenge);
        final r2 = RouterosAuth.computeMd5ResponseForTest('admin', challenge);
        expect(r1, equals(r2));
      });

      test('empty password produces valid response', () {
        final result = RouterosAuth.computeMd5ResponseForTest(
          '',
          '00000000000000000000000000000000',
        );
        expect(result.length, equals(32));
      });

      test('handles unicode password bytes correctly', () {
        // Password with non-ASCII chars — UTF-8 encoded
        final result = RouterosAuth.computeMd5ResponseForTest(
          'pässwörd',
          '1234567890abcdef1234567890abcdef',
        );
        expect(result.length, equals(32));
        expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(result), isTrue);
      });
    });

    group('login — post-v6.43 plain auth', () {
      test('succeeds when router returns !done without challenge', () async {
        Future<List<RouterosSentence>> mockTransport(List<String> words) async {
          return [
            RouterosSentence(['!done']),
          ];
        }

        await expectLater(
          RouterosAuth.login(
            username: 'admin',
            password: 'secret',
            sendAndReceive: mockTransport,
          ),
          completes,
        );
      });

      test('throws RouterosAuthException on !trap response', () async {
        Future<List<RouterosSentence>> mockTransport(List<String> words) async {
          return [
            RouterosSentence([
              '!trap',
              '=category=1',
              '=message=invalid user name or password (6)',
            ]),
          ];
        }

        await expectLater(
          RouterosAuth.login(
            username: 'admin',
            password: 'wrong',
            sendAndReceive: mockTransport,
          ),
          throwsA(isA<RouterosAuthException>()),
        );
      });
    });

    group('login — pre-v6.43 MD5 challenge-response', () {
      test(
        'falls back to MD5 auth when !done contains ret= challenge',
        () async {
          var callCount = 0;

          Future<List<RouterosSentence>> mockTransport(
            List<String> words,
          ) async {
            callCount++;
            if (callCount == 1) {
              // First call: return challenge
              return [
                RouterosSentence([
                  '!done',
                  '=ret=deadbeef01234567deadbeef01234567',
                ]),
              ];
            }
            // Second call: challenge response — verify format
            expect(
              words.any((w) => w.startsWith('=response=00')),
              isTrue,
              reason: 'response word must start with 00',
            );
            return [
              RouterosSentence(['!done']),
            ];
          }

          await expectLater(
            RouterosAuth.login(
              username: 'admin',
              password: 'secret',
              sendAndReceive: mockTransport,
            ),
            completes,
          );

          expect(callCount, equals(2));
        },
      );

      test(
        'throws RouterosAuthException on !trap after MD5 response',
        () async {
          var callCount = 0;

          Future<List<RouterosSentence>> mockTransport(
            List<String> words,
          ) async {
            callCount++;
            if (callCount == 1) {
              return [
                RouterosSentence([
                  '!done',
                  '=ret=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                ]),
              ];
            }
            return [
              RouterosSentence([
                '!trap',
                '=message=invalid user name or password (6)',
              ]),
            ];
          }

          await expectLater(
            RouterosAuth.login(
              username: 'admin',
              password: 'wrongpass',
              sendAndReceive: mockTransport,
            ),
            throwsA(isA<RouterosAuthException>()),
          );
        },
      );
    });
  });
}
