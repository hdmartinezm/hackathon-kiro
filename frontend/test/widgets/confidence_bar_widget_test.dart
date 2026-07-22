import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/widgets/confidence_bar_widget.dart';

void main() {
  group('ConfidenceBarWidget', () {
    testWidgets('renders confidence percentage text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ConfidenceBarWidget(confidence: 0.87)),
        ),
      );

      expect(find.text('87%'), findsOneWidget);
    });

    testWidgets('renders 0% for zero confidence', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ConfidenceBarWidget(confidence: 0.0)),
        ),
      );

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('renders 100% for full confidence',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ConfidenceBarWidget(confidence: 1.0)),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('renders LinearProgressIndicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ConfidenceBarWidget(confidence: 0.5)),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });
}
