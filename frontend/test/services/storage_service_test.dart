import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:babyhealth/models/captured_media.dart';
import 'package:babyhealth/models/upload_url_dto.dart';
import 'package:babyhealth/services/http_client.dart';
import 'package:babyhealth/services/storage_service.dart';

void main() {
  group('StorageService', () {
    late MockClient mockClient;
    late StorageService storageService;

    const testUploadUrl = 'https://s3.example.com/upload/test.mp4';
    final testBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

    final testUploadInfo = UploadUrlDto(
      uploadUrl: testUploadUrl,
      expiresAt: '2026-07-20T20:00:00Z',
      videoKey: 'sessions/abc-123/video.mp4',
      contentType: 'video/mp4',
    );

    final testMedia = CapturedMedia(
      bytes: testBytes,
      fileName: 'video.mp4',
      mimeType: 'video/mp4',
    );

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response('', 200);
      });
      storageService = StorageService(client: mockClient);
    });

    group('uploadMedia', () {
      test('sends PUT request with correct URL and headers', () async {
        Uri? capturedUri;
        Map<String, String>? capturedHeaders;
        List<int>? capturedBody;

        mockClient = MockClient((request) async {
          capturedUri = request.url;
          capturedHeaders = request.headers;
          capturedBody = request.bodyBytes;
          return http.Response('', 200);
        });
        storageService = StorageService(client: mockClient);

        await storageService.uploadMedia(testUploadInfo, testMedia);

        expect(capturedUri.toString(), equals(testUploadUrl));
        expect(capturedHeaders!['content-type'], equals('video/mp4'));
        expect(capturedBody, equals(testBytes));
      });

      test('succeeds on HTTP 200', () async {
        await expectLater(
          storageService.uploadMedia(testUploadInfo, testMedia),
          completes,
        );
      });

      test('succeeds on HTTP 201', () async {
        mockClient = MockClient((_) async => http.Response('', 201));
        storageService = StorageService(client: mockClient);

        await expectLater(
          storageService.uploadMedia(testUploadInfo, testMedia),
          completes,
        );
      });

      test('throws ArgumentError on Content-Type mismatch', () async {
        final mismatchedMedia = CapturedMedia(
          bytes: testBytes,
          fileName: 'video.webm',
          mimeType: 'video/webm',
        );

        expect(
          () => storageService.uploadMedia(testUploadInfo, mismatchedMedia),
          throwsArgumentError,
        );
      });

      test('Content-Type mismatch error message includes both types', () async {
        final mismatchedMedia = CapturedMedia(
          bytes: testBytes,
          fileName: 'video.webm',
          mimeType: 'video/webm',
        );

        try {
          await storageService.uploadMedia(testUploadInfo, mismatchedMedia);
          fail('Expected ArgumentError');
        } on ArgumentError catch (e) {
          expect(e.message, contains('video/webm'));
          expect(e.message, contains('video/mp4'));
        }
      });

      test('retries on HTTP 403 up to 3 times then throws', () async {
        var callCount = 0;

        mockClient = MockClient((_) async {
          callCount++;
          return http.Response('Forbidden', 403);
        });
        storageService = StorageService(client: mockClient);

        await expectLater(
          () => storageService.uploadMedia(testUploadInfo, testMedia),
          throwsA(isA<HttpClientException>()),
        );

        expect(callCount, equals(3));
      });

      test('retries on HTTP 404 up to 3 times then throws', () async {
        var callCount = 0;

        mockClient = MockClient((_) async {
          callCount++;
          return http.Response('Not Found', 404);
        });
        storageService = StorageService(client: mockClient);

        await expectLater(
          () => storageService.uploadMedia(testUploadInfo, testMedia),
          throwsA(isA<HttpClientException>()),
        );

        expect(callCount, equals(3));
      });

      test('succeeds on retry after initial 403', () async {
        var callCount = 0;

        mockClient = MockClient((_) async {
          callCount++;
          if (callCount == 1) {
            return http.Response('Forbidden', 403);
          }
          return http.Response('', 200);
        });
        storageService = StorageService(client: mockClient);

        await expectLater(
          storageService.uploadMedia(testUploadInfo, testMedia),
          completes,
        );

        expect(callCount, equals(2));
      });

      test('throws immediately on non-retryable HTTP error (500)', () async {
        var callCount = 0;

        mockClient = MockClient((_) async {
          callCount++;
          return http.Response('Server Error', 500);
        });
        storageService = StorageService(client: mockClient);

        await expectLater(
          () => storageService.uploadMedia(testUploadInfo, testMedia),
          throwsA(isA<HttpClientException>()),
        );

        expect(callCount, equals(1));
      });

      test('throws HttpClientException with status code on failure', () async {
        mockClient = MockClient((_) async => http.Response('Forbidden', 403));
        storageService = StorageService(client: mockClient);

        try {
          await storageService.uploadMedia(testUploadInfo, testMedia);
          fail('Expected HttpClientException');
        } on HttpClientException catch (e) {
          expect(e.statusCode, equals(403));
          expect(e.message, contains('403'));
        }
      });

      test('retries on network error up to 3 times then throws', () async {
        var callCount = 0;

        mockClient = MockClient((_) async {
          callCount++;
          throw Exception('Connection reset');
        });
        storageService = StorageService(client: mockClient);

        await expectLater(
          () => storageService.uploadMedia(testUploadInfo, testMedia),
          throwsA(isA<HttpClientException>()),
        );

        expect(callCount, equals(3));
      });
    });
  });
}
