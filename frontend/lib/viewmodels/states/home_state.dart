import '../../models/captured_media.dart';

/// Immutable state snapshot for the Home screen.
///
/// Tracks navigation and the video capture flow (recording, picking, preview).
class HomeState {
  /// The currently active screen identifier.
  ///
  /// Expected values: `'home'`, `'analysis'`.
  final String currentScreen;

  /// Current capture status.
  ///
  /// Expected values: `'idle'`, `'recording'`, `'captured'`, `'error'`.
  final String captureStatus;

  /// The captured video media, if available.
  final CapturedMedia? media;

  /// Descriptive error message when [captureStatus] is `'error'`.
  final String? errorMessage;

  /// Creates an immutable [HomeState].
  ///
  /// [currentScreen] defaults to `'home'`, [captureStatus] defaults to
  /// `'idle'`. [media] and [errorMessage] are optional.
  const HomeState({
    this.currentScreen = 'home',
    this.captureStatus = 'idle',
    this.media,
    this.errorMessage,
  });

  /// Creates a copy with optionally updated fields.
  HomeState copyWith({
    String? currentScreen,
    String? captureStatus,
    CapturedMedia? media,
    String? errorMessage,
    bool clearMedia = false,
    bool clearError = false,
  }) {
    return HomeState(
      currentScreen: currentScreen ?? this.currentScreen,
      captureStatus: captureStatus ?? this.captureStatus,
      media: clearMedia ? null : (media ?? this.media),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HomeState &&
        other.currentScreen == currentScreen &&
        other.captureStatus == captureStatus &&
        other.media == media &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode =>
      Object.hash(currentScreen, captureStatus, media, errorMessage);
}
