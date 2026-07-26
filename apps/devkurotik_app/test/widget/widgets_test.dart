/// Widget tests for HealthStatusBadge and RouterGroupFilter.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/domain/models/router_model.dart';
import 'package:devkurotik_app/src/domain/services/router_health_service.dart';
import 'package:devkurotik_app/src/ui/router_management/widgets/health_status_badge.dart';
import 'package:devkurotik_app/src/ui/router_management/widgets/router_group_filter.dart';

void main() {
  group('HealthStatusBadge', () {
    Widget buildBadge(HealthCheckResult? result) => MaterialApp(
      home: Scaffold(body: Center(child: HealthStatusBadge(result: result))),
    );

    testWidgets('renders nothing when result is null', (tester) async {
      await tester.pumpWidget(buildBadge(null));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('shows check_circle for reachable status', (tester) async {
      final result = HealthCheckResult(
        routerId: 'r1',
        status: RouterHealthStatus.reachable,
        latencyMs: 42,
        checkedAt: DateTime.now(),
      );
      await tester.pumpWidget(buildBadge(result));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows cancel icon for unreachable status', (tester) async {
      final result = HealthCheckResult(
        routerId: 'r1',
        status: RouterHealthStatus.unreachable,
        errorMessage: 'Cannot reach',
        checkedAt: DateTime.now(),
      );
      await tester.pumpWidget(buildBadge(result));
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('shows lock icon for authFailed status', (tester) async {
      final result = HealthCheckResult(
        routerId: 'r1',
        status: RouterHealthStatus.authFailed,
        errorMessage: 'Auth failed',
        checkedAt: DateTime.now(),
      );
      await tester.pumpWidget(buildBadge(result));
      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('shows timer_off icon for timeout status', (tester) async {
      final result = HealthCheckResult(
        routerId: 'r1',
        status: RouterHealthStatus.timeout,
        errorMessage: 'Timed out',
        checkedAt: DateTime.now(),
      );
      await tester.pumpWidget(buildBadge(result));
      expect(find.byIcon(Icons.timer_off), findsOneWidget);
    });

    testWidgets('shows help_outline icon for unknown status', (tester) async {
      final result = HealthCheckResult(
        routerId: 'r1',
        status: RouterHealthStatus.unknown,
        checkedAt: DateTime.now(),
      );
      await tester.pumpWidget(buildBadge(result));
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
    });
  });

  group('RouterGroupFilter', () {
    testWidgets('renders all group chips plus All', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouterGroupFilter(
              selected: null,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // All chip must be in widget tree (may be off-screen due to scroll).
      expect(
        find.byKey(const Key('group_filter_all'), skipOffstage: false),
        findsOneWidget,
      );
      for (final g in RouterGroup.values) {
        expect(
          find.byKey(Key('group_filter_${g.name}'), skipOffstage: false),
          findsOneWidget,
        );
      }
    });

    testWidgets('"All" chip is selected when selected is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RouterGroupFilter(
              selected: null,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final allChip = tester.widget<ChoiceChip>(
        find.byKey(const Key('group_filter_all')),
      );
      expect(allChip.selected, isTrue);
    });

    testWidgets('calls onChanged with group when a chip is tapped', (
      tester,
    ) async {
      RouterGroup? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => RouterGroupFilter(
                selected: selected,
                onChanged: (g) => setState(() => selected = g),
              ),
            ),
          ),
        ),
      );

      // Use ungrouped (first item after All) which is always visible.
      await tester.tap(
        find.byKey(
          const Key('group_filter_ungrouped'),
          skipOffstage: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(selected, RouterGroup.ungrouped);
    });

    testWidgets('calls onChanged with null when All is tapped', (
      tester,
    ) async {
      RouterGroup? selected = RouterGroup.office;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => RouterGroupFilter(
                selected: selected,
                onChanged: (g) => setState(() => selected = g),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('group_filter_all')));
      await tester.pumpAndSettle();

      expect(selected, isNull);
    });
  });
}
