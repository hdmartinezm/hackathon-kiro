import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:babyhealth/models/captured_media.dart';
import 'package:babyhealth/repositories/capture_repository.dart';
import 'package:babyhealth/services/video_capture_service.dart';
import 'package:babyhealth/viewmodels/home_viewmodel.dart';
import 'package:babyhealth/views/web_landing_screen.dart';

/// A fake [VideoCaptureService] for testing the web landing screen.
class _FakeVideoCaptureService implements VideoCaptureService {
  @override
  Future<CapturedMedia> recordVideo() async {
    throw UnsupportedError('Not used in this test');
  }

  @override
  Future<CapturedMedia> pickVideo() async {
    throw UnsupportedError('Not used in this test');
  }
}

void main() {
  group('WebLandingScreen', () {
    late CaptureRepository captureRepository;
    late HomeViewModel homeViewModel;

    setUp(() {
      final fakeService = _FakeVideoCaptureService();
      captureRepository = CaptureRepository(videoCaptureService: fakeService);
      homeViewModel = HomeViewModel(captureRepository: captureRepository);
    });

    Widget buildTestWidget() {
      return MultiProvider(
        providers: [
          Provider<CaptureRepository>.value(value: captureRepository),
          ChangeNotifierProvider<HomeViewModel>.value(value: homeViewModel),
        ],
        child: const MaterialApp(
          home: WebLandingScreen(),
        ),
      );
    }

    testWidgets('renders navigation bar with BabyHealth logo',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // The nav bar should show the app name.
      expect(find.text('BabyHealth'), findsWidgets);
    });

    testWidgets('renders hero section title lines',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.text('Tu bebé te habla.'),
        findsOneWidget,
      );
      expect(
        find.text('Nosotros te ayudamos a entenderlo.'),
        findsOneWidget,
      );
    });

    testWidgets('renders hero chip', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.text('INNOVACIÓN EN SALUD NEONATAL'),
        findsOneWidget,
      );
    });

    testWidgets('renders technology badges', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('★ AWS Bedrock'), findsOneWidget);
      expect(find.text('🕒 Análisis en segundos'), findsOneWidget);
      expect(find.text('+ Multimodal'), findsOneWidget);
    });

    testWidgets('renders "Solicitar acceso" CTA button',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Solicitar acceso →'), findsOneWidget);
    });

    testWidgets('renders "Ver cómo funciona" ghost button',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Ver cómo funciona'), findsOneWidget);
    });

    testWidgets('renders "El Desafío" section',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('EL DESAFÍO'), findsOneWidget);
      expect(
        find.text('La incertidumbre de los primeros meses'),
        findsOneWidget,
      );
    });

    testWidgets('renders "Cómo Funciona" section',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('CÓMO FUNCIONA'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('02'), findsOneWidget);
      expect(find.text('03'), findsOneWidget);
    });

    testWidgets('renders "Características" section',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('CARACTERÍSTICAS'), findsOneWidget);
      expect(find.text('VISIÓN POR IA'), findsOneWidget);
      expect(find.text('AUDIO IA'), findsOneWidget);
    });

    testWidgets('renders "Arquitectura" section',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('ARQUITECTURA'), findsOneWidget);
      expect(find.text('Flutter App'), findsOneWidget);
      expect(find.text('API Gateway'), findsOneWidget);
    });

    testWidgets('renders CTA subscription band',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.text('¿Listo para probar BabyHealth?'),
        findsOneWidget,
      );
    });

    testWidgets('renders footer with legal text',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.textContaining('Todos los derechos reservados'),
        findsOneWidget,
      );
    });

    testWidgets('renders medical disclaimer in footer',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.textContaining('no reemplaza la evaluación'),
        findsWidgets,
      );
    });
  });
}
