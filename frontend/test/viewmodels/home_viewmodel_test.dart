import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/models/captured_media.dart';
import 'package:babyhealth/repositories/capture_repository.dart';
import 'package:babyhealth/services/video_capture_service.dart';
import 'package:babyhealth/viewmodels/home_viewmodel.dart';

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
  group('HomeViewModel', () {
    final testBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
    final testMedia = CapturedMedia(
      bytes: testBytes,
      fileName: 'test_video.mp4',
      mimeType: 'video/mp4',
    );

    late FakeVideoCaptureService fakeService;
    late CaptureRepository repository;
    late HomeViewModel viewModel;

    setUp(() {
      fakeService = FakeVideoCaptureService(recordVideoResult: testMedia);
      repository = CaptureRepository(videoCaptureService: fakeService);
      viewModel = HomeViewModel(captureRepository: repository);
    });

    group('initial state', () {
      test('currentScreen is "home" by default', () {
        expect(viewModel.state.currentScreen, equals('home'));
      });

      test('captureStatus is "idle" by default', () {
        expect(viewModel.state.captureStatus, equals('idle'));
      });

      test('media is null by default', () {
        expect(viewModel.state.media, isNull);
      });

      test('errorMessage is null by default', () {
        expect(viewModel.state.errorMessage, isNull);
      });
    });

    group('recordVideo', () {
      test('transitions to recording then captured on success', () async {
        final states = <String>[];
        viewModel.addListener(() {
          states.add(viewModel.state.captureStatus);
        });

        await viewModel.recordVideo();

        expect(fakeService.recordVideoCalled, isTrue);
        expect(states, contains('recording'));
        expect(viewModel.state.captureStatus, equals('captured'));
        expect(viewModel.state.media, equals(testMedia));
        expect(viewModel.state.errorMessage, isNull);
      });

      test('notifies listeners during transitions', () async {
        var listenerCallCount = 0;
        viewModel.addListener(() {
          listenerCallCount++;
        });

        await viewModel.recordVideo();

        // At least 2 notifications: recording → captured
        expect(listenerCallCount, greaterThanOrEqualTo(2));
      });

      test('sets error state when recording fails', () async {
        fakeService = FakeVideoCaptureService(
          recordVideoError: Exception('Camera not available'),
        );
        repository = CaptureRepository(videoCaptureService: fakeService);
        viewModel = HomeViewModel(captureRepository: repository);

        await viewModel.recordVideo();

        expect(viewModel.state.captureStatus, equals('error'));
        expect(
          viewModel.state.errorMessage,
          contains('Camera not available'),
        );
        expect(viewModel.state.media, isNull);
      });

      test('handles UnsupportedError from repository', () async {
        fakeService = FakeVideoCaptureService(
          recordVideoError: UnsupportedError(
            'Video recording is not supported on this platform.',
          ),
        );
        repository = CaptureRepository(videoCaptureService: fakeService);
        viewModel = HomeViewModel(captureRepository: repository);

        await viewModel.recordVideo();

        expect(viewModel.state.captureStatus, equals('error'));
        expect(viewModel.state.errorMessage, contains('not supported'));
      });
    });

    group('pickVideo', () {
      test('transitions to captured on success', () async {
        fakeService = FakeVideoCaptureService(pickVideoResult: testMedia);
        repository = CaptureRepository(videoCaptureService: fakeService);
        viewModel = HomeViewModel(captureRepository: repository);

        await viewModel.pickVideo();

        expect(fakeService.pickVideoCalled, isTrue);
        expect(viewModel.state.captureStatus, equals('captured'));
        expect(viewModel.state.media, equals(testMedia));
        expect(viewModel.state.errorMessage, isNull);
      });

      test('notifies listeners', () async {
        fakeService = FakeVideoCaptureService(pickVideoResult: testMedia);
        repository = CaptureRepository(videoCaptureService: fakeService);
        viewModel = HomeViewModel(captureRepository: repository);

        var listenerCallCount = 0;
        viewModel.addListener(() {
          listenerCallCount++;
        });

        await viewModel.pickVideo();

        expect(listenerCallCount, greaterThanOrEqualTo(1));
      });

      test('sets error state when picking fails', () async {
        fakeService = FakeVideoCaptureService(
          pickVideoError: Exception('Gallery access denied'),
        );
        repository = CaptureRepository(videoCaptureService: fakeService);
        viewModel = HomeViewModel(captureRepository: repository);

        await viewModel.pickVideo();

        expect(viewModel.state.captureStatus, equals('error'));
        expect(
          viewModel.state.errorMessage,
          contains('Gallery access denied'),
        );
        expect(viewModel.state.media, isNull);
      });
    });

    group('resetCapture', () {
      test('resets state to initial values', () async {
        await viewModel.recordVideo();
        expect(viewModel.state.captureStatus, equals('captured'));

        viewModel.resetCapture();

        expect(viewModel.state.captureStatus, equals('idle'));
        expect(viewModel.state.media, isNull);
        expect(viewModel.state.errorMessage, isNull);
      });

      test('notifies listeners', () {
        var listenerCallCount = 0;
        viewModel.addListener(() {
          listenerCallCount++;
        });

        viewModel.resetCapture();

        expect(listenerCallCount, equals(1));
      });
    });

    group('navigateToAnalysis', () {
      test('sets currentScreen to "analysis"', () {
        viewModel.navigateToAnalysis();

        expect(viewModel.state.currentScreen, equals('analysis'));
      });

      test('notifies listeners', () {
        var listenerCallCount = 0;
        viewModel.addListener(() {
          listenerCallCount++;
        });

        viewModel.navigateToAnalysis();

        expect(listenerCallCount, equals(1));
      });
    });

    group('navigateToHome', () {
      test('sets currentScreen to "home"', () {
        viewModel.navigateToAnalysis();
        viewModel.navigateToHome();

        expect(viewModel.state.currentScreen, equals('home'));
      });

      test('notifies listeners', () {
        var listenerCallCount = 0;
        viewModel.addListener(() {
          listenerCallCount++;
        });

        viewModel.navigateToHome();

        expect(listenerCallCount, equals(1));
      });
    });
  });
}
