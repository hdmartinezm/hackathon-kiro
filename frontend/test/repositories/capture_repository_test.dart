import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/models/captured_media.dart';
import 'package:babyhealth/repositories/capture_repository.dart';
import 'package:babyhealth/services/video_capture_service.dart';

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
  group('CaptureRepository', () {
    final testBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
    final testMedia = CapturedMedia(
      bytes: testBytes,
      fileName: 'test_video.mp4',
      mimeType: 'video/mp4',
    );

    group('recordVideo', () {
      test('delegates to VideoCaptureService.recordVideo', () async {
        final fakeService = FakeVideoCaptureService(
          recordVideoResult: testMedia,
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        final result = await repository.recordVideo();

        expect(fakeService.recordVideoCalled, isTrue);
        expect(result, equals(testMedia));
      });

      test('returns CapturedMedia on success', () async {
        final fakeService = FakeVideoCaptureService(
          recordVideoResult: testMedia,
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        final result = await repository.recordVideo();

        expect(result, isA<CapturedMedia>());
        expect(result.fileName, equals('test_video.mp4'));
        expect(result.mimeType, equals('video/mp4'));
      });

      test('throws UnsupportedError when platform has no recording support',
          () async {
        final fakeService = FakeVideoCaptureService(
          recordVideoError: UnsupportedError(
            'Video recording is not supported on this platform.',
          ),
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        expect(
          () => repository.recordVideo(),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('throws Exception when user cancels recording', () async {
        final fakeService = FakeVideoCaptureService(
          recordVideoError: Exception(
            'Video recording was cancelled by the user.',
          ),
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        expect(
          () => repository.recordVideo(),
          throwsA(isA<Exception>()),
        );
      });

      test('handles PlatformException from underlying service', () async {
        final fakeService = FakeVideoCaptureService(
          recordVideoError: PlatformException(
            code: 'CAMERA_ERROR',
            message: 'Camera access denied',
          ),
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        expect(
          () => repository.recordVideo(),
          throwsA(isA<Exception>()),
        );
      });

      test('PlatformException is wrapped in a descriptive Exception',
          () async {
        final fakeService = FakeVideoCaptureService(
          recordVideoError: PlatformException(
            code: 'CAMERA_ERROR',
            message: 'Camera access denied',
          ),
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        try {
          await repository.recordVideo();
          fail('Expected Exception');
        } on Exception catch (e) {
          expect(e.toString(), contains('Camera access denied'));
        }
      });
    });

    group('pickVideo', () {
      test('delegates to VideoCaptureService.pickVideo', () async {
        final fakeService = FakeVideoCaptureService(
          pickVideoResult: testMedia,
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        final result = await repository.pickVideo();

        expect(fakeService.pickVideoCalled, isTrue);
        expect(result, equals(testMedia));
      });

      test('returns CapturedMedia on success', () async {
        final fakeService = FakeVideoCaptureService(
          pickVideoResult: testMedia,
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        final result = await repository.pickVideo();

        expect(result, isA<CapturedMedia>());
        expect(result.fileName, equals('test_video.mp4'));
        expect(result.mimeType, equals('video/mp4'));
      });

      test('throws Exception when user cancels selection', () async {
        final fakeService = FakeVideoCaptureService(
          pickVideoError: Exception(
            'Video selection was cancelled by the user.',
          ),
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        expect(
          () => repository.pickVideo(),
          throwsA(isA<Exception>()),
        );
      });

      test('handles PlatformException from underlying service', () async {
        final fakeService = FakeVideoCaptureService(
          pickVideoError: PlatformException(
            code: 'PICKER_ERROR',
            message: 'Gallery access denied',
          ),
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        expect(
          () => repository.pickVideo(),
          throwsA(isA<Exception>()),
        );
      });

      test('PlatformException is wrapped in a descriptive Exception',
          () async {
        final fakeService = FakeVideoCaptureService(
          pickVideoError: PlatformException(
            code: 'PICKER_ERROR',
            message: 'Gallery access denied',
          ),
        );
        final repository = CaptureRepository(
          videoCaptureService: fakeService,
        );

        try {
          await repository.pickVideo();
          fail('Expected Exception');
        } on Exception catch (e) {
          expect(e.toString(), contains('Gallery access denied'));
        }
      });
    });
  });
}
