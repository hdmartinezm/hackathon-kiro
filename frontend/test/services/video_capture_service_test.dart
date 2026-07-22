import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:babyhealth/models/captured_media.dart';
import 'package:babyhealth/services/platform_service.dart';
import 'package:babyhealth/services/video_capture_service.dart';

/// A fake [XFile] that returns predefined bytes without reading from disk.
class FakeXFile extends XFile {
  final Uint8List _fakeBytes;

  FakeXFile({
    required String name,
    String? mimeType,
    Uint8List? bytes,
  })  : _fakeBytes = bytes ?? Uint8List(0),
        super(
          name,
          mimeType: mimeType,
          name: name,
          bytes: bytes,
        );

  @override
  Future<Uint8List> readAsBytes() async => _fakeBytes;
}

/// A fake [ImagePicker] that returns predefined [XFile] instances.
///
/// [pickVideoMock] can return `XFile?` or throw to simulate errors.
class FakeImagePicker extends ImagePicker {
  final Function({required ImageSource source})? pickVideoMock;

  FakeImagePicker({this.pickVideoMock});

  @override
  Future<XFile?> pickVideo({
    required ImageSource source,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    Duration? maxDuration,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    final result = pickVideoMock?.call(source: source);
    // If the mock returned a Future, await it; otherwise cast directly.
    if (result is Future) {
      return await result as XFile?;
    }
    return result as XFile?;
  }
}

/// A fake [PlatformService] with configurable properties for testing.
class FakePlatformService implements PlatformService {
  @override
  final bool isWeb;
  @override
  final bool isAndroid;
  @override
  final bool hasVideoRecordingSupport;

