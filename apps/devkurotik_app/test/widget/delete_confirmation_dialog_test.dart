/// Widget tests for DeleteConfirmationDialog.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:devkurotik_app/src/ui/router_management/delete_confirmation_dialog.dart';

Widget _buildDialog(String routerName) {
  return MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<bool>(
            context: context,
            builder: (_) => DeleteConfirmationDialog(routerName: routerName),
          ),
          child: const Text('Open'),
        ),
      ),
    ),
  );
}

void main() {
  group('DeleteConfirmationDialog', () {
    testWidgets('displays router name in message', (tester) async {
      await tester.pumpWidget(_buildDialog('My Router'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('"My Router"', findRichText: true), findsNothing);
      expect(find.textContaining('My Router'), findsOneWidget);
    });

    testWidgets('shows Cancel and Delete buttons', (tester) async {
      await tester.pumpWidget(_buildDialog('Test'));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('delete_cancel_btn')), findsOneWidget);
      expect(find.byKey(const Key('delete_confirm_btn')), findsOneWidget);
    });

    testWidgets('Cancel returns false', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        const DeleteConfirmationDialog(routerName: 'R'),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_cancel_btn')));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('Confirm returns true', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await showDialog<bool>(
                    context: context,
                    builder: (_) =>
                        const DeleteConfirmationDialog(routerName: 'R'),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('delete_confirm_btn')));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}
