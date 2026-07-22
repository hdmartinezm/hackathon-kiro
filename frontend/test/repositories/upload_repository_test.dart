import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:babyhealth/models/captured_media.dart';
import 'package:babyhealth/models/upload_url_dto.dart';
import 'package:babyhealth/repositories/upload_repository.dart';
import 'package:babyhealth/services/http_client.dart';
import 'package:babyhealth/services/storage_service.dart';

void main() {
  group('UploadRepository', () {
    const baseUrl = 'http://test.api';
    late MockClient mockClient;
    late HttpClient httpClient;
    late StorageService storageService;
    late UploadRepository repository;

    final testBytes = Uint8List.fromList([0x00, 0x01, 0x02, 0x03]);

    final testMedia = CapturedMedia(
      bytes: testBytes,
      fileName: 'video.mp4',
      mimeType: 'video/mp4',
    );

    setUp(() {
      mockClient = MockClient((request) async {
        if (request.url.path.contains('upload-url')) {
          return http.Response(
            jsonEncode({
              'upload_url': 'https://s3.example.com/upload/test.mp4',
              'expires_at': '2026-07-20T20:00:00Z',
              'video_key': 'sessions/test-001/video.mp4',
              'content_type': 'video/mp4',
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'ok': true}), 200);
      });
      httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
      storageService = StorageService(client: mockClient);
      repository = UploadRepository(
        httpClient: httpClient,
        storageService: storageService,
      );
    });

    tearDown(() {
      httpClient.dispose();
      storageService.dispose();
    });

    group('getUploadUrl', () {
      test('sends GET /upload-url with correct query parameters', () async {
        Uri? capturedUri;

        mockClient = MockClient((request) async {
          capturedUri = request.url;
          return http.Response(
            jsonEncode({
              'upload_url': 'https://s3.example.com/upload/test.mp4',
              'expires_at': '2026-07-20T20:00:00Z',
              'video_key': 'sessions/test-001/video.mp4',
              'content_type': 'video/mp4',
            }),
            200,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = UploadRepository(
          httpClient: httpClient,
          storageService: storageService,
        );

        await repository.getUploadUrl('video/mp4');

        expect(capturedUri!.path, endsWith('/upload-url'));
        expect(
          capturedUri!.queryParameters,
          containsPair('media_type', 'video'),
        );
        expect(
          capturedUri!.queryParameters,
          containsPair('content_type', 'video/mp4'),
        );
      });

      test('returns UploadUrlDto on success', () async {
        final result = await repository.getUploadUrl('video/mp4');

        expect(result, isA<UploadUrlDto>());
        expect(result.uploadUrl,
            equals('https://s3.example.com/upload/test.mp4'));
        expect(result.videoKey, equals('sessions/test-001/video.mp4'));
        expect(result.contentType, equals('video/mp4'));
        expect(result.expiresAt, equals('2026-07-20T20:00:00Z'));
      });

      test('throws HttpClientException on HTTP error', () async {
        mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({'detail': 'Bad request'}),
            400,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = UploadRepository(
          httpClient: httpClient,
          storageService: storageService,
        );

        expect(
          () => repository.getUploadUrl('video/mp4'),
          throwsA(isA<HttpClientException>()),
        );
      });

      test('HttpClientException contains status code on HTTP error',
          () async {
        mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({'detail': 'Server error'}),
            500,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = UploadRepository(
          httpClient: httpClient,
          storageService: storageService,
        );

        try {
          await repository.getUploadUrl('video/mp4');
          fail('Expected HttpClientException');
        } on HttpClientException catch (e) {
          expect(e.statusCode, equals(500));
          expect(e.message, contains('500'));
        }
      });
    });

    group('uploadMedia', () {
      test('validates MIME type before requesting URL', () async {
        final invalidMedia = CapturedMedia(
          bytes: testBytes,
          fileName: 'video.avi',
          mimeType: 'video/avi',
        );

        expect(
          () => repository.uploadMedia(invalidMedia),
          throwsArgumentError,
        );
      });

      test('rejects MIME type with descriptive error message', () async {
        final invalidMedia = CapturedMedia(
          bytes: testBytes,
          fileName: 'video.avi',
          mimeType: 'video/avi',
        );

        try {
          await repository.uploadMedia(invalidMedia);
          fail('Expected ArgumentError');
        } on ArgumentError catch (e) {
          expect(e.message, contains('video/avi'));
          expect(e.message, contains('video/mp4'));
          expect(e.message, contains('video/webm'));
        }
      });

      test('calls getUploadUrl with media.mimeType', () async {
        String? capturedContentType;

        mockClient = MockClient((request) async {
          if (request.url.path.contains('upload-url')) {
            capturedContentType =
                request.url.queryParameters['content_type'];
            return http.Response(
              jsonEncode({
                'upload_url': 'https://s3.example.com/upload/test.mp4',
                'expires_at': '2026-07-20T20:00:00Z',
                'video_key': 'sessions/test-001/video.mp4',
                'content_type': 'video/mp4',
              }),
              200,
            );
          }
          // StorageService PUT
          return http.Response('', 200);
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        storageService = StorageService(client: mockClient);
        repository = UploadRepository(
          httpClient: httpClient,
          storageService: storageService,
        );

        await repository.uploadMedia(testMedia);

        expect(capturedContentType, equals('video/mp4'));
      });

      test('passes UploadUrlDto to StorageService and returns videoKey',
          () async {
        final result = await repository.uploadMedia(testMedia);

        expect(result, equals('sessions/test-001/video.mp4'));
      });

      test('throws HttpClientException when getUploadUrl fails', () async {
        mockClient = MockClient((request) async {
          if (request.url.path.contains('upload-url')) {
            return http.Response(
              jsonEncode({'detail': 'Server error'}),
              500,
            );
          }
          return http.Response('', 200);
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        storageService = StorageService(client: mockClient);
        repository = UploadRepository(
          httpClient: httpClient,
          storageService: storageService,
        );

        expect(
          () => repository.uploadMedia(testMedia),
          throwsA(isA<HttpClientException>()),
        );
      });

      test('accepts video/webm MIME type', () async {
        final webmMedia = CapturedMedia(
          bytes: testBytes,
          fileName: 'video.webm',
          mimeType: 'video/webm',
        );

        mockClient = MockClient((request) async {
          if (request.url.path.contains('upload-url')) {
            return http.Response(
              jsonEncode({
                'upload_url': 'https://s3.example.com/upload/test.webm',
                'expires_at': '2026-07-20T20:00:00Z',
                'video_key': 'sessions/test-002/video.webm',
                'content_type': 'video/webm',
              }),
              200,
            );
          }
          return http.Response('', 200);
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        storageService = StorageService(client: mockClient);
        repository = UploadRepository(
          httpClient: httpClient,
          storageService: storageService,
        );

        final result = await repository.uploadMedia(webmMedia);

        expect(result, equals('sessions/test-002/video.webm'));
      });
    });
  });
}
