import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/models/upload_url_dto.dart';

void main() {
  group('UploadUrlDto', () {
    // Mock JSON from api-contracts.md
    final mockJson = <String, dynamic>{
      'upload_url':
          'https://s3.mock-region.amazonaws.com/babyhealth-media/sessions/mock-001/video.mp4?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=mock%2F20260720%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20260720T193000Z&X-Amz-Expires=900&X-Amz-Signature=mocksignature',
      'expires_at': '2026-07-20T20:00:00Z',
      'video_key': 'sessions/mock-001/video.mp4',
      'content_type': 'video/mp4',
    };

    test('fromJson parses all fields correctly', () {
      final dto = UploadUrlDto.fromJson(mockJson);

      expect(dto.uploadUrl, startsWith('https://s3.mock-region.amazonaws.com'));
      expect(dto.uploadUrl, contains('X-Amz-Signature'));
      expect(dto.expiresAt, equals('2026-07-20T20:00:00Z'));
      expect(dto.videoKey, equals('sessions/mock-001/video.mp4'));
      expect(dto.contentType, equals('video/mp4'));
    });

    test('fromJson parses webm content type', () {
      final webmJson = <String, dynamic>{
        'upload_url': 'https://s3.amazonaws.com/bucket/key.webm?signature=abc',
        'expires_at': '2026-07-20T21:00:00Z',
        'video_key': 'sessions/abc-123/video.webm',
        'content_type': 'video/webm',
      };

      final dto = UploadUrlDto.fromJson(webmJson);

      expect(dto.contentType, equals('video/webm'));
      expect(dto.videoKey, equals('sessions/abc-123/video.webm'));
    });

    test('fromJson keys match backend contract (snake_case)', () {
      final dto = UploadUrlDto.fromJson(mockJson);

      // Verify the DTO has all expected fields from the contract
      expect(dto.uploadUrl, isNotEmpty);
      expect(dto.expiresAt, isNotEmpty);
      expect(dto.videoKey, isNotEmpty);
      expect(dto.contentType, isNotEmpty);
    });

    test('contentType matches the MIME signed by backend', () {
      final dto = UploadUrlDto.fromJson(mockJson);

      // The contentType in the response is the MIME the backend signed
      // It should match what was sent in the request
      expect(dto.contentType, equals('video/mp4'));
    });

    test('fromJson throws TypeError on missing fields', () {
      final incompleteJson = <String, dynamic>{
        'upload_url': 'https://example.com/upload',
        'expires_at': '2026-07-20T20:00:00Z',
        // missing video_key and content_type
      };

      expect(
        () => UploadUrlDto.fromJson(incompleteJson),
        throwsA(isA<TypeError>()),
      );
    });
  });
}
