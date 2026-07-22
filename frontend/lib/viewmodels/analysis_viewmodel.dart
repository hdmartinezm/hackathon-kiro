import 'package:flutter/foundation.dart';

import '../models/captured_media.dart';
import '../repositories/analysis_repository.dart';
import '../repositories/upload_repository.dart';
import 'states/analysis_state.dart';

/// ViewModel for the Analysis screen.
///
/// Coordinates the upload and analysis flow via [UploadRepository] and
/// [AnalysisRepository]. Exposes an immutable [AnalysisState] snapshot to
/// the view layer.
class AnalysisViewModel extends ChangeNotifier {
  final UploadRepository _uploadRepository;
  final AnalysisRepository _analysisRepository;

  AnalysisState _state = const AnalysisState();

  /// The current immutable state snapshot.
  AnalysisState get state => _state;

  /// Creates an [AnalysisViewModel] with the required repositories.
  AnalysisViewModel({
    required UploadRepository uploadRepository,
    required AnalysisRepository analysisRepository,
  })  : _uploadRepository = uploadRepository,
        _analysisRepository = analysisRepository;

  /// Starts the full analysis flow for the given [media].
  ///
  /// Steps:
  /// 1. Sets status to `'uploading'` and uploads [media] via
  ///    [UploadRepository.uploadMedia].
  /// 2. Sets status to `'analyzing'` and calls
  ///    [AnalysisRepository.analyze] with the returned `videoKey`.
  /// 3. On success, sets status to `'completed'` with the [AnalysisResult].
  ///
  /// On failure at any step, sets status to `'error'` with a descriptive
  /// [AnalysisState.errorMessage].
  Future<void> startAnalysis(CapturedMedia media) async {
    _state = _state.copyWith(status: 'uploading', errorMessage: null);
    notifyListeners();

    try {
      final videoKey = await _uploadRepository.uploadMedia(media);

      _state = _state.copyWith(status: 'analyzing');
      notifyListeners();

      final result = await _analysisRepository.analyze(videoKey);

      _state = _state.copyWith(status: 'completed', result: result);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: 'error',
        errorMessage: 'Analysis failed: $e',
      );
      notifyListeners();
    }
  }

  /// Resets the analysis state to its initial values.
  ///
  /// Sets [AnalysisState.status] to `'idle'` and clears [AnalysisState.result]
  /// and [AnalysisState.errorMessage].
  void reset() {
    _state = const AnalysisState();
    notifyListeners();
  }
}
