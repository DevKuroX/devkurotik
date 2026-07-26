/// Phase 7 — Widget tests for PPP screens.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/ppp_models.dart';
import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/providers/ppp_providers.dart';
import 'package:devkurotik_app/src/providers/router_providers.dart';
import 'package:devkurotik_app/src/ui/ppp/ppp_dashboard_screen.dart';
import 'package:devkurotik_app/src/ui/ppp/ppp_secret_list_screen.dart';
import 'package:devkurotik_app/src/ui/ppp/add_ppp_secret_screen.dart';
import 'package:devkurotik_app/src/ui/ppp/ppp_active_sessions_screen.dart';
import 'package:devkurotik_app/src/ui/ppp/ppp_profiles_screen.dart';

// ---------------------------------------------------------------------------
// Test data
// ---------------------------------------------------------------------------

const _testRouter = RouterModel(
  id: 'router-test',
  name: 'Test Router',
  host: '192.168.1.1',
  port: 8728,
  username: 'admin',
  group: RouterGroup.testing,
);

PppData _fakeData() {
  return PppData(
    routerId: 'router-test',
    secrets: [
      PppSecret.fromApiMap({
        '.id': '*1', 'name': 'user001', 'service': 'pppoe',
        'profile': 'default', 'disabled': 'false',
      }),
      PppSecret.fromApiMap({
        '.id': '*2', 'name': 'user002', 'service': 'l2tp',
        'profile': 'admin', 'disabled': 'true',
      }),
    ],
    profiles: [
      PppProfile.fromApiMap({'.id': '*1', 'name': 'default', 'rate-limit': '10M/10M'}),
    ],
    activeSessions: [
      PppActive.fromApiMap({
        '.id': '*1', 'name': 'user001',
        'service': 'pppoe', 'address': '10.0.0.1',
        'uptime': '2h',
      }),
    ],
    fetchedAt: DateTime(2026),
  );
}

