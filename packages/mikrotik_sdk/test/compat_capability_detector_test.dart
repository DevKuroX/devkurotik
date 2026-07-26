/// Unit tests for CapabilityDetector — AMENDMENT_001 Deliverable D.
///
/// Uses MockRouterosServer from connection_mock_test.dart pattern to simulate
/// RouterOS API responses for connect/identity/resource sequences.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

// ─── Minimal mock server for CapabilityDetector tests ─────────────────────────

/// A minimal RouterOS mock server.
///
/// Sends one queued response (possibly multi-sentence) per received sentence.
class _MockCapServer {
  final ServerSocket _server;
  Socket? _client;
  late StreamSubscription<Socket> _serverSub;

  /// Each entry is a complete byte payload to send back for one received sentence.
  final List<Uint8List> _responseQueue = [];
  final Completer<void> _connected = Completer();

  _MockCapServer._(this._server);

  static Future<_MockCapServer> start() async {
    final server =
        await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    return _MockCapServer._(server);
  }

  int get port => _server.port;

  /// Queue a single-sentence response.
  void queueSentence(List<String> words) =>
      _responseQueue.add(Uint8List.fromList(encodeSentence(words)));

  /// Queue a multi-sentence response (e.g. !re + !done) as one payload.
  void queueMulti(List<List<String>> sentences) {
    final buf = <int>[];
    for (final s in sentences) {
      buf.addAll(encodeSentence(s));
    }
    _responseQueue.add(Uint8List.fromList(buf));
  }

  void listen() {
    _serverSub = _server.listen((socket) {
      _client = socket;
      socket.listen((data) {
        final bytes = Uint8List.fromList(data);
        final sentences = parseSentences(bytes);
        for (final _ in sentences) {
          if (_responseQueue.isNotEmpty) {
            socket.add(_responseQueue.removeAt(0));
          }
        }
      });
      if (!_connected.isCompleted) _connected.complete();
    });
  }

  Future<void> close() async {
    await _client?.close();
    await _serverSub.cancel();
    await _server.close();
  }
}

MikrotikCredentials _creds(int port) => MikrotikCredentials(
      host: '127.0.0.1',
      username: 'admin',
      password: 'test',
      port: port,
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('CapabilityDetector — mock server', () {
    late _MockCapServer server;

    setUp(() async {
      server = await _MockCapServer.start();
      server.listen();
    });

    tearDown(() => server.close());

    test('returns RouterInfo with correct version from mock CHR v7', () async {
      // 1. Auth → !done
      server.queueSentence(['!done']);
      // 2. /system/identity/print → !re name + !done (combined payload)
      server.queueMulti([
        ['!re', '=name=mock-router'],
        ['!done'],
      ]);
      // 3. /system/resource/print → !re fields + !done (combined)
      server.queueMulti([
        [
          '!re',
          '=version=7.15.1 (stable)',
          '=board-name=CHR',
          '=architecture-name=x86_64',
          '=cpu-count=1',
          '=total-memory=536870912',
          '=platform=MikroTik',
        ],
        ['!done'],
      ]);

      final info = await CapabilityDetector(
        timeout: const Duration(seconds: 5),
      ).detect(credentials: _creds(server.port));

      expect(info.identity, 'mock-router');
      expect(info.version.major, 7);
      expect(info.version.minor, 15);
      expect(info.isChr, isTrue);
      expect(info.isVirtual, isTrue);
      expect(info.board, 'CHR');
      expect(info.architecture, 'x86_64');
      expect(info.cpuCount, 1);
      expect(info.platform, 'MikroTik');
      expect(info.detectedAt, isNotNull);
    });

    test('returns RouterInfo with version=unknown when resource returns no fields',
        () async {
      server.queueSentence(['!done']); // auth
      server.queueMulti([
        ['!re', '=name=partial-router'],
        ['!done'],
      ]); // identity
      server.queueSentence(['!done']); // resource → no !re, just !done

      final info = await CapabilityDetector(
        timeout: const Duration(seconds: 5),
      ).detect(credentials: _creds(server.port));

      expect(info.identity, 'partial-router');
      expect(info.version.isUnknown, isTrue);
    });

    test('propagates RouterosAuthException on !trap during login', () async {
      server.queueSentence([
        '!trap',
        '=message=invalid user name or password (6)',
        '=category=2',
      ]);

      await expectLater(
        CapabilityDetector(timeout: const Duration(seconds: 5))
            .detect(credentials: _creds(server.port)),
        throwsA(isA<RouterosAuthException>()),
      );
    });

    test('connection refused → connection-related exception', () async {
      final unusedPort = server.port + 1000;
      await expectLater(
        CapabilityDetector(timeout: const Duration(seconds: 2)).detect(
          credentials: MikrotikCredentials(
            host: '127.0.0.1',
            username: 'admin',
            password: 'pass',
            port: unusedPort,
          ),
        ),
        throwsA(
          anyOf(
            isA<RouterosConnectionException>(),
            isA<RouterosTimeoutException>(),
            isA<RouterosRetryExhaustedException>(),
          ),
        ),
      );
    });
  });

  group('CapabilityDetector — construction', () {
    test('default timeout is 10 seconds', () {
      const d = CapabilityDetector();
      expect(d.timeout, const Duration(seconds: 10));
    });

    test('custom timeout is stored', () {
      const d = CapabilityDetector(timeout: Duration(seconds: 3));
      expect(d.timeout, const Duration(seconds: 3));
    });
  });
}
