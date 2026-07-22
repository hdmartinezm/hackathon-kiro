import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:babyhealth/models/analysis_result.dart';
import 'package:babyhealth/models/analysis_status.dart';
import 'package:babyhealth/repositories/analysis_repository.dart';
import 'package:babyhealth/services/http_client.dart';

void main() {
  group('AnalysisRepository', () {
    const baseUrl = 'http://test.api';
    late MockClient mockClient;
    late HttpClient httpClient;
    late AnalysisRepository repository;

    setUp(() {
      mockClient = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'status': 'normal',
            'observations': 'Test observation',
            'recommendations': 'Test recommendation',
            'confidence': 0.87,
            'cry_category': 'hambre',
            'error': null,
            'session_id': 'test-session-001',
            'disclaimer': 'Test disclaimer',
          }),
          200,
        );
      });
      httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
      repository = AnalysisRepository(httpClient: httpClient);
    });

    tearDown(() {
      httpClient.dispose();
    });

    group('analyze', () {
      test('sends POST /analyze with correct body', () async {
        Uri? capturedUri;
        Map<String, dynamic>? capturedBody;

        mockClient = MockClient((request) async {
          capturedUri = request.url;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'status': 'normal',
              'observations': 'OK',
              'recommendations': 'None',
              'session_id': 's-001',
              'disclaimer': 'Disclaimer',
            }),
            200,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = AnalysisRepository(httpClient: httpClient);

        await repository.analyze('sessions/test/video.mp4',
            sessionId: 'my-session');

        expect(capturedUri!.path, endsWith('/analyze'));
        expect(capturedBody!['video_key'], equals('sessions/test/video.mp4'));
        expect(capturedBody!['session_id'], equals('my-session'));
      });

      test('returns AnalysisResult on success', () async {
        final result = await repository.analyze('sessions/test/video.mp4');

        expect(result, isA<AnalysisResult>());
        expect(result.status, equals(AnalysisStatus.normal));
        expect(result.observations, equals('Test observation'));
        expect(result.recommendations, equals('Test recommendation'));
        expect(result.confidence, equals(0.87));
        expect(result.cryCategory, equals('hambre'));
        expect(result.error, isNull);
        expect(result.sessionId, equals('test-session-001'));
        expect(result.disclaimer, equals('Test disclaimer'));
      });

      test('translates DTO to domain model via toDomain()', () async {
        mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({
              'status': 'urgente',
              'observations': 'Critical',
              'recommendations': 'Seek help',
              'confidence': 0.94,
              'cry_category': 'dolor',
              'error': null,
              'session_id': 's-002',
              'disclaimer': 'Disclaimer',
            }),
            200,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = AnalysisRepository(httpClient: httpClient);

        final result = await repository.analyze('sessions/test/video.mp4');

        expect(result.status, equals(AnalysisStatus.urgente));
        expect(result.cryCategory, equals('dolor'));
      });

      test('handles optional fields as null', () async {
        mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({
              'status': 'requiere_atencion',
              'observations': 'Some observations',
              'recommendations': 'Monitor',
              'session_id': 's-003',
              'disclaimer': 'Disclaimer',
            }),
            200,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = AnalysisRepository(httpClient: httpClient);

        final result = await repository.analyze('sessions/test/video.mp4');

        expect(result.confidence, isNull);
        expect(result.cryCategory, isNull);
        expect(result.error, isNull);
      });

      test('handles partial degradation (non-null error)', () async {
        mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({
              'status': 'requiere_atencion',
              'observations': 'Partial result',
              'recommendations': 'Retry',
              'error': 'Could not classify cry',
              'session_id': 's-004',
              'disclaimer': 'Disclaimer',
            }),
            200,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = AnalysisRepository(httpClient: httpClient);

        final result = await repository.analyze('sessions/test/video.mp4');

        expect(result.error, equals('Could not classify cry'));
        expect(result.status, equals(AnalysisStatus.requiereAtencion));
      });

      test('throws HttpClientException on HTTP 500', () async {
        mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({'detail': 'Internal server error'}),
            500,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = AnalysisRepository(httpClient: httpClient);

        expect(
          () => repository.analyze('sessions/test/video.mp4'),
          throwsA(isA<HttpClientException>()),
        );
      });

      test('throws HttpClientException on HTTP 404', () async {
        mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({'detail': 'Not found'}),
            404,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = AnalysisRepository(httpClient: httpClient);

        expect(
          () => repository.analyze('sessions/test/video.mp4'),
          throwsA(isA<HttpClientException>()),
        );
      });

      test('HttpClientException contains status code on HTTP error', () async {
        mockClient = MockClient((_) async {
          return http.Response(
            jsonEncode({'detail': 'Bad request'}),
            400,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = AnalysisRepository(httpClient: httpClient);

        try {
          await repository.analyze('sessions/test/video.mp4');
          fail('Expected HttpClientException');
        } on HttpClientException catch (e) {
          expect(e.statusCode, equals(400));
          expect(e.message, contains('400'));
        }
      });

      test('sends POST without sessionId when not provided', () async {
        Map<String, dynamic>? capturedBody;

        mockClient = MockClient((request) async {
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'status': 'normal',
              'observations': 'OK',
              'recommendations': 'None',
              'session_id': 's-001',
              'disclaimer': 'Disclaimer',
            }),
            200,
          );
        });
        httpClient = HttpClient(baseUrl: baseUrl, client: mockClient);
        repository = AnalysisRepository(httpClient: httpClient);

        await repository.analyze('sessions/test/video.mp4');

        expect(capturedBody!['video_key'], equals('sessions/test/video.mp4'));
        expect(capturedBody!.containsKey('session_id'), isFalse);
      });
    });
  });
}