Widget _wrap(
  Widget child, {
  PppData? data,
  bool noRouter = false,
  bool loading = false,
  bool error = false,
}) {
  return ProviderScope(
    overrides: [
      activeRouterProvider.overrideWith(
        () => _FakeActiveRouter(noRouter ? null : _testRouter),
      ),
      activePppProvider.overrideWith(
        () => _FakePppNotifier(
          loading: loading,
          error: error,
          data: data ?? _fakeData(),
        ),
      ),
    ],
    child: MaterialApp(home: child),
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

class _FakePppNotifier extends ActivePppNotifier {
  _FakePppNotifier({
    required this.data,
    this.loading = false,
    this.error = false,
  });

  final PppData data;
  final bool loading;
  final bool error;

  @override
  Future<PppData?> build() async {
    if (loading) return Completer<PppData?>().future;
    if (error) throw Exception('Connection refused');
    return data;
  }
}

// ---------------------------------------------------------------------------
// PppDashboardScreen tests
// ---------------------------------------------------------------------------

void main() {
group('PppDashboardScreen', () {
  testWidgets('shows loading indicator while loading', (tester) async {
    await tester.pumpWidget(_wrap(const PppDashboardScreen(), loading: true));
    expect(find.byKey(const Key('ppp_dashboard_loading')), findsOneWidget);
  });

  testWidgets('shows error state and retry button on failure', (tester) async {
    await tester.pumpWidget(_wrap(const PppDashboardScreen(), error: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ppp_dashboard_error')), findsOneWidget);
    expect(find.byKey(const Key('ppp_dashboard_retry')), findsOneWidget);
  });

  testWidgets('shows dashboard cards with data', (tester) async {
    await tester.pumpWidget(_wrap(const PppDashboardScreen()));
    await tester.pump();
    expect(find.byKey(const Key('ppp_secrets_card')), findsOneWidget);
    expect(find.byKey(const Key('ppp_sessions_card')), findsOneWidget);
    expect(find.byKey(const Key('ppp_profiles_card')), findsOneWidget);
  });

  testWidgets('shows correct counts in dashboard', (tester) async {
    await tester.pumpWidget(_wrap(const PppDashboardScreen()));
    await tester.pump();
    expect(find.text('2 users'), findsOneWidget);
    expect(find.text('1 session'), findsOneWidget);
    expect(find.text('1 profile'), findsOneWidget);
  });

  testWidgets('shows empty dashboard when no data', (tester) async {
    final emptyData = PppData(
      routerId: 'r1', secrets: [], profiles: [], activeSessions: [],
      fetchedAt: DateTime(2026),
    );
    await tester.pumpWidget(_wrap(const PppDashboardScreen(), data: emptyData));
    await tester.pump();
    expect(find.text('0 users'), findsOneWidget);
  });
});

// ---------------------------------------------------------------------------
// PppSecretListScreen tests
// ---------------------------------------------------------------------------

group('PppSecretListScreen', () {
  testWidgets('shows loading indicator while loading', (tester) async {
    await tester.pumpWidget(_wrap(const PppSecretListScreen(), loading: true));
    expect(find.byKey(const Key('ppp_secrets_loading')), findsOneWidget);
  });

  testWidgets('shows error state on failure', (tester) async {
    await tester.pumpWidget(_wrap(const PppSecretListScreen(), error: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ppp_secrets_error')), findsOneWidget);
    expect(find.byKey(const Key('ppp_secrets_retry')), findsOneWidget);
  });

  testWidgets('shows secret list with data', (tester) async {
    await tester.pumpWidget(_wrap(const PppSecretListScreen()));
    await tester.pump();
    expect(find.byKey(const Key('ppp_secrets_list')), findsOneWidget);
    expect(find.byKey(const Key('secret_tile_*1')), findsOneWidget);
    expect(find.byKey(const Key('secret_tile_*2')), findsOneWidget);
  });

  testWidgets('shows empty state when no secrets', (tester) async {
    final emptyData = PppData(
      routerId: 'r1', secrets: [], profiles: [], activeSessions: [],
      fetchedAt: DateTime(2026),
    );
    await tester.pumpWidget(_wrap(const PppSecretListScreen(), data: emptyData));
    await tester.pump();
    expect(find.byKey(const Key('ppp_secrets_empty')), findsOneWidget);
  });

  testWidgets('search field is present', (tester) async {
    await tester.pumpWidget(_wrap(const PppSecretListScreen()));
    await tester.pump();
    expect(find.byKey(const Key('ppp_search_field')), findsOneWidget);
  });

  testWidgets('FAB for adding secret is present', (tester) async {
    await tester.pumpWidget(_wrap(const PppSecretListScreen()));
    await tester.pump();
    expect(find.byKey(const Key('ppp_add_secret_fab')), findsOneWidget);
  });

  testWidgets('filter menu button is present', (tester) async {
    await tester.pumpWidget(_wrap(const PppSecretListScreen()));
    await tester.pump();
    expect(find.byKey(const Key('ppp_service_filter_menu')), findsOneWidget);
  });
});

// ---------------------------------------------------------------------------
// AddPppSecretScreen tests
// ---------------------------------------------------------------------------

group('AddPppSecretScreen', () {
  testWidgets('shows all form fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddPppSecretScreen())),
    );
    expect(find.byKey(const Key('ppp_name_field')), findsOneWidget);
    expect(find.byKey(const Key('ppp_password_field')), findsOneWidget);
    expect(find.byKey(const Key('ppp_service_field')), findsOneWidget);
    expect(find.byKey(const Key('ppp_profile_field')), findsOneWidget);
    // Optional fields may need scrolling — check existence in widget tree
    expect(
      find.byKey(const Key('ppp_local_address_field'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ppp_remote_address_field'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ppp_caller_id_field'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ppp_comment_field'), skipOffstage: false),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('ppp_disabled_switch'), skipOffstage: false),
      findsOneWidget,
    );
  });

  testWidgets('save button is present in app bar', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddPppSecretScreen())),
    );
    expect(find.byKey(const Key('ppp_add_save_button')), findsOneWidget);
  });

  testWidgets('validation fails for empty required fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddPppSecretScreen())),
    );
    // Clear profile field (has default 'default')
    await tester.enterText(find.byKey(const Key('ppp_profile_field')), '');
    // Tap Save
    await tester.tap(find.byKey(const Key('ppp_add_save_button')));
    await tester.pump();
    // Should show validation errors
    expect(find.text('Username must not be empty.'), findsOneWidget);
    expect(find.text('Password must not be empty.'), findsOneWidget);
    expect(find.text('Profile must not be empty.'), findsOneWidget);
  });

  testWidgets('password toggle button toggles visibility', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: AddPppSecretScreen())),
    );
    // Initially obscured (visibility_off icon)
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
});

