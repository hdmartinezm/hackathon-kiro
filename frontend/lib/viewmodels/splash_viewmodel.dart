import 'package:flutter/foundation.dart';

import 'states/splash_state.dart';

/// ViewModel for the Splash screen.
///
/// Manages the medical disclaimer acceptance state. No external dependencies
/// are required since the disclaimer state is purely local.
class SplashViewModel extends ChangeNotifier {
  SplashState _state = const SplashState();

  /// The current immutable state snapshot.
  SplashState get state => _state;

  /// Accepts the medical disclaimer.
  ///
  /// Updates [SplashState.disclaimerAccepted] to `true` and notifies listeners.
  void acceptDisclaimer() {
    _state = _state.copyWith(disclaimerAccepted: true);
    notifyListeners();
  }
}
