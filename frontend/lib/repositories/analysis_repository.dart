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
  /// Uses AWS Bedrock for visual analysis.
  /// Throws [HttpClientException] on HTTP errors (non-2xx status or network failure).
  Future<AnalysisResult> analyze(
    String videoKey, {
    String? sessionId,
  }) async {
    return _analyzeWithEndpoint('/analyze', videoKey, sessionId: sessionId);
  }

  /// Sends a video key for analysis using Google Gemini (native multimodal).
  ///
  /// Calls `POST /analyze-gemini` with [videoKey] and optional [sessionId].
  /// Gemini provides native video+audio analysis without frame extraction.
  /// Includes cry classification with category, label, confidence, and recommendation.
  /// Throws [HttpClientException] on HTTP errors (non-2xx status or network failure).
  Future<AnalysisResult> analyzeWithGemini(
    String videoKey, {
    String? sessionId,
  }) async {
    return _analyzeWithEndpoint('/analyze-gemini', videoKey, sessionId: sessionId);
  }

  /// Internal method that handles the actual API call.
  Future<AnalysisResult> _analyzeWithEndpoint(
    String endpoint,
    String videoKey, {
    String? sessionId,
  }) async {
    final requestDto = AnalyzeRequestDto(
      videoKey: videoKey,
      sessionId: sessionId,
    );

    final response = await _httpClient.post(
      endpoint,
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
