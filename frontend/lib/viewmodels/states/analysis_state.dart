import '../../models/analysis_result.dart';

/// Immutable state snapshot for the Analysis screen.
///
/// Tracks the analysis flow status, result, and any error messages.
class AnalysisState {
  /// Current analysis status.
  ///
  /// Expected values: `'idle'`, `'uploading'`, `'analyzing'`, `'completed'`,
  /// `'error'`.
  final String status;

  /// The analysis result, available when [status] is `'completed'`.
  final AnalysisResult? result;

  /// Descriptive error message when [status] is `'error'`.
  final String? errorMessage;

  /// Creates an immutable [AnalysisState].
  ///
  /// [status] defaults to `'idle'`. [result] and [errorMessage] are optional.
  const AnalysisState({
    this.status = 'idle',
    this.result,
    this.errorMessage,
  });

  /// Creates a copy with optionally updated fields.
  AnalysisState copyWith({
    String? status,
    AnalysisResult? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return AnalysisState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnalysisState &&
        other.status == status &&
        other.result == result &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode => Object.hash(status, result, errorMessage);
}
