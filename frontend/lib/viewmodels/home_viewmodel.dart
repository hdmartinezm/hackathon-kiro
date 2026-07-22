import 'package:flutter/foundation.dart';

import '../repositories/capture_repository.dart';
import 'states/home_state.dart';

/// ViewModel for the Home screen.
///
/// Manages navigation and the video capture flow (recording and file picking).
/// Delegates capture operations to [CaptureRepository].
class HomeViewModel extends ChangeNotifier {
  final CaptureRepository _captureRepository;

  HomeState _state = const HomeState();

  /// The current immutable state snapshot.
  HomeState get state => _state;

  /// Creates a [HomeViewModel] with the required [CaptureRepository].
  HomeViewModel({required CaptureRepository captureRepository})
      : _captureRepository = captureRepository;

  /// Starts video recording via the device camera.
  ///
  /// Transitions [HomeState.captureStatus] to `'recording'`, calls
  /// [CaptureRepository.recordVideo], and updates [HomeState.media] on success.
  /// On failure, sets status to `'error'` with a descriptive message.
  Future<void> recordVideo() async {
    _state = _state.copyWith(captureStatus: 'recording', clearError: true);
    notifyListeners();

    try {
      final media = await _captureRepository.recordVideo();
      _state = _state.copyWith(captureStatus: 'captured', media: media);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        captureStatus: 'error',
        errorMessage: 'Error recording video: $e',
      );
      notifyListeners();
    }
  }

  /// Picks an existing video from the device gallery.
  ///
  /// Calls [CaptureRepository.pickVideo] and updates [HomeState.media] on
  /// success. On failure, sets status to `'error'` with a descriptive message.
  Future<void> pickVideo() async {
    _state = _state.copyWith(captureStatus: 'idle', clearError: true);
    notifyListeners();

    try {
      final media = await _captureRepository.pickVideo();
      _state = _state.copyWith(captureStatus: 'captured', media: media);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        captureStatus: 'error',
        errorMessage: 'Error picking video: $e',
      );
      notifyListeners();
    }
  }

  /// Resets the capture state to its initial values.
  ///
  /// Sets [HomeState.captureStatus] to `'idle'` and clears [HomeState.media]
  /// and [HomeState.errorMessage].
  void resetCapture() {
    _state = const HomeState();
    notifyListeners();
  }

  /// Navigates to the analysis screen.
  ///
  /// Updates [HomeState.currentScreen] to `'analysis'` and notifies listeners.
  void navigateToAnalysis() {
    _state = _state.copyWith(currentScreen: 'analysis');
    notifyListeners();
  }

  /// Navigates back to the home screen.
  ///
  /// Updates [HomeState.currentScreen] to `'home'` and notifies listeners.
  void navigateToHome() {
    _state = _state.copyWith(currentScreen: 'home');
    notifyListeners();
  }
}
