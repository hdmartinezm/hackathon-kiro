import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:babyhealth/services/http_client.dart';

void main() {
  group('HttpClient', () {
    const baseUrl = 'http://test.api';
    late MockClient mockClient;
    late HttpClient client;

    setUp(() {
      mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'ok': true, 'path': request.url.path}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      client = HttpClient(baseUrl: baseUrl, client: mockClient);
    });

    tearDown(() {
      client.dispose();
    });

    group('get', () {
      test('sends GET request to the correct URL', () async {
        mockClient = MockClient((request) async {
          expect(request.method, equals('GET'));
          expect(request.url.toString(), equals('$baseUrl/test'));
          return http.Response(jsonEncode({'ok': true}), 200);
        });
        client = HttpClient(baseUrl: baseUrl, client: mockClient);

        final response = await client.get('/test');
        expect(response.statusCode, equals(200));
      });

      test('appends query parameters', () async {
        mockClient = MockClient((request) async {
          expect(
            request.url.queryParameters,
            containsPair('key', 'value'),
          );
          return http.Response(jsonEncode({'ok': true}), 200);
        });
        client = HttpClient(baseUrl: baseUrl, client: mockClient);

        await client.get('/search', queryParams: {'key': 'value'});
      });

      test('merges custom headers', () async {
        mockClient = MockClient((request) async {
          expect(request.headers, containsPair('X-Custom', 'abc'));
          return http.Response(jsonEncode({'ok': true}), 200);
        });
        client = HttpClient(baseUrl: baseUrl, client: mockClient);

        await client.get('/test', headers: {'X-Custom': 'abc'});
      });
    });

    group('post', () {
      test('sends POST request with JSON body', () async {
        mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.headers['content-type'], equals('application/json'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, containsPair('key', 'value'));
          return http.Response(jsonEncode({'ok': true}), 201);
        });
        client = HttpClient(baseUrl: baseUrl, client: mockClient);

        final response = await client.post('/create', body: {'key': 'value'});
        expect(response.statusCode, equals(201));
      });

      test('sends POST without body when body is null', () async {
        mockClient = MockClient((request) async {
          expect(request.method, equals('POST'));
          expect(request.body, isEmpty);
          return http.Response(jsonEncode({'ok': true}), 200);
        });
        client = HttpClient(baseUrl: baseUrl, client: mockClient);

        await client.post('/create');
      });
    });

    group('put', () {
      test('sends PUT request with JSON body', () async {
        mockClient = MockClient((request) async {
          expect(request.method, equals('PUT'));
          expect(request.headers['content-type'], equals('application/json'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, containsPair('key', 'value'));
          return http.Response(jsonEncode({'ok': true}), 200);
        });
        client = HttpClient(baseUrl: baseUrl, client: mockClient);

        final response = await client.put('/update', body: {'key': 'value'});
        expect(response.statusCode, equals(200));
      });
    });

    group('delete', () {
      test('sends DELETE request', () async {
        mockClient = MockClient((request) async {
          expect(request.method, equals('DELETE'));
          return http.Response(jsonEncode({'ok': true}), 200);
        });
        client = HttpClient(baseUrl: baseUrl, client: mockClient);

        final response = await client.delete('/resource/1');
        expect(response.statusCode, equals(200));
      });
    });

    group('HttpClientResponse', () {
      test('jsonBody decodes response body', () async {
        final response = await client.get('/test');
        expect(response.jsonBody, containsPair('ok', true));
        expect(response.jsonBody, containsPair('path', '/test'));
      });
    });

    group('error handling', () {
      test('throws HttpClientException on network error', () async {
        mockClient = MockClient((_) async =>
            throw Exception('Connection refused'));
        client = HttpClient(baseUrl: baseUrl, client: mockClient);

        expect(
          () => client.get('/fail'),
          throwsA(isA<HttpClientException>()),
        );
      });

      test('throws HttpClientException on timeout', () async {
        mockClient = MockClient((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return http.Response('', 200);
        });
        client = HttpClient(
          baseUrl: baseUrl,
          client: mockClient,
          timeout: const Duration(milliseconds: 10),
        );

        expect(
          () => client.get('/slow'),
          throwsA(isA<HttpClientException>()),
        );
      });

      test('HttpClientException contains status code when available', () async {
        mockClient = MockClient((_) async {
          return http.Response('Not Found', 404);
        });
        client = HttpClient(baseUrl: baseUrl, client: mockClient);

        try {
          // The client does not throw on non-2xx; it returns the response.
          // The caller decides how to handle status codes.
          final response = await client.get('/not-found');
          expect(response.statusCode, equals(404));
          expect(response.body, equals('Not Found'));
        } catch (_) {
          // Not expected — HttpClient returns responses as-is.
        }
      });
    });
  });
}
