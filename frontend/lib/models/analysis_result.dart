import 'analysis_status.dart';

/// Immutable domain model representing the result of a neonatal analysis.
///
/// Maps from the backend's `AnalysisResult` DTO. The [error] field has special
/// semantics: `null` means the analysis was fully successful, while a non-null
/// value indicates partial degradation (shown as a warning, not a terminal error).
///
/// Supports both Bedrock (/analyze) and Gemini (/analyze-gemini) responses.
class AnalysisResult {
  /// Severity status of the analysis.
  final AnalysisStatus status;

  /// Textual observations from the multimodal analysis.
  final String observations;

  /// Textual recommendations for the caregiver.
  final String recommendations;

  /// Confidence level of the analysis (0.0 — 1.0), if available.
  final double? confidence;

  /// Detected cry category (e.g. "hambre", "dolor", "sueño"), if available.
  final String? cryCategory;

  /// Human-readable label for the cry category (e.g. "Hambre", "Dolor").
  final String? cryLabel;

  /// Confidence level for cry classification (0.0 — 1.0), if available.
  final double? cryConfidence;

  /// Specific recommendation based on the detected cry type.
  final String? cryRecommendation;

  /// Partial degradation message.
  ///
  /// - `null`: analysis fully successful.
  /// - Non-null: analysis completed with partial degradation. The frontend
  ///   should display this as a warning, not a terminal error.
  final String? error;

  /// Session identifier for traceability.
  final String sessionId;

  /// Mandatory medical disclaimer text.
  final String disclaimer;

  /// Creates an immutable [AnalysisResult] instance.
  ///
  /// [status], [observations], [recommendations], [sessionId], and [disclaimer]
  /// are required. All cry-related fields and [error] are optional.
  const AnalysisResult({
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

  /// Returns true if cry analysis data is available.
  bool get hasCryAnalysis => cryCategory != null;

  /// Returns the display label for the cry, falling back to category if label is null.
  String? get cryDisplayLabel => cryLabel ?? cryCategory;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisResult &&
        other.status == status &&
        other.observations == observations &&
        other.recommendations == recommendations &&
        other.confidence == confidence &&
        other.cryCategory == cryCategory &&
        other.cryLabel == cryLabel &&
        other.cryConfidence == cryConfidence &&
        other.cryRecommendation == cryRecommendation &&
        other.error == error &&
        other.sessionId == sessionId &&
        other.disclaimer == disclaimer;
  }

  @override
  int get hashCode => Object.hash(
        status,
        observations,
        recommendations,
        confidence,
        cryCategory,
        cryLabel,
        cryConfidence,
        cryRecommendation,
        error,
        sessionId,
        disclaimer,
      );

  /// Creates a copy with optionally updated fields.
  AnalysisResult copyWith({
    AnalysisStatus? status,
    String? observations,
    String? recommendations,
    double? confidence,
    String? cryCategory,
    String? cryLabel,
    double? cryConfidence,
    String? cryRecommendation,
    String? error,
    String? sessionId,
    String? disclaimer,
    bool clearConfidence = false,
    bool clearCryCategory = false,
    bool clearCryLabel = false,
    bool clearCryConfidence = false,
    bool clearCryRecommendation = false,
    bool clearError = false,
  }) {
    return AnalysisResult(
      status: status ?? this.status,
      observations: observations ?? this.observations,
      recommendations: recommendations ?? this.recommendations,
      confidence: clearConfidence ? null : (confidence ?? this.confidence),
      cryCategory: clearCryCategory ? null : (cryCategory ?? this.cryCategory),
      cryLabel: clearCryLabel ? null : (cryLabel ?? this.cryLabel),
      cryConfidence: clearCryConfidence ? null : (cryConfidence ?? this.cryConfidence),
      cryRecommendation: clearCryRecommendation ? null : (cryRecommendation ?? this.cryRecommendation),
      error: clearError ? null : (error ?? this.error),
      sessionId: sessionId ?? this.sessionId,
      disclaimer: disclaimer ?? this.disclaimer,
    );
  }
}
