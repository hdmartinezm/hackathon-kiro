import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:babyhealth/models/captured_media.dart';
import 'package:babyhealth/repositories/capture_repository.dart';
import 'package:babyhealth/services/video_capture_service.dart';
import 'package:babyhealth/viewmodels/home_viewmodel.dart';
import 'package:babyhealth/views/home_screen.dart';

/// A fake [VideoCaptureService] with configurable behavior for testing.
class FakeVideoCaptureService implements VideoCaptureService {
  final CapturedMedia? recordVideoResult;
  final CapturedMedia? pickVideoResult;
  final Object? recordVideoError;
  final Object? pickVideoError;

  bool recordVideoCalled = false;
  bool pickVideoCalled = false;

  FakeVideoCaptureService({
    this.recordVideoResult,
    this.pickVideoResult,
    this.recordVideoError,
    this.pickVideoError,
  });

  @override
  Future<CapturedMedia> recordVideo() async {
    recordVideoCalled = true;
    if (recordVideoError != null) {
      throw recordVideoError!;
    }
    return recordVideoResult!;
  }

  @override
  Future<CapturedMedia> pickVideo() async {
    pickVideoCalled = true;
    if (pickVideoError != null) {
      throw pickVideoError!;
    }
    return pickVideoResult!;
  }
}

void main() {
  group('HomeScreen', () {
    final testBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
    final testMedia = CapturedMedia(
      bytes: testBytes,
      fileName: 'test_video.mp4',
      mimeType: 'video/mp4',
    );

    late HomeViewModel viewModel;
    late FakeVideoCaptureService fakeService;

    setUp(() {
      fakeService = FakeVideoCaptureService(recordVideoResult: testMedia);
      final repository = CaptureRepository(videoCaptureService: fakeService);
      viewModel = HomeViewModel(captureRepository: repository);
    });

    Widget buildTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<HomeViewModel>.value(value: viewModel),
        ],
        child: MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/analysis': (_) => const SizedBox.shrink(),
          },
        ),
      );
    }

    testWidgets('renders medical disclaimer', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('BabyHealth'), findsOneWidget);
      expect(
        find.textContaining('NO reemplaza la evaluación de un profesional'),
        findsOneWidget,
      );
    });

    testWidgets('renders both action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Grabar Video'), findsOneWidget);
      expect(find.text('Seleccionar Video'), findsOneWidget);
    });

    testWidgets('renders app description', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Analizar bebé'), findsOneWidget);
    });

    testWidgets('tapping Grabar Video calls recordVideo',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(viewModel.state.captureStatus, equals('idle'));

      await tester.tap(find.text('Grabar Video'));
      await tester.pump();

      expect(fakeService.recordVideoCalled, isTrue);
    });

    testWidgets('tapping Seleccionar Video calls pickVideo',
        (WidgetTester tester) async {
      fakeService = FakeVideoCaptureService(pickVideoResult: testMedia);
      final repository = CaptureRepository(videoCaptureService: fakeService);
      viewModel = HomeViewModel(captureRepository: repository);

      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Seleccionar Video'));
      await tester.pump();

      expect(fakeService.pickVideoCalled, isTrue);
    });

    testWidgets('shows error message when capture fails',
        (WidgetTester tester) async {
      fakeService = FakeVideoCaptureService(
        recordVideoError: Exception('Camera not available'),
      );
      final repository = CaptureRepository(videoCaptureService: fakeService);
      viewModel = HomeViewModel(captureRepository: repository);

      await tester.pumpWidget(buildTestWidget());

      await viewModel.recordVideo();
      await tester.pump();

      expect(find.textContaining('Camera not available'), findsOneWidget);
    });

    testWidgets('shows video preview when media is captured',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await viewModel.recordVideo();
      await tester.pump();

      expect(find.text('Video listo'), findsOneWidget);
      expect(find.text('test_video.mp4'), findsOneWidget);
    });

    testWidgets('shows reset button when status is captured',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await viewModel.recordVideo();
      await tester.pump();

      expect(find.text('Reiniciar'), findsOneWidget);
    });

    testWidgets('tapping reset clears state', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      await viewModel.recordVideo();
      await tester.pump();

      expect(viewModel.state.captureStatus, equals('captured'));

      // Scroll down to make the reset button visible.
      await tester.scrollUntilVisible(
        find.text('Reiniciar'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Reiniciar'));
      await tester.pump();

      expect(viewModel.state.captureStatus, equals('idle'));
    });

    testWidgets('buttons are enabled after error',
        (WidgetTester tester) async {
      fakeService = FakeVideoCaptureService(
        recordVideoError: Exception('Camera not available'),
      );
      final repository = CaptureRepository(videoCaptureService: fakeService);
      viewModel = HomeViewModel(captureRepository: repository);

      await tester.pumpWidget(buildTestWidget());

      await viewModel.recordVideo();
      await tester.pump();

      final recordButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Grabar Video'),
      );
      expect(recordButton.onPressed, isNotNull);

      final selectButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Seleccionar Video'),
      );
      expect(selectButton.onPressed, isNotNull);
    });
  });
}
