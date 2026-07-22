import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Exception thrown by [HttpClient] on request failures.
class HttpClientException implements Exception {
  /// Human-readable error message.
  final String message;

  /// HTTP status code, if the error originated from an HTTP response.
  final int? statusCode;

  /// Response body, if available.
  final String? body;

  const HttpClientException({
    required this.message,
    this.statusCode,
    this.body,
  });

  @override
  String toString() => 'HttpClientException: $message'
      '${statusCode != null ? ' (status: $statusCode)' : ''}';
}

/// Typed response wrapper returned by [HttpClient] methods.
class HttpClientResponse {
  /// HTTP status code (e.g. 200, 404, 500).
  final int statusCode;

  /// Raw response body as a string.
  final String body;

  /// Response headers.
  final Map<String, String> headers;

  const HttpClientResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  /// Convenience getter that decodes [body] as JSON.
  Map<String, dynamic> get jsonBody => jsonDecode(body) as Map<String, dynamic>;
}

/// Stateless HTTP client for backend API calls.
///
/// Wraps `package:http` with typed responses, timeout handling, and
/// consistent error reporting. The [baseUrl] is injected at construction
/// time (typically from [ApiConfig]).
class HttpClient {
  final String baseUrl;
  final http.Client _client;
  final Duration _timeout;

  HttpClient({
    required this.baseUrl,
    http.Client? client,
    Duration timeout = const Duration(seconds: 30),
  })  : _client = client ?? http.Client(),
        _timeout = timeout;

  /// Sends a GET request to [path] relative to [baseUrl].
  ///
  /// Optional [queryParams] are appended as URL query parameters.
  /// Optional [headers] are merged into the request.
  Future<HttpClientResponse> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    return _sendRequest(() => _client.get(uri, headers: headers));
  }

  /// Sends a POST request to [path] relative to [baseUrl].
  ///
  /// [body] is sent as JSON with `Content-Type: application/json`.
  /// Optional [headers] are merged into the request.
  Future<HttpClientResponse> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
    return _sendRequest(
      () => _client.post(
        uri,
        headers: mergedHeaders,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  /// Sends a PUT request to [path] relative to [baseUrl].
  ///
  /// [body] is sent as JSON with `Content-Type: application/json`.
  /// Optional [headers] are merged into the request.
  Future<HttpClientResponse> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final mergedHeaders = <String, String>{
      'Content-Type': 'application/json',
      if (headers != null) ...headers,
    };
    return _sendRequest(
      () => _client.put(
        uri,
        headers: mergedHeaders,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
  }

  /// Sends a DELETE request to [path] relative to [baseUrl].
  ///
  /// Optional [headers] are merged into the request.
  Future<HttpClientResponse> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    return _sendRequest(() => _client.delete(uri, headers: headers));
  }

  /// Executes [requestFn] with timeout and wraps errors.
  Future<HttpClientResponse> _sendRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      final response = await requestFn().timeout(_timeout);
      return HttpClientResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } on TimeoutException {
      throw const HttpClientException(message: 'Request timed out');
    } catch (e) {
      throw HttpClientException(message: 'Network error: $e');
    }
  }

  /// Releases underlying HTTP client resources.
  void dispose() {
    _client.close();
  }
}
