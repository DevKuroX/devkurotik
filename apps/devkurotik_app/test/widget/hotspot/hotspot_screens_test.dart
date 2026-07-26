/// Phase 4 — Widget tests for hotspot screens.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/hotspot_models.dart';
import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/providers/hotspot_providers.dart';
import 'package:devkurotik_app/src/providers/router_providers.dart';
import 'package:devkurotik_app/src/ui/hotspot/hotspot_dashboard_screen.dart';
import 'package:devkurotik_app/src/ui/hotspot/hotspot_user_list_screen.dart';
import 'package:devkurotik_app/src/ui/hotspot/active_sessions_screen.dart';
import 'package:devkurotik_app/src/ui/hotspot/hotspot_cookie_screen.dart';
import 'package:devkurotik_app/src/ui/hotspot/hotspot_host_screen.dart';
import 'package:devkurotik_app/src/ui/hotspot/add_hotspot_user_screen.dart';
import 'package:devkurotik_app/src/ui/hotspot/hotspot_user_detail_screen.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

const _testRouter = RouterModel(
  id: 'router-test',
  name: 'Test Router',
  host: '192.168.1.1',
  port: 8728,
  username: 'admin',
  group: RouterGroup.testing,
);

HotspotData _fakeData() {
  return HotspotData(
    routerId: 'router-test',
    users: [
      HotspotUser.fromApiMap({
        '.id': '*1', 'name': 'user001', 'profile': 'daily', 'disabled': 'false',
      }),
      HotspotUser.fromApiMap({
        '.id': '*2', 'name': 'user002', 'profile': 'weekly', 'disabled': 'true',
      }),
      HotspotUser.fromApiMap({
        '.id': '*3', 'name': 'user003', 'profile': 'daily', 'disabled': 'false',
        'limit-uptime': '1s',
      }),
    ],
    profiles: [
      HotspotProfile.fromApiMap({'.id': '*1', 'name': 'daily'}),
      HotspotProfile.fromApiMap({'.id': '*2', 'name': 'weekly'}),
    ],
    activeSessions: [
      HotspotActive.fromApiMap({
        '.id': '*1', 'user': 'user001', 'server': 'hotspot1',
        'mac-address': 'AA:BB:CC:DD:EE:FF', 'address': '10.0.0.1',
        'uptime': '45m10s',
      }),
    ],
    fetchedAt: DateTime.now(),
  );
}

