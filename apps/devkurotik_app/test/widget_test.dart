import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/main.dart';

void main() {
  group('DevKuroTikApp — Phase 0 smoke tests', () {
    testWidgets('app builds and shows title', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: DevKuroTikApp()));

      // Verify the app scaffolds without error.
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('placeholder home screen renders', (WidgetTester tester) async {
      await tester.pumpWidget(const ProviderScope(child: DevKuroTikApp()));
      await tester.pump();

      // Verify placeholder content is shown.
      expect(find.text('DevKuroTik'), findsWidgets);
    });

    testWidgets('ProviderScope wraps app correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: DevKuroTikApp()));

      expect(find.byType(ProviderScope), findsOneWidget);
    });
  });
}
