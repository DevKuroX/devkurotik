/// Widget tests for MultiRouterOverviewScreen — Phase 3.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/dashboard_data.dart';
import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/providers/dashboard_providers.dart';
import 'package:devkurotik_app/src/providers/router_providers.dart';
import 'package:devkurotik_app/src/ui/dashboard/multi_router_overview_screen.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

Widget _wrap(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(home: child),
  );
}

const _router1 = RouterModel(
  id: 'r1',
  name: 'CHR-V7',
  host: '54.147.121.92',
  port: 8728,
  username: 'admin',
  group: RouterGroup.testing,
);

const _router2 = RouterModel(
  id: 'r2',
  name: 'CHR-V6',
  host: '139.162.35.252',
  port: 8728,
  username: 'admin',
  group: RouterGroup.testing,
);

DashboardData _makeData(RouterModel router, String version) => DashboardData(
      routerId: router.id,
      routerName: router.name,
      routerHost: router.host,
      identity: router.name,
      version: version,
      board: 'CHR',
      cpuLoad: 5,
      totalMemory: 536870912,
      freeMemory: 268435456,
      uptime: '1d2h',
      interfaces: const [InterfaceSummary(name: 'ether1', running: true)],
      fetchedAt: DateTime(2026, 7, 26, 12),
    );

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('MultiRouterOverviewScreen — empty state', () {
    testWidgets('shows "No routers saved" when list is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MultiRouterOverviewScreen(),
          overrides: [
            routerListProvider.overrideWith(() => _EmptyRouterList()),
            multiRouterDashboardProvider.overrideWith(
              () => _EmptyMultiDashboard(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.text('No routers saved'), findsOneWidget);
    });
  });

  group('MultiRouterOverviewScreen — loading state', () {
    testWidgets('shows skeleton cards while loading', (tester) async {
      final completer = Completer<List<DashboardData>>();
      await tester.pumpWidget(
        _wrap(
          const MultiRouterOverviewScreen(),
          overrides: [
            routerListProvider.overrideWith(() => _TwoRouterList()),
            multiRouterDashboardProvider.overrideWith(
              () => _CompleterMultiDashboard(completer),
            ),
          ],
        ),
      );
      await tester.pump();

      // Should show skeleton loading cards (grey boxes).
      expect(find.byType(Card), findsWidgets);

      completer.complete([]);
      await tester.pump();
    });
  });

  group('MultiRouterOverviewScreen — data state', () {
    testWidgets('shows compact summary cards for each router', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MultiRouterOverviewScreen(),
          overrides: [
            routerListProvider.overrideWith(() => _TwoRouterList()),
            multiRouterDashboardProvider.overrideWith(
              () => _DataMultiDashboard(),
            ),
          ],
        ),
      );
      await tester.pump();

      // Both router names appear.
      expect(find.text('CHR-V7'), findsOneWidget);
      expect(find.text('CHR-V6'), findsOneWidget);

      // Compact mode chips.
      expect(find.text('CPU'), findsWidgets);

      // Refresh button.
      expect(find.byKey(const Key('multi_refresh_button')), findsOneWidget);
    });
  });

  group('MultiRouterOverviewScreen — error state', () {
    testWidgets('shows retry button on dashboard error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MultiRouterOverviewScreen(),
          overrides: [
            routerListProvider.overrideWith(() => _TwoRouterList()),
            multiRouterDashboardProvider.overrideWith(
              () => _ErrorMultiDashboard(),
            ),
          ],
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('multi_retry_button')), findsOneWidget);
      expect(find.text('Failed to load dashboard data'), findsOneWidget);
    });
  });
}

// ─── Test helper notifiers ───────────────────────────────────────────────────

class _EmptyRouterList extends RouterListNotifier {
  @override
  Future<List<RouterModel>> build() async => [];
}

class _TwoRouterList extends RouterListNotifier {
  @override
  Future<List<RouterModel>> build() async => [_router1, _router2];
}

class _EmptyMultiDashboard extends MultiRouterDashboardNotifier {
  @override
  Future<List<DashboardData>> build() async => [];
}

class _CompleterMultiDashboard extends MultiRouterDashboardNotifier {
  _CompleterMultiDashboard(this._completer);
  final Completer<List<DashboardData>> _completer;

  @override
  Future<List<DashboardData>> build() => _completer.future;
}

class _DataMultiDashboard extends MultiRouterDashboardNotifier {
  @override
  Future<List<DashboardData>> build() async => [
        _makeData(_router1, '7.15.1 (stable)'),
        _makeData(_router2, '6.49.17 (stable)'),
      ];
}

class _ErrorMultiDashboard extends MultiRouterDashboardNotifier {
  @override
  Future<List<DashboardData>> build() async {
    throw Exception('network failure');
  }
}