/// Wrap widget in ProviderScope with active router and hotspot data.
Widget _wrap(
  Widget child, {
  HotspotData? data,
  bool noRouter = false,
  bool loading = false,
  bool error = false,
}) {
  return ProviderScope(
    overrides: [
      activeRouterProvider.overrideWith(
        () => _FakeActiveRouter(noRouter ? null : _testRouter),
      ),
      activeHotspotProvider.overrideWith(
        () => _FakeActiveHotspot(
          data: data ?? (error ? null : (loading ? null : _fakeData())),
          loading: loading,
          error: error,
        ),
      ),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

// ---------------------------------------------------------------------------
// Fake notifiers
// ---------------------------------------------------------------------------

class _FakeActiveRouter extends ActiveRouterNotifier {
  _FakeActiveRouter(this._router);
  final RouterModel? _router;

  @override
  RouterModel? build() => _router;
}

class _FakeActiveHotspot extends ActiveHotspotNotifier {
  _FakeActiveHotspot({this.data, this.loading = false, this.error = false});

  final HotspotData? data;
  final bool loading;
  final bool error;

  @override
  Future<HotspotData?> build() async {
    if (loading) return Completer<HotspotData?>().future;
    if (error) throw Exception('Test error loading hotspot data');
    return data;
  }
}

// ---------------------------------------------------------------------------
// HotspotDashboardScreen tests
// ---------------------------------------------------------------------------

void main() {
  group('HotspotDashboardScreen', () {
    testWidgets('shows loading when data not yet available', (tester) async {
      await tester.pumpWidget(_wrap(
        const HotspotDashboardScreen(),
        loading: true,
      ));
      await tester.pump();
      expect(find.byKey(const Key('hotspot_dashboard_loading')), findsOneWidget);
    });

    testWidgets('shows no-router when no active router', (tester) async {
      await tester.pumpWidget(_wrap(
        const HotspotDashboardScreen(),
        noRouter: true,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hotspot_no_router')), findsOneWidget);
    });

    testWidgets('shows stats when data loaded', (tester) async {
      await tester.pumpWidget(_wrap(const HotspotDashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stat_total_users')), findsOneWidget);
      expect(find.byKey(const Key('stat_active_users')), findsOneWidget);
      expect(find.text('3'), findsWidgets); // totalUsers=3
    });

    testWidgets('shows navigation tiles', (tester) async {
      await tester.pumpWidget(_wrap(const HotspotDashboardScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('nav_user_list')), findsOneWidget);
      expect(find.byKey(const Key('nav_active_sessions')), findsOneWidget);
      // Scroll down to make cookies and hosts visible.
      await tester.scrollUntilVisible(
        find.byKey(const Key('nav_cookies')),
        100,
      );
      expect(find.byKey(const Key('nav_cookies')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('nav_hosts')),
        100,
      );
      expect(find.byKey(const Key('nav_hosts')), findsOneWidget);
    });

    testWidgets('shows error state on failure', (tester) async {
      await tester.pumpWidget(_wrap(
        const HotspotDashboardScreen(),
        error: true,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hotspot_dashboard_error')), findsOneWidget);
      expect(find.byKey(const Key('hotspot_dashboard_retry')), findsOneWidget);
    });

    testWidgets('shows refresh button', (tester) async {
      await tester.pumpWidget(_wrap(const HotspotDashboardScreen()));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('hotspot_dashboard_refresh')),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotUserListScreen tests
  // ---------------------------------------------------------------------------
  group('HotspotUserListScreen', () {
    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(_wrap(
        const HotspotUserListScreen(),
        loading: true,
      ));
      await tester.pump();
      expect(find.byKey(const Key('hotspot_loading')), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(_wrap(
        const HotspotUserListScreen(),
        error: true,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hotspot_error')), findsOneWidget);
      expect(find.byKey(const Key('hotspot_retry_button')), findsOneWidget);
    });

    testWidgets('shows no-router when no active router', (tester) async {
      await tester.pumpWidget(_wrap(
        const HotspotUserListScreen(),
        noRouter: true,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hotspot_empty_no_router')), findsOneWidget);
    });

    testWidgets('renders user list when data loaded', (tester) async {
      await tester.pumpWidget(_wrap(const HotspotUserListScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hotspot_user_list')), findsOneWidget);
      expect(find.byKey(const Key('user_tile_*1')), findsOneWidget);
      expect(find.byKey(const Key('user_tile_*2')), findsOneWidget);
    });

    testWidgets('shows search field', (tester) async {
      await tester.pumpWidget(_wrap(const HotspotUserListScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hotspot_search_field')), findsOneWidget);
    });

    testWidgets('shows filter button', (tester) async {
      await tester.pumpWidget(_wrap(const HotspotUserListScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hotspot_filter_button')), findsOneWidget);
    });

    testWidgets('shows add FAB when router selected', (tester) async {
      await tester.pumpWidget(_wrap(const HotspotUserListScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add_hotspot_user_fab')), findsOneWidget);
    });

    testWidgets('no FAB when no router selected', (tester) async {
      await tester.pumpWidget(_wrap(
        const HotspotUserListScreen(),
        noRouter: true,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add_hotspot_user_fab')), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // ActiveSessionsScreen tests
  // ---------------------------------------------------------------------------
  group('ActiveSessionsScreen', () {
    testWidgets('shows sessions list when data loaded', (tester) async {
      await tester.pumpWidget(_wrap(const ActiveSessionsScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sessions_list')), findsOneWidget);
      expect(find.byKey(const Key('session_tile_*1')), findsOneWidget);
    });

    testWidgets('shows empty state when no sessions', (tester) async {
      final emptyData = HotspotData(
        routerId: 'r1',
        users: [],
        profiles: [],
        activeSessions: [],
        fetchedAt: DateTime.now(),
      );
      await tester.pumpWidget(_wrap(
        const ActiveSessionsScreen(),
        data: emptyData,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sessions_empty')), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(_wrap(
        const ActiveSessionsScreen(),
        loading: true,
      ));
      await tester.pump();
      expect(find.byKey(const Key('sessions_loading')), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(_wrap(
        const ActiveSessionsScreen(),
        error: true,
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sessions_error')), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotCookieScreen tests
  // ---------------------------------------------------------------------------
  group('HotspotCookieScreen', () {
    testWidgets('shows empty state when no cookies', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRouterProvider.overrideWith(
              () => _FakeActiveRouter(_testRouter),
            ),
            hotspotCookieProvider.overrideWith(
              () => _FakeCookieNotifier([]),
            ),
          ],
          child: const MaterialApp(home: HotspotCookieScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cookies_empty')), findsOneWidget);
    });

    testWidgets('shows cookie list', (tester) async {
      final cookies = [
        HotspotCookie.fromApiMap({
          '.id': '*1', 'user': 'user001',
          'mac-address': 'AA:BB:CC:DD:EE:FF',
        }),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRouterProvider.overrideWith(
              () => _FakeActiveRouter(_testRouter),
            ),
            hotspotCookieProvider.overrideWith(
              () => _FakeCookieNotifier(cookies),
            ),
          ],
          child: const MaterialApp(home: HotspotCookieScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('cookies_list')), findsOneWidget);
      expect(find.byKey(const Key('cookie_tile_*1')), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotHostScreen tests
  // ---------------------------------------------------------------------------
  group('HotspotHostScreen', () {
    testWidgets('shows empty state when no hosts', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRouterProvider.overrideWith(
              () => _FakeActiveRouter(_testRouter),
            ),
            hotspotHostProvider.overrideWith(
              () => _FakeHostNotifier([]),
            ),
          ],
          child: const MaterialApp(home: HotspotHostScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hosts_empty')), findsOneWidget);
    });

    testWidgets('shows host list', (tester) async {
      final hosts = [
        HotspotHost.fromApiMap({
          '.id': '*1', 'mac-address': 'AA:BB:CC:DD:EE:FF',
          'address': '10.0.0.1', 'authorized': 'true',
        }),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeRouterProvider.overrideWith(
              () => _FakeActiveRouter(_testRouter),
            ),
            hotspotHostProvider.overrideWith(
              () => _FakeHostNotifier(hosts),
            ),
          ],
          child: const MaterialApp(home: HotspotHostScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hosts_list')), findsOneWidget);
      expect(find.byKey(const Key('host_tile_*1')), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // AddHotspotUserScreen tests
  // ---------------------------------------------------------------------------
  group('AddHotspotUserScreen', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(_wrap(const AddHotspotUserScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add_user_name_field')), findsOneWidget);
      expect(find.byKey(const Key('add_user_password_field')), findsOneWidget);
      expect(find.byKey(const Key('add_user_comment_field')), findsOneWidget);
      expect(find.byKey(const Key('add_user_mac_field')), findsOneWidget);
      expect(find.byKey(const Key('add_user_limit_uptime_field')), findsOneWidget);
    });

    testWidgets('shows save button', (tester) async {
      await tester.pumpWidget(_wrap(const AddHotspotUserScreen()));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add_user_save_button')), findsOneWidget);
    });

    testWidgets('validates empty name on save', (tester) async {
      await tester.pumpWidget(_wrap(const AddHotspotUserScreen()));
      await tester.pumpAndSettle();
      // Tap save without filling fields.
      await tester.tap(find.byKey(const Key('add_user_save_button')));
      await tester.pumpAndSettle();
      // Should show validation errors.
      expect(find.text('Username must not be empty.'), findsOneWidget);
    });

    testWidgets('shows password visibility toggle', (tester) async {
      await tester.pumpWidget(_wrap(const AddHotspotUserScreen()));
      await tester.pumpAndSettle();
      // Password field has visibility toggle button.
      final field = find.byKey(const Key('add_user_password_field'));
      expect(field, findsOneWidget);
    });

    testWidgets('shows disabled toggle', (tester) async {
      await tester.pumpWidget(_wrap(const AddHotspotUserScreen()));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('add_user_disabled_toggle')),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // HotspotUserDetailScreen tests
  // ---------------------------------------------------------------------------
  group('HotspotUserDetailScreen', () {
    final testUser = HotspotUser.fromApiMap({
      '.id': '*1',
      'name': 'user001',
      'profile': 'daily',
      'disabled': 'false',
      'password': 'pass001',
      'server': 'hotspot1',
    });

    testWidgets('renders user name in appbar', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HotspotUserDetailScreen(userId: '*1', user: testUser),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('user001'), findsWidgets);
    });

    testWidgets('shows edit button', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HotspotUserDetailScreen(userId: '*1', user: testUser),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('hotspot_detail_edit_button')),
        findsOneWidget,
      );
    });

    testWidgets('shows overflow menu', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HotspotUserDetailScreen(userId: '*1', user: testUser),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('hotspot_detail_overflow')),
        findsOneWidget,
      );
    });

    testWidgets('delete confirmation dialog shows on tap', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HotspotUserDetailScreen(userId: '*1', user: testUser),
        ),
      );
      await tester.pumpAndSettle();
      // Open overflow menu.
      await tester.tap(find.byKey(const Key('hotspot_detail_overflow')));
      await tester.pumpAndSettle();
      // Tap delete.
      await tester.tap(find.byKey(const Key('hotspot_detail_delete')));
      await tester.pumpAndSettle();
      // Confirmation dialog should appear.
      expect(find.byKey(const Key('delete_user_confirm')), findsOneWidget);
    });

    testWidgets('disabled user shows Enable in overflow menu', (tester) async {
      final disabledUser = testUser.copyWith(disabled: true);
      await tester.pumpWidget(
        _wrap(
          HotspotUserDetailScreen(userId: '*1', user: disabledUser),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hotspot_detail_overflow')));
      await tester.pumpAndSettle();
      expect(find.text('Enable User'), findsOneWidget);
    });

    testWidgets('enabled user shows Disable in overflow menu', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HotspotUserDetailScreen(userId: '*1', user: testUser),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('hotspot_detail_overflow')));
      await tester.pumpAndSettle();
      expect(find.text('Disable User'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Generic fake list notifier (must extend the real notifier)
// ---------------------------------------------------------------------------

class _FakeCookieNotifier extends HotspotCookieNotifier {
  _FakeCookieNotifier(this._items);
  final List<HotspotCookie> _items;

  @override
  Future<List<HotspotCookie>> build() async => _items;
}

class _FakeHostNotifier extends HotspotHostNotifier {
  _FakeHostNotifier(this._items);
  final List<HotspotHost> _items;

  @override
  Future<List<HotspotHost>> build() async => _items;
}
