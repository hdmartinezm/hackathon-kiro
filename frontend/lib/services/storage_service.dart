import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/captured_media.dart';
import '../models/upload_url_dto.dart';
import 'http_client.dart';

/// Uploads video bytes to pre-signed S3 URLs.
///
/// Validates Content-Type match between [CapturedMedia] and [UploadUrlDto]
/// before executing the PUT request. Implements retry logic for transient
/// errors (HTTP 403/404).
class StorageService {
  final http.Client _client;

  /// Maximum number of upload attempts for retryable errors.
  static const int _maxRetries = 3;

  StorageService({http.Client? client})
      : _client = client ?? http.Client();

  /// Uploads [media] bytes to the pre-signed [uploadInfo.uploadUrl].
  ///
  /// Steps:
  /// 1. Verifies `media.mimeType == uploadInfo.contentType` — throws
  ///    [ArgumentError] on mismatch.
  /// 2. Executes PUT with `Content-Type: uploadInfo.contentType`.
  /// 3. Retries up to 3 times on HTTP 403 or 404.
  ///
  /// Throws [HttpClientException] on failure after exhausting retries.
  Future<void> uploadMedia(UploadUrlDto uploadInfo, CapturedMedia media) async {
    if (media.mimeType != uploadInfo.contentType) {
      throw ArgumentError(
        'Content-Type mismatch: media.mimeType ("${media.mimeType}") '
        'does not match uploadInfo.contentType ("${uploadInfo.contentType}").',
      );
    }

    final uri = Uri.parse(uploadInfo.uploadUrl);
    final headers = <String, String>{
      'Content-Type': uploadInfo.contentType,
    };

    for (var attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _client.put(
          uri,
          headers: headers,
          body: media.bytes,
        );

        if (_isSuccess(response.statusCode)) {
          return;
        }

        if (_isRetryable(response.statusCode) && attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }

        throw HttpClientException(
          message: 'Upload failed with HTTP ${response.statusCode}',
          statusCode: response.statusCode,
          body: response.body,
        );
      } on HttpClientException {
        rethrow;
      } catch (e) {
        if (attempt < _maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
          continue;
        }
        throw HttpClientException(
          message: 'Upload failed after $_maxRetries attempts: $e',
        );
      }
    }
  }

  /// Returns `true` for HTTP status codes indicating success (2xx).
  bool _isSuccess(int statusCode) =>
      statusCode >= 200 && statusCode < 300;

  /// Returns `true` for status codes that should trigger a retry.
  bool _isRetryable(int statusCode) =>
      statusCode == 403 || statusCode == 404;

  /// Releases underlying HTTP client resources.
  void dispose() {
    _client.close();
  }
}
