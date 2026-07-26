/// Widget tests for DashboardScreen — Phase 3.
///
/// Covers: loading state, error state, empty state (no active router),
/// data state (with RouterSummaryCard), pull-to-refresh, cached state.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/dashboard_data.dart';
import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/providers/dashboard_providers.dart';
import 'package:devkurotik_app/src/providers/router_providers.dart';
import 'package:devkurotik_app/src/ui/dashboard/dashboard_screen.dart';
import 'package:devkurotik_app/src/ui/dashboard/widgets/router_summary_card.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

const _testRouter = RouterModel(
  id: 'router-test',
  name: 'Test Router',
  host: '192.168.88.1',
  port: 8728,
  username: 'admin',
  group: RouterGroup.testing,
);

DashboardData _makeDashboardData({
  DashboardDataSource source = DashboardDataSource.live,
}) {
  return DashboardData(
    routerId: 'router-test',
    routerName: 'Test Router',
    routerHost: '192.168.88.1',
    identity: 'test-identity',
    version: '7.15.1 (stable)',
    board: 'CHR Amazon EC2 t3.small',
    cpuLoad: 12,
    totalMemory: 536870912, // 512 MB
    freeMemory: 268435456, // 256 MB
    uptime: '4d12h30m',
    interfaces: const [
      InterfaceSummary(name: 'ether1', running: true),
      InterfaceSummary(name: 'ether2', running: false),
    ],
    fetchedAt: DateTime(2026, 7, 26, 12),
    source: source,
  );
}

/// Wraps widget in MaterialApp + ProviderScope with necessary overrides.
Widget _wrap(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  // ── Empty state: no active router ─────────────────────────────────────────

  group('DashboardScreen — empty state (no active router)', () {
    testWidgets('shows "No router selected" message', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          overrides: [
            activeRouterProvider.overrideWith(() {
              final n = ActiveRouterNotifier();
              return n;
            }),
          ],
        ),
      );

      expect(find.text('No router selected'), findsOneWidget);
      expect(find.byKey(const Key('go_to_routers_button')), findsOneWidget);
    });
  });

  // ── Loading state ─────────────────────────────────────────────────────────

  group('DashboardScreen — loading state', () {
    testWidgets('shows CircularProgressIndicator while loading', (tester) async {
      // completer never completes within this test — safe (no pending timer).
      final completer = Completer<DashboardData>();

      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          overrides: [
            activeRouterProvider.overrideWith(() => _FixedActiveRouter()),
            // Override the whole family to use completer.
            dashboardProvider.overrideWith(
              () => _CompleterDashboardNotifier(completer),
            ),
          ],
        ),
      );

      // First pump starts the async build; state is AsyncLoading.
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Connecting to router…'), findsOneWidget);

      // Complete completer so resources are released before test ends.
      completer.complete(_makeDashboardData());
      await tester.pump();
    });
  });

  // ── Error state ───────────────────────────────────────────────────────────

  group('DashboardScreen — error state', () {
    testWidgets('shows error message and retry button', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          overrides: [
            activeRouterProvider.overrideWith(() => _FixedActiveRouter()),
            dashboardProvider.overrideWith(() => _ErrorDashboardNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Unable to reach router'), findsOneWidget);
      expect(find.byKey(const Key('dashboard_retry_button')), findsOneWidget);
    });
  });

  // ── Data state ─────────────────────────────────────────────────────────────

  group('DashboardScreen — data state', () {
    testWidgets('shows RouterSummaryCard with live data', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          overrides: [
            activeRouterProvider.overrideWith(() => _FixedActiveRouter()),
            dashboardProvider.overrideWith(() => _DataDashboardNotifier()),
          ],
        ),
      );
      await tester.pump();

      // Card is displayed.
      expect(
        find.byKey(const Key('summary_card_router-test')),
        findsOneWidget,
      );

      // Router name visible somewhere in UI.
      expect(find.text('Test Router'), findsWidgets);

      // ONLINE badge.
      expect(find.text('ONLINE'), findsOneWidget);

      // RouterOS version.
      expect(find.text('7.15.1'), findsOneWidget);

      // Refresh button.
      expect(
        find.byKey(const Key('dashboard_refresh_button')),
        findsOneWidget,
      );
    });

    testWidgets('shows interface list section', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          overrides: [
            activeRouterProvider.overrideWith(() => _FixedActiveRouter()),
            dashboardProvider.overrideWith(() => _DataDashboardNotifier()),
          ],
        ),
      );
      await tester.pump();

      // Interface names visible.
      expect(find.text('ether1'), findsOneWidget);
    });

    testWidgets('shows cached banner when data is cached', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const DashboardScreen(),
          overrides: [
            activeRouterProvider.overrideWith(() => _FixedActiveRouter()),
            dashboardProvider.overrideWith(() => _CachedDashboardNotifier()),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('Showing cached data'), findsOneWidget);
    });
  });

  // ── RouterSummaryCard direct tests ────────────────────────────────────────

  group('RouterSummaryCard widget', () {
    testWidgets('renders full mode by default', (tester) async {
      final data = _makeDashboardData();
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: ListView(
              children: [RouterSummaryCard(data: data)],
            ),
          ),
        ),
      );

      expect(find.text('ONLINE'), findsOneWidget);
      // CPU row.
      expect(find.textContaining('CPU'), findsOneWidget);
    });

    testWidgets('renders compact mode', (tester) async {
      final data = _makeDashboardData();
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: RouterSummaryCard(data: data, compact: true),
          ),
        ),
      );

      // Compact mode shows chip-style labels.
      expect(find.text('CPU'), findsOneWidget);
      expect(find.text('MEM'), findsOneWidget);
      expect(find.text('UP'), findsOneWidget);
    });
  });
}

// ─── Test helper notifiers ───────────────────────────────────────────────────

class _FixedActiveRouter extends ActiveRouterNotifier {
  @override
  RouterModel? build() => _testRouter;
}

class _CompleterDashboardNotifier extends DashboardNotifier {
  _CompleterDashboardNotifier(this._completer);
  final Completer<DashboardData> _completer;

  @override
  Future<DashboardData> build(String arg) => _completer.future;
}

class _ErrorDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardData> build(String arg) async {
    throw Exception('Cannot reach router: connection refused');
  }
}

class _DataDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardData> build(String arg) async => _makeDashboardData();
}

class _CachedDashboardNotifier extends DashboardNotifier {
  @override
  Future<DashboardData> build(String arg) async =>
      _makeDashboardData(source: DashboardDataSource.cached);
}