// ---------------------------------------------------------------------------
// PppActiveSessionsScreen tests
// ---------------------------------------------------------------------------

group('PppActiveSessionsScreen', () {
  testWidgets('shows loading indicator while loading', (tester) async {
    await tester.pumpWidget(
        _wrap(const PppActiveSessionsScreen(), loading: true));
    expect(find.byKey(const Key('ppp_sessions_loading')), findsOneWidget);
  });

  testWidgets('shows error state on failure', (tester) async {
    await tester.pumpWidget(
        _wrap(const PppActiveSessionsScreen(), error: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ppp_sessions_error')), findsOneWidget);
  });

  testWidgets('shows active sessions list', (tester) async {
    await tester.pumpWidget(_wrap(const PppActiveSessionsScreen()));
    await tester.pump();
    expect(find.byKey(const Key('ppp_sessions_list')), findsOneWidget);
    expect(find.byKey(const Key('ppp_session_tile_*1')), findsOneWidget);
  });

  testWidgets('shows empty state when no sessions', (tester) async {
    final emptyData = PppData(
      routerId: 'r1', secrets: [], profiles: [], activeSessions: [],
      fetchedAt: DateTime(2026),
    );
    await tester.pumpWidget(
        _wrap(const PppActiveSessionsScreen(), data: emptyData));
    await tester.pump();
    expect(find.byKey(const Key('ppp_sessions_empty')), findsOneWidget);
  });

  testWidgets('disconnect button is present for each session', (tester) async {
    await tester.pumpWidget(_wrap(const PppActiveSessionsScreen()));
    await tester.pump();
    expect(find.byKey(const Key('ppp_disconnect_*1')), findsOneWidget);
  });

  testWidgets('disconnect shows confirmation dialog', (tester) async {
    await tester.pumpWidget(_wrap(const PppActiveSessionsScreen()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ppp_disconnect_*1')));
    await tester.pump();
    expect(find.text('Disconnect PPP Session'), findsOneWidget);
    expect(find.byKey(const Key('ppp_disconnect_confirm')), findsOneWidget);
  });
});

// ---------------------------------------------------------------------------
// PppProfilesScreen tests
// ---------------------------------------------------------------------------

group('PppProfilesScreen', () {
  testWidgets('shows loading indicator while loading', (tester) async {
    await tester.pumpWidget(_wrap(const PppProfilesScreen(), loading: true));
    expect(find.byKey(const Key('ppp_profiles_loading')), findsOneWidget);
  });

  testWidgets('shows profiles list', (tester) async {
    await tester.pumpWidget(_wrap(const PppProfilesScreen()));
    await tester.pump();
    expect(find.byKey(const Key('ppp_profiles_list')), findsOneWidget);
    expect(find.byKey(const Key('ppp_profile_tile_*1')), findsOneWidget);
  });

  testWidgets('shows empty state when no profiles', (tester) async {
    final emptyData = PppData(
      routerId: 'r1', secrets: [], profiles: [], activeSessions: [],
      fetchedAt: DateTime(2026),
    );
    await tester.pumpWidget(_wrap(const PppProfilesScreen(), data: emptyData));
    await tester.pump();
    expect(find.byKey(const Key('ppp_profiles_empty')), findsOneWidget);
  });
});
}
