/// Immutable state snapshot for the Splash screen.
///
/// Tracks whether the user has accepted the medical disclaimer.
class SplashState {
  /// Whether the user has accepted the medical disclaimer.
  final bool disclaimerAccepted;

  /// Creates an immutable [SplashState] with [disclaimerAccepted] defaulting
  /// to `false`.
  const SplashState({this.disclaimerAccepted = false});

  /// Creates a copy with optionally updated fields.
  SplashState copyWith({bool? disclaimerAccepted}) {
    return SplashState(
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SplashState && other.disclaimerAccepted == disclaimerAccepted;
  }

  @override
  int get hashCode => disclaimerAccepted.hashCode;
}
