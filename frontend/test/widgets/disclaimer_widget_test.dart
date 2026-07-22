import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/widgets/disclaimer_widget.dart';

void main() {
  group('DisclaimerWidget', () {
    testWidgets('renders full disclaimer with title and long text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DisclaimerWidget())),
      );

      expect(find.text('Aviso importante'), findsOneWidget);
      expect(
        find.textContaining('NO reemplaza la evaluación de un profesional'),
        findsOneWidget,
      );
      expect(find.textContaining('Al aceptar, usted reconoce'), findsOneWidget);
    });

    testWidgets('renders compact disclaimer without title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: DisclaimerWidget(compact: true)),
        ),
      );

      expect(find.text('Aviso importante'), findsNothing);
      expect(
        find.textContaining('NO reemplaza la evaluación de un profesional'),
        findsOneWidget,
      );
    });

    testWidgets('uses custom text when provided', (WidgetTester tester) async {
      const customText = 'Custom disclaimer text for testing.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisclaimerWidget(compact: true, text: customText),
          ),
        ),
      );

      expect(find.text(customText), findsOneWidget);
    });

    testWidgets('full disclaimer has horizontal padding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DisclaimerWidget())),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.padding, isNotNull);
      expect(container.padding!.horizontal, greaterThan(0));
    });

    testWidgets('full disclaimer text has no forced line breaks', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DisclaimerWidget())),
      );

      // Last Text widget is the body text (first is the title)
      final textWidget = tester.widget<Text>(find.byType(Text).last);
      expect(textWidget.data, isNotNull);
      expect(textWidget.data!, isNot(contains('\n')));
    });

    testWidgets('full disclaimer has borderRadius', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DisclaimerWidget())),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });
  });
}
