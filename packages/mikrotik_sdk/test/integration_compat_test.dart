/// Real CHR integration test for CapabilityDetector — AMENDMENT_001 Section 8.4.
///
/// Runs against the live CHR v7 environment specified in chr.txt.
/// This file is NOT run in CI — requires a live RouterOS target.
///
/// Required evidence per AMENDMENT_001:
///   - RouterInfo.version.raw
///   - RouterInfo.isChr
///   - RouterInfo.board
///   - CapabilityMatrix.supportsPlainAuth(version)
library;

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

const _host = '54.147.121.92';
const _username = 'admin';
const _password = 'Ssh19233@';
const _port = 8728;

void main() {
  group('CapabilityDetector — CHR v7 live integration', () {
    late CapabilityDetector detector;
    late MikrotikCredentials credentials;

    setUp(() {
      detector = const CapabilityDetector(timeout: Duration(seconds: 15));
      credentials = const MikrotikCredentials(
        host: _host,
        username: _username,
        password: _password,
        port: _port,
      );
    });

    test('detect() returns RouterInfo from CHR v7', () async {
      final info = await detector.detect(credentials: credentials);

      // Version must be RouterOS v7.x.
      expect(info.version.major, greaterThanOrEqualTo(7));
      expect(info.version.isUnknown, isFalse);
      print('RouterInfo.version.raw   : ${info.version.raw}');
      print('RouterInfo.board         : ${info.board}');
      print('RouterInfo.isChr         : ${info.isChr}');
      print('RouterInfo.isVirtual     : ${info.isVirtual}');
      print('RouterInfo.identity      : ${info.identity}');
      print('RouterInfo.architecture  : ${info.architecture}');
      print('RouterInfo.cpuCount      : ${info.cpuCount}');
      print('RouterInfo.platform      : ${info.platform}');
    });

    test('board starts with "CHR" on Cloud Hosted Router', () async {
      final info = await detector.detect(credentials: credentials);
      expect(info.isChr, isTrue,
          reason: 'Expected CHR board — got board: "${info.board}"');
      // Real CHR v7 on AWS returns "CHR Amazon EC2 t3.small"
      expect(info.board.toUpperCase(), startsWith('CHR'));
    });

    test('version parsed as major=7, minor>=15', () async {
      final info = await detector.detect(credentials: credentials);
      expect(info.version.major, 7);
      expect(info.version.minor, greaterThanOrEqualTo(15));
    });

    test('CapabilityMatrix.supportsPlainAuth for CHR v7 → true', () async {
      final info = await detector.detect(credentials: credentials);
      expect(CapabilityMatrix.supportsPlainAuth(info.version), isTrue);
      print('supportsPlainAuth : ${CapabilityMatrix.supportsPlainAuth(info.version)}');
    });

    test('CapabilityMatrix.requiresMd5Auth for CHR v7 → false', () async {
      final info = await detector.detect(credentials: credentials);
      expect(CapabilityMatrix.requiresMd5Auth(info.version), isFalse);
    });

    test('CapabilityMatrix.supportsHotspot for CHR v7 → true', () async {
      final info = await detector.detect(credentials: credentials);
      expect(CapabilityMatrix.supportsHotspot(info.version), isTrue);
    });

    test('CapabilityMatrix.supportsPppoe for CHR v7 → true', () async {
      final info = await detector.detect(credentials: credentials);
      expect(CapabilityMatrix.supportsPppoe(info.version), isTrue);
    });

    test('CapabilityMatrix.supportsApiSsl for CHR v7 → true', () async {
      final info = await detector.detect(credentials: credentials);
      expect(CapabilityMatrix.supportsApiSsl(info.version), isTrue);
    });

    test('CapabilityMatrix.hasKnownVariance for CHR v7 → false', () async {
      final info = await detector.detect(credentials: credentials);
      expect(CapabilityMatrix.hasKnownVariance(info.version), isFalse);
      print('hasKnownVariance  : ${CapabilityMatrix.hasKnownVariance(info.version)}');
    });

    test('full CapabilityMatrix summary is printed for evidence', () async {
      final info = await detector.detect(credentials: credentials);
      final summary = CapabilityMatrix.summary(info.version);
      print('--- CapabilityMatrix.summary ---');
      summary.forEach((k, v) => print('  $k: $v'));
    });
  });
}
