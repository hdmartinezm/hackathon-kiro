import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/widgets/error_dialog_widget.dart';

void main() {
  group('showNetworkErrorDialog', () {
    testWidgets('shows dialog with error message and buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _DialogLauncher())),
      );

      // Tap the button to trigger the dialog
      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify dialog content
      expect(find.text('Error de conexión'), findsOneWidget);
      expect(find.text('Exception: Test error'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('returns false when Cancelar is tapped',
        (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showNetworkErrorDialog(
                    context: context,
                    error: Exception('Test error'),
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isFalse);
    });

    testWidgets('returns true when Reintentar is tapped',
        (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showNetworkErrorDialog(
                    context: context,
                    error: Exception('Test error'),
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });
  });
}

/// Helper widget to launch the dialog in tests.
class _DialogLauncher extends StatelessWidget {
  const _DialogLauncher();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        showNetworkErrorDialog(
          context: context,
          error: Exception('Test error'),
        );
      },
      child: const Text('Show Error'),
    );
  }
}
