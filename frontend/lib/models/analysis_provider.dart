/// Available AI providers for neonatal analysis.
///
/// Each provider has different capabilities:
/// - [bedrock]: AWS Bedrock with Claude - extracts frames and analyzes visually
/// - [gemini]: Google Gemini - native multimodal video+audio analysis with cry classification
enum AnalysisProvider {
  /// AWS Bedrock with Claude Sonnet.
  /// Extracts video frames and spectrograms for analysis.
  bedrock,

  /// Google Gemini 2.5 Flash.
  /// Native multimodal analysis of video and audio.
  /// Includes cry classification with category, label, confidence, and recommendation.
  gemini;

  /// Returns a human-readable display name for this provider.
  String get displayName {
    switch (this) {
      case AnalysisProvider.bedrock:
        return 'Bedrock (Claude)';
      case AnalysisProvider.gemini:
        return 'Gemini';
    }
  }

  /// Returns a description of this provider's capabilities.
  String get description {
    switch (this) {
      case AnalysisProvider.bedrock:
        return 'Análisis visual con extracción de frames';
      case AnalysisProvider.gemini:
        return 'Análisis nativo de video y audio con clasificación de llanto';
    }
  }

  /// Returns an icon name suggestion for this provider.
  String get iconName {
    switch (this) {
      case AnalysisProvider.bedrock:
        return 'cloud';
      case AnalysisProvider.gemini:
        return 'auto_awesome';
    }
  }
}
