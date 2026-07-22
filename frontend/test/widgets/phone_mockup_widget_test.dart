import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/widgets/phone_mockup_widget.dart';

void main() {
  group('PhoneMockupWidget', () {
    testWidgets('renders phone frame with child widget',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneMockupWidget(
              child: const Text('App Content'),
            ),
          ),
        ),
      );

      // The child widget should be rendered inside the mockup.
      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('renders with custom dimensions',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneMockupWidget(
              width: 320,
              height: 640,
              child: const Text('Custom Size'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Size'), findsOneWidget);
    });

    testWidgets('renders iOS status bar with time',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneMockupWidget(
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      // The status bar should show "9:41".
      expect(find.text('9:41'), findsOneWidget);
    });

    testWidgets('has dark border styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneMockupWidget(
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );

      // The phone mockup renders a ClipRRect for the screen area.
      expect(find.byType(ClipRRect), findsOneWidget);
    });

    testWidgets('renders internal Navigator for isolated routing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PhoneMockupWidget(
              child: const Text('Home Route'),
            ),
          ),
        ),
      );

      // Two Navigators exist: the root MaterialApp one and the internal one.
      expect(find.byType(Navigator), findsNWidgets(2));
    });
  });
}
