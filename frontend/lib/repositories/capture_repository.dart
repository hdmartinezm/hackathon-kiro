import 'package:flutter/services.dart';

import '../models/captured_media.dart';
import '../services/video_capture_service.dart';

/// Abstracts [VideoCaptureService] behind a repository boundary.
///
/// Delegates recording and file-picking to the injected service.
/// Handles user cancellation by catching [PlatformException] and
/// rethrowing a descriptive error.
class CaptureRepository {
  final VideoCaptureService _videoCaptureService;

  CaptureRepository({required VideoCaptureService videoCaptureService})
      : _videoCaptureService = videoCaptureService;

  /// Records a video using the device camera.
  ///
  /// Delegates to [VideoCaptureService.recordVideo].
  /// Throws [UnsupportedError] if the platform does not support recording.
  /// Throws [Exception] if the user cancels or recording fails.
  Future<CapturedMedia> recordVideo() async {
    try {
      return await _videoCaptureService.recordVideo();
    } on PlatformException catch (e) {
      throw Exception('Video recording failed: ${e.message}');
    }
  }

  /// Picks an existing video from the device gallery.
  ///
  /// Delegates to [VideoCaptureService.pickVideo].
  /// Throws [Exception] if the user cancels or selection fails.
  Future<CapturedMedia> pickVideo() async {
    try {
      return await _videoCaptureService.pickVideo();
    } on PlatformException catch (e) {
      throw Exception('Video selection failed: ${e.message}');
    }
  }
}
