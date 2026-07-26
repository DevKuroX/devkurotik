import 'package:mikrotik_sdk/mikrotik_sdk.dart';
import 'package:test/test.dart';

void main() {
  group('MikrotikConnectionPool', () {
    test('connectionCount is 0 initially', () {
      final pool = MikrotikConnectionPool();
      expect(pool.connectionCount, equals(0));
    });

    test('hasConnection returns false for unknown routerId', () {
      final pool = MikrotikConnectionPool();
      expect(pool.hasConnection('router-1'), isFalse);
    });

    test(
      'acquire throws ArgumentError without credentials for new connection',
      () async {
        final pool = MikrotikConnectionPool();
        await expectLater(pool.acquire('router-1'), throwsArgumentError);
      },
    );

    test('release is a no-op and does not throw', () {
      final pool = MikrotikConnectionPool();
      expect(() => pool.release('nonexistent'), returnsNormally);
    });

    test('invalidate is a no-op for nonexistent routerId', () async {
      final pool = MikrotikConnectionPool();
      await expectLater(pool.invalidate('nonexistent'), completes);
    });

    test('closeAll is a no-op on empty pool', () async {
      final pool = MikrotikConnectionPool();
      await expectLater(pool.closeAll(), completes);
    });

    test('connectionCount stays 0 after closeAll on empty pool', () async {
      final pool = MikrotikConnectionPool();
      await pool.closeAll();
      expect(pool.connectionCount, equals(0));
    });
  });

  group('ConnectionState', () {
    test('all states are distinct', () {
      expect(
        ConnectionState.values.toSet().length,
        equals(ConnectionState.values.length),
      );
    });

    test('disconnected is the initial state value', () {
      expect(ConnectionState.disconnected.name, equals('disconnected'));
    });

    test('connected state exists', () {
      expect(ConnectionState.values, contains(ConnectionState.connected));
    });
  });

  group('MikrotikConnection state (without real socket)', () {
    test('starts in disconnected state', () {
      final conn = MikrotikConnection(
        credentials: const MikrotikCredentials(
          host: '192.168.1.1',
          username: 'admin',
          password: 'test',
        ),
      );
      expect(conn.state, equals(ConnectionState.disconnected));
      expect(conn.isConnected, isFalse);
    });

    test(
      'throws RouterosNotConnectedException on command when disconnected',
      () async {
        final conn = MikrotikConnection(
          credentials: const MikrotikCredentials(
            host: '192.168.1.1',
            username: 'admin',
            password: 'test',
          ),
        );
        await expectLater(
          conn.command('/ip/hotspot/user/print'),
          throwsA(isA<RouterosNotConnectedException>()),
        );
      },
    );

    test(
      'throws RouterosNotConnectedException on execute when disconnected',
      () async {
        final conn = MikrotikConnection(
          credentials: const MikrotikCredentials(
            host: '192.168.1.1',
            username: 'admin',
            password: 'test',
          ),
        );
        await expectLater(
          conn.execute('/system/reboot'),
          throwsA(isA<RouterosNotConnectedException>()),
        );
      },
    );

    test('disconnect on disconnected state is a no-op', () async {
      final conn = MikrotikConnection(
        credentials: const MikrotikCredentials(
          host: '192.168.1.1',
          username: 'admin',
          password: 'test',
        ),
      );
      await expectLater(conn.disconnect(), completes);
      expect(conn.state, equals(ConnectionState.disconnected));
    });

    test(
      'connect to unreachable host throws RouterosConnectionException',
      () async {
        final conn = MikrotikConnection(
          credentials: const MikrotikCredentials(
            host: '192.0.2.1', // TEST-NET-1 — guaranteed unreachable
            username: 'admin',
            password: 'test',
            port: 8728,
          ),
          retryConfig: RetryConfig(
            maxRetries: 0, // no retries in test
            baseDelay: Duration.zero,
          ),
          connectTimeout: const Duration(milliseconds: 500),
        );

        await expectLater(
          conn.connect(),
          throwsA(
            anyOf(
              isA<RouterosConnectionException>(),
              isA<RouterosTimeoutException>(),
              isA<RouterosRetryExhaustedException>(),
            ),
          ),
        );
      },
      timeout: Timeout(const Duration(seconds: 5)),
    );
  });

  group('MikrotikClient', () {
    test('isConnected is false before connect()', () {
      final client = MikrotikClient(
        host: '192.168.1.1',
        username: 'admin',
        password: 'test',
      );
      expect(client.isConnected, isFalse);
    });

    test('connectionState starts as disconnected', () {
      final client = MikrotikClient(
        host: '192.168.1.1',
        username: 'admin',
        password: 'test',
      );
      expect(client.connectionState, equals(ConnectionState.disconnected));
    });

    test('fromCredentials factory creates client', () {
      const creds = MikrotikCredentials(
        host: '10.0.0.1',
        username: 'api',
        password: 'apipass',
      );
      final client = MikrotikClient.fromCredentials(creds);
      expect(client.isConnected, isFalse);
    });
  });
}
