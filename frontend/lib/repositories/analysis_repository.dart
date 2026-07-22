import '../models/analysis_result.dart';
import '../models/analysis_result_dto.dart';
import '../models/analyze_request_dto.dart';
import '../services/http_client.dart';

/// Coordinates the `POST /analyze` API call and translates DTOs to domain models.
///
/// Injects [HttpClient] for HTTP communication. The public method [analyze]
/// accepts domain-level parameters and returns a domain [AnalysisResult],
/// keeping DTO translation internal.
class AnalysisRepository {
  final HttpClient _httpClient;

  AnalysisRepository({required HttpClient httpClient})
      : _httpClient = httpClient;

  /// Sends a video key for analysis and returns the domain result.
  ///
  /// Calls `POST /analyze` with [videoKey] and optional [sessionId].
  /// Throws [HttpClientException] on HTTP errors (non-2xx status or network failure).
  Future<AnalysisResult> analyze(
    String videoKey, {
    String? sessionId,
  }) async {
    final requestDto = AnalyzeRequestDto(
      videoKey: videoKey,
      sessionId: sessionId,
    );

    final response = await _httpClient.post(
      '/analyze',
      body: requestDto.toJson(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpClientException(
        message: 'Analysis request failed with HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    final resultDto = AnalysisResultDto.fromJson(response.jsonBody);
    return resultDto.toDomain();
  }
}
