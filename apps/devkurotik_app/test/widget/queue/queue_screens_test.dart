/// Phase 7 — Widget tests for Queue screens.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/queue_models.dart';
import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/providers/queue_providers.dart';
import 'package:devkurotik_app/src/providers/router_providers.dart';
import 'package:devkurotik_app/src/ui/queue/simple_queue_screen.dart';

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

List<SimpleQueue> _fakeQueues() => [
      SimpleQueue.fromApiMap({
        '.id': '*1', 'name': 'daily-users', 'target': '192.168.1.0/24',
        'max-limit': '2M/10M', 'disabled': 'false',
      }),
      SimpleQueue.fromApiMap({
        '.id': '*2', 'name': 'paused-queue', 'disabled': 'true',
      }),
      SimpleQueue.fromApiMap({
        '.id': '*3', 'name': 'premium-users', 'max-limit': '10M/50M',
        'disabled': 'false', 'comment': 'premium tier',
      }),
    ];

Widget _wrap(
  Widget child, {
  List<SimpleQueue>? queues,
  bool noRouter = false,
  bool loading = false,
  bool error = false,
}) {
  return ProviderScope(
    overrides: [
      activeRouterProvider.overrideWith(
        () => _FakeActiveRouter(noRouter ? null : _testRouter),
      ),
      activeSimpleQueueProvider.overrideWith(
        () => _FakeQueueNotifier(
          loading: loading,
          error: error,
          queues: queues ?? _fakeQueues(),
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

class _FakeQueueNotifier extends ActiveSimpleQueueNotifier {
  _FakeQueueNotifier({
    required this.queues,
    this.loading = false,
    this.error = false,
  });

  final List<SimpleQueue> queues;
  final bool loading;
  final bool error;

  @override
  Future<List<SimpleQueue>> build() async {
    if (loading) return Completer<List<SimpleQueue>>().future;
    if (error) throw Exception('Connection refused');
    return queues;
  }
}

// ---------------------------------------------------------------------------
// SimpleQueueScreen tests
// ---------------------------------------------------------------------------

void main() {
group('SimpleQueueScreen', () {
  testWidgets('shows loading indicator while loading', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen(), loading: true));
    expect(find.byKey(const Key('queue_loading')), findsOneWidget);
  });

  testWidgets('shows error state on failure', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen(), error: true));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('queue_error')), findsOneWidget);
    expect(find.byKey(const Key('queue_retry')), findsOneWidget);
  });

  testWidgets('shows queue list with data', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen()));
    await tester.pump();
    expect(find.byKey(const Key('queue_list')), findsOneWidget);
    expect(find.byKey(const Key('queue_tile_*1')), findsOneWidget);
    expect(find.byKey(const Key('queue_tile_*2')), findsOneWidget);
    expect(find.byKey(const Key('queue_tile_*3')), findsOneWidget);
  });

  testWidgets('shows empty state when no queues', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen(), queues: []));
    await tester.pump();
    expect(find.byKey(const Key('queue_empty')), findsOneWidget);
  });

  testWidgets('search field is present', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen()));
    await tester.pump();
    expect(find.byKey(const Key('queue_search_field')), findsOneWidget);
  });

  testWidgets('filter menu is present', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen()));
    await tester.pump();
    expect(find.byKey(const Key('queue_filter_menu')), findsOneWidget);
  });

  testWidgets('refresh button is present in appbar', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen()));
    await tester.pump();
    expect(find.byKey(const Key('queue_refresh')), findsOneWidget);
  });

  testWidgets('queue name is displayed in list', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen()));
    await tester.pump();
    expect(find.text('daily-users'), findsOneWidget);
    expect(find.text('paused-queue'), findsOneWidget);
    expect(find.text('premium-users'), findsOneWidget);
  });

  testWidgets('queue menu button present for each queue', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen()));
    await tester.pump();
    expect(find.byKey(const Key('queue_menu_*1')), findsOneWidget);
    expect(find.byKey(const Key('queue_menu_*2')), findsOneWidget);
  });

  testWidgets('delete shows confirmation dialog', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen()));
    await tester.pump();
    await tester.tap(find.byKey(const Key('queue_menu_*1')));
    await tester.pumpAndSettle();
    // After menu opens, tap Delete
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Delete Queue'), findsOneWidget);
    expect(find.byKey(const Key('queue_delete_confirm')), findsOneWidget);
  });

  testWidgets('shows empty message when search has no results', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleQueueScreen()));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('queue_search_field')),
      'zzznomatch',
    );
    await tester.pump();
    expect(find.byKey(const Key('queue_empty')), findsOneWidget);
    expect(find.text('No queues match the filter.'), findsOneWidget);
  });
});
}
