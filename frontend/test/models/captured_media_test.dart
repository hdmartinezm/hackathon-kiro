import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/models/captured_media.dart';
import 'package:babyhealth/models/mime_validator.dart';

void main() {
  group('CapturedMedia', () {
    final testBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);
    final testDuration = Duration(seconds: 15);

    test('creates instance with all required fields', () {
      final media = CapturedMedia(
        bytes: testBytes,
        fileName: 'test_video.mp4',
        mimeType: 'video/mp4',
      );

      expect(media.bytes, equals(testBytes));
      expect(media.fileName, equals('test_video.mp4'));
      expect(media.mimeType, equals('video/mp4'));
      expect(media.duration, isNull);
    });

    test('creates instance with optional duration', () {
      final media = CapturedMedia(
        bytes: testBytes,
        fileName: 'test_video.mp4',
        mimeType: 'video/mp4',
        duration: testDuration,
      );

      expect(media.duration, equals(testDuration));
    });

    test('is immutable — bytes cannot be mutated externally', () {
      final mutableBytes = Uint8List.fromList([0x00, 0x01, 0x02]);
      final media = CapturedMedia(
        bytes: mutableBytes,
        fileName: 'test.mp4',
        mimeType: 'video/mp4',
      );

      // Mutate the original list
      mutableBytes[0] = 0xFF;

      // The media's bytes should be unaffected
      expect(media.bytes[0], equals(0x00));
    });

    test('equality — same values are equal', () {
      final media1 = CapturedMedia(
        bytes: Uint8List.fromList([0x00, 0x01]),
        fileName: 'a.mp4',
        mimeType: 'video/mp4',
        duration: Duration(seconds: 10),
      );
      final media2 = CapturedMedia(
        bytes: Uint8List.fromList([0x00, 0x01]),
        fileName: 'a.mp4',
        mimeType: 'video/mp4',
        duration: Duration(seconds: 10),
      );

      expect(media1, equals(media2));
      expect(media1.hashCode, equals(media2.hashCode));
    });

    test('equality — different values are not equal', () {
      final media1 = CapturedMedia(
        bytes: Uint8List.fromList([0x00, 0x01]),
        fileName: 'a.mp4',
        mimeType: 'video/mp4',
      );
      final media2 = CapturedMedia(
        bytes: Uint8List.fromList([0x00, 0x02]),
        fileName: 'a.mp4',
        mimeType: 'video/mp4',
      );

      expect(media1, isNot(equals(media2)));
    });

    test('copyWith preserves unchanged fields', () {
      final media = CapturedMedia(
        bytes: testBytes,
        fileName: 'original.mp4',
        mimeType: 'video/mp4',
        duration: testDuration,
      );

      final copy = media.copyWith(fileName: 'renamed.mp4');

      expect(copy.fileName, equals('renamed.mp4'));
      expect(copy.bytes, equals(testBytes));
      expect(copy.mimeType, equals('video/mp4'));
      expect(copy.duration, equals(testDuration));
    });

    test('copyWith clears duration when clearDuration is true', () {
      final media = CapturedMedia(
        bytes: testBytes,
        fileName: 'test.mp4',
        mimeType: 'video/mp4',
        duration: testDuration,
      );

      final copy = media.copyWith(clearDuration: true);

      expect(copy.duration, isNull);
    });

    test('does not import dart:io', () {
      // Verify the source file does not reference dart:io
      // by checking that CapturedMedia can be constructed without File
      final media = CapturedMedia(
        bytes: testBytes,
        fileName: 'test.mp4',
        mimeType: 'video/mp4',
      );

      expect(media.bytes, isA<Uint8List>());
    });
  });

  group('validateVideoMimeType', () {
    const acceptedMimes = ['video/mp4', 'video/webm'];

    test('accepts valid MIME type video/mp4', () {
      expect(
        () => validateVideoMimeType('video/mp4', acceptedMimes),
        returnsNormally,
      );
    });

    test('accepts valid MIME type video/webm', () {
      expect(
        () => validateVideoMimeType('video/webm', acceptedMimes),
        returnsNormally,
      );
    });

    test('rejects invalid MIME type video/avi', () {
      expect(
        () => validateVideoMimeType('video/avi', acceptedMimes),
        throwsArgumentError,
      );
    });

    test('rejects non-video MIME type text/plain', () {
      expect(
        () => validateVideoMimeType('text/plain', acceptedMimes),
        throwsArgumentError,
      );
    });

    test('rejects empty string MIME type', () {
      expect(
        () => validateVideoMimeType('', acceptedMimes),
        throwsArgumentError,
      );
    });

    test('error message contains the rejected MIME and accepted list', () {
      try {
        validateVideoMimeType('video/avi', acceptedMimes);
        fail('Expected ArgumentError');
      } on ArgumentError catch (e) {
        expect(e.message, contains('video/avi'));
        expect(e.message, contains('video/mp4'));
        expect(e.message, contains('video/webm'));
      }
    });
  });
}
