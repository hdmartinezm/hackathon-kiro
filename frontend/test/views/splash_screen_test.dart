import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:babyhealth/models/captured_media.dart';
import 'package:babyhealth/repositories/capture_repository.dart';
import 'package:babyhealth/services/video_capture_service.dart';
import 'package:babyhealth/viewmodels/home_viewmodel.dart';
import 'package:babyhealth/viewmodels/splash_viewmodel.dart';
import 'package:babyhealth/views/home_screen.dart';
import 'package:babyhealth/views/splash_screen.dart';

/// A fake [VideoCaptureService] with configurable behavior for testing.
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
  group('SplashScreen', () {
    late SplashViewModel splashViewModel;
    late HomeViewModel homeViewModel;

    setUp(() {
      splashViewModel = SplashViewModel();
      final fakeService = _FakeVideoCaptureService();
      final repository = CaptureRepository(videoCaptureService: fakeService);
      homeViewModel = HomeViewModel(captureRepository: repository);
    });

    Widget buildTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<SplashViewModel>.value(
            value: splashViewModel,
          ),
          ChangeNotifierProvider<HomeViewModel>.value(
            value: homeViewModel,
          ),
        ],
        child: MaterialApp(
          home: const SplashScreen(),
          routes: {
            '/home': (_) => const HomeScreen(),
          },
        ),
      );
    }

    testWidgets('renders medical disclaimer text', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('BabyHealth'), findsOneWidget);
      expect(
        find.text('Tu bebé te habla. Nosotros te ayudamos a entenderlo.'),
        findsOneWidget,
      );
      expect(find.text('Aviso importante'), findsOneWidget);
      expect(find.text('Aceptar y continuar'), findsOneWidget);
    });

    testWidgets('shows disclaimer content', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(
        find.textContaining('NO reemplaza la evaluación de un profesional'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Al aceptar, usted reconoce'),
        findsOneWidget,
      );
    });

    testWidgets('tapping accept button calls acceptDisclaimer',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(splashViewModel.state.disclaimerAccepted, isFalse);

      // Scroll down to make the button visible
      await tester.scrollUntilVisible(
        find.text('Aceptar y continuar'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Aceptar y continuar'));
      await tester.pumpAndSettle();

      expect(splashViewModel.state.disclaimerAccepted, isTrue);
    });

    testWidgets('navigates to HomeScreen after accepting disclaimer',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      splashViewModel.acceptDisclaimer();
      await tester.pumpAndSettle();

      expect(find.text('Analizar bebé'), findsOneWidget);
      expect(find.text('Grabar Video'), findsOneWidget);
    });

    testWidgets('does not navigate before accepting disclaimer',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Analizar bebé'), findsNothing);
      expect(find.text('Grabar Video'), findsNothing);
    });
  });
}
