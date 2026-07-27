import 'analysis_status.dart';
import 'analysis_result.dart';

/// DTO for parsing the backend's `AnalysisResult` JSON response.
///
/// Maps snake_case JSON fields to camelCase Dart fields. Use [fromJson] to
/// parse a JSON map and [toDomain] to convert to the immutable domain model.
///
/// Supports both Bedrock (/analyze) and Gemini (/analyze-gemini) endpoints.
class AnalysisResultDto {
  /// Severity status string from backend (`"normal"`, `"requiere_atencion"`, `"urgente"`).
  final String status;

  /// Textual observations from the multimodal analysis.
  final String observations;

  /// Textual recommendations for the caregiver.
  final String recommendations;

  /// Confidence level (0.0 — 1.0), may be null.
  final double? confidence;

  /// Detected cry category (e.g. "hambre", "dolor", "sueño"), may be null.
  final String? cryCategory;

  /// Human-readable label for the cry category (e.g. "Hambre", "Dolor").
  final String? cryLabel;

  /// Confidence level for cry classification (0.0 — 1.0), may be null.
  final double? cryConfidence;

  /// Specific recommendation based on the detected cry type.
  final String? cryRecommendation;

  /// Partial degradation message.
  ///
  /// `null` = fully successful. Non-null = partial degradation (warning).
  final String? error;

  /// Session identifier.
  final String sessionId;

  /// Mandatory medical disclaimer.
  final String disclaimer;

  const AnalysisResultDto({
    required this.status,
    required this.observations,
    required this.recommendations,
    this.confidence,
    this.cryCategory,
    this.cryLabel,
    this.cryConfidence,
    this.cryRecommendation,
    this.error,
    required this.sessionId,
    required this.disclaimer,
  });

  /// Parses an [AnalysisResultDto] from the backend JSON response.
  ///
  /// All fields are expected to be present in [json] except nullable fields
  /// which default to `null` when absent.
  factory AnalysisResultDto.fromJson(Map<String, dynamic> json) {
    return AnalysisResultDto(
      status: json['status'] as String,
      observations: json['observations'] as String,
      recommendations: json['recommendations'] as String,
      confidence: (json['confidence'] as num?)?.toDouble(),
      cryCategory: json['cry_category'] as String?,
      cryLabel: json['cry_label'] as String?,
      cryConfidence: (json['cry_confidence'] as num?)?.toDouble(),
      cryRecommendation: json['cry_recommendation'] as String?,
      error: json['error'] as String?,
      sessionId: json['session_id'] as String,
      disclaimer: json['disclaimer'] as String,
    );
  }

  /// Converts this DTO to the immutable domain model [AnalysisResult].
  AnalysisResult toDomain() {
    return AnalysisResult(
      status: AnalysisStatus.fromJson(status),
      observations: observations,
      recommendations: recommendations,
      confidence: confidence,
      cryCategory: cryCategory,
      cryLabel: cryLabel,
      cryConfidence: cryConfidence,
      cryRecommendation: cryRecommendation,
      error: error,
      sessionId: sessionId,
      disclaimer: disclaimer,
    );
  }
}