  FakePlatformService({
    this.isWeb = false,
    this.isAndroid = true,
    this.hasVideoRecordingSupport = true,
  });
}

void main() {
  group('ImagePickerVideoCaptureService', () {
    final testBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

    group('recordVideo', () {
      test('returns CapturedMedia when recording succeeds', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) => FakeXFile(
            name: 'test_video.mp4',
            mimeType: 'video/mp4',
            bytes: testBytes,
          ),
        );
        final platformService = FakePlatformService(
          hasVideoRecordingSupport: true,
        );
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        final media = await service.recordVideo();

        expect(media, isA<CapturedMedia>());
        expect(media.fileName, equals('test_video.mp4'));
        expect(media.mimeType, equals('video/mp4'));
        expect(media.bytes, equals(testBytes));
      });

      test('throws UnsupportedError when platform has no recording support',
          () async {
        final fakePicker = FakeImagePicker();
        final platformService = FakePlatformService(
          hasVideoRecordingSupport: false,
        );
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        expect(
          () => service.recordVideo(),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('throws Exception when user cancels recording', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) => null,
        );
        final platformService = FakePlatformService(
          hasVideoRecordingSupport: true,
        );
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        expect(
          () => service.recordVideo(),
          throwsA(isA<Exception>()),
        );
      });

      test('throws Web-friendly message when recording on Web', () async {
        final fakePicker = FakeImagePicker();
        final platformService = FakePlatformService(
          isWeb: true,
          hasVideoRecordingSupport: false,
        );
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        expect(
          () => service.recordVideo(),
          throwsA(
            isA<UnsupportedError>().having(
              (e) => e.message,
              'message',
              contains('no está disponible en la versión web'),
            ),
          ),
        );
      });

      test('uses camera source for recording', () async {
        ImageSource? capturedSource;
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) {
            capturedSource = source;
            return FakeXFile(
              name: 'test.mp4',
              mimeType: 'video/mp4',
              bytes: testBytes,
            );
          },
        );
        final platformService = FakePlatformService(
          hasVideoRecordingSupport: true,
        );
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        await service.recordVideo();

        expect(capturedSource, equals(ImageSource.camera));
      });
    });

    group('pickVideo', () {
      test('returns CapturedMedia when selection succeeds', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) => FakeXFile(
            name: 'gallery_video.mp4',
            mimeType: 'video/mp4',
            bytes: testBytes,
          ),
        );
        final platformService = FakePlatformService();
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        final media = await service.pickVideo();

        expect(media, isA<CapturedMedia>());
        expect(media.fileName, equals('gallery_video.mp4'));
        expect(media.mimeType, equals('video/mp4'));
      });

      test('throws Exception when user cancels selection', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) => null,
        );
        final platformService = FakePlatformService();
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        expect(
          () => service.pickVideo(),
          throwsA(isA<Exception>()),
        );
      });

      test('throws Web-specific error when picker fails on Web', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) =>
              throw Exception('picker internal error'),
        );
        final platformService = FakePlatformService(isWeb: true);
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        expect(
          () => service.pickVideo(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Error al seleccionar el video en la versión web'),
            ),
          ),
        );
      });

      test('rethrows original error on non-Web when picker fails', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) =>
              throw Exception('picker internal error'),
        );
        final platformService = FakePlatformService(isWeb: false);
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        expect(
          () => service.pickVideo(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('picker internal error'),
            ),
          ),
        );
      });

      test('uses gallery source for selection', () async {
        ImageSource? capturedSource;
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) {
            capturedSource = source;
            return FakeXFile(
              name: 'test.mp4',
              mimeType: 'video/mp4',
              bytes: testBytes,
            );
          },
        );
        final platformService = FakePlatformService();
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        await service.pickVideo();

        expect(capturedSource, equals(ImageSource.gallery));
      });
    });

    group('MIME type handling', () {
      test('uses mimeType from XFile when available', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) => FakeXFile(
            name: 'clip.webm',
            mimeType: 'video/webm',
            bytes: testBytes,
          ),
        );
        final platformService = FakePlatformService();
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        final media = await service.pickVideo();

        expect(media.mimeType, equals('video/webm'));
      });

      test('derives mimeType from extension when XFile.mimeType is null',
          () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) => FakeXFile(
            name: 'video.mp4',
            bytes: testBytes,
          ),
        );
        final platformService = FakePlatformService();
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        final media = await service.pickVideo();

        expect(media.mimeType, equals('video/mp4'));
      });

      test('throws on Web when MIME type is not video/', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) => FakeXFile(
            name: 'image.png',
            mimeType: 'image/png',
            bytes: testBytes,
          ),
        );
        final platformService = FakePlatformService(isWeb: true);
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        expect(
          () => service.pickVideo(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('no es un video válido'),
            ),
          ),
        );
      });

      test('accepts video MIME on Web', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) => FakeXFile(
            name: 'clip.webm',
            mimeType: 'video/webm',
            bytes: testBytes,
          ),
        );
        final platformService = FakePlatformService(isWeb: true);
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        final media = await service.pickVideo();

        expect(media.mimeType, equals('video/webm'));
      });

      test('defaults to video/mp4 for unknown extensions', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) => FakeXFile(
            name: 'video.xyz',
            bytes: testBytes,
          ),
        );
        final platformService = FakePlatformService();
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        final media = await service.pickVideo();

        expect(media.mimeType, equals('video/mp4'));
      });
    });

    group('CapturedMedia contract', () {
      test('returns CapturedMedia without dart:io dependency', () async {
        final fakePicker = FakeImagePicker(
          pickVideoMock: ({required source}) => FakeXFile(
            name: 'test.mp4',
            mimeType: 'video/mp4',
            bytes: testBytes,
          ),
        );
        final platformService = FakePlatformService();
        final service = ImagePickerVideoCaptureService(
          platformService: platformService,
          picker: fakePicker,
        );

        final media = await service.pickVideo();

        expect(media.bytes, isA<Uint8List>());
        expect(media.fileName, isA<String>());
        expect(media.mimeType, isA<String>());
      });
    });
  });
}
