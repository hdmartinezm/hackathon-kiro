import 'analysis_provider.dart';
import 'captured_media.dart';

/// Configuration for an analysis request.
///
/// Bundles the [media] to analyze with the selected [provider].
/// Passed as route arguments from ModelSelectorScreen to AnalysisScreen.
class AnalysisConfig {
  /// The captured video to analyze.
  final CapturedMedia media;

  /// The AI provider to use for analysis.
  final AnalysisProvider provider;

  const AnalysisConfig({
    required this.media,
    required this.provider,
  });
}
