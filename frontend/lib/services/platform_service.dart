import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Abstracts platform detection and capability queries.
///
/// Uses [kIsWeb] from `package:flutter/foundation.dart` to determine
/// the current platform. Does not depend on `dart:io`, making it safe
/// for Web compilation.
class PlatformService {
  /// Whether the app is running on the web.
  bool get isWeb => kIsWeb;

  /// Whether the app is running on Android.
  ///
  /// On Web this always returns `false`. On native platforms, this
  /// approximates Android detection via `defaultTargetPlatform`.
  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether the current platform supports video recording via the camera.
  ///
  /// - Android: `true` (native camera recording works).
  /// - Web: `false` (camera recording for video is not reliably supported).
  bool get hasVideoRecordingSupport => !kIsWeb;
}
