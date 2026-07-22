import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/models/analysis_status.dart';
import 'package:babyhealth/widgets/traffic_light_widget.dart';

void main() {
  group('TrafficLightWidget', () {
    testWidgets('renders normal status with green color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightWidget(status: AnalysisStatus.normal),
          ),
        ),
      );

      expect(find.text('Normal'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('renders requiereAtencion status with amber color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightWidget(status: AnalysisStatus.requiereAtencion),
          ),
        ),
      );

      expect(find.text('Requiere Atención'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('renders urgente status with red color',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrafficLightWidget(status: AnalysisStatus.urgente),
          ),
        ),
      );

      expect(find.text('Urgente'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
    });
  });
}
