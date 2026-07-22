import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:path/path.dart' as p;

/// Service responsible for camera initialization, image capture,
/// and basic local validation of captured images.
///
/// Wraps the `camera` plugin to provide a simpler interface
/// for the camera screen.
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  /// Whether the camera has been initialized and is ready to capture.
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// The camera controller for preview rendering.
  CameraController? get controller => _controller;

  /// Initializes the camera with the back-facing lens.
  ///
  /// Falls back to the first available camera if no back camera is found.
  /// Throws [CameraException] if no cameras are available.
  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException('no_cameras', 'No cameras available on this device');
    }

    // Prefer back camera for baby photos
    final camera = _cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await _controller!.initialize();
  }

  /// Captures an image and returns the file path.
  ///
  /// Performs basic local validation:
  /// - Ensures the file exists
  /// - Ensures the file is not empty (minimum 10KB for a valid JPEG)
  ///
  /// Returns the path to the captured image file.
  /// Throws [CameraException] if capture fails or validation doesn't pass.
  Future<String> captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw CameraException('not_initialized', 'Camera not initialized');
    }

    final XFile photo = await _controller!.takePicture();
    final File file = File(photo.path);

    // Basic validation: file exists and has reasonable size
    if (!await file.exists()) {
      throw CameraException('capture_failed', 'Image file was not created');
    }

    final int fileSize = await file.length();
    if (fileSize < 10240) {
      // Less than 10KB is likely corrupt
      throw CameraException(
        'invalid_image',
        'Captured image is too small and may be corrupt',
      );
    }

    return photo.path;
  }

  /// Reads the image bytes from the given file path.
  Future<Uint8List> readImageBytes(String filePath) async {
    final file = File(filePath);
    return await file.readAsBytes();
  }

  /// Determines the MIME type based on file extension.
  ///
  /// Returns "image/jpeg" or "image/png". Defaults to "image/jpeg"
  /// for unknown extensions.
  String getMimeType(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }

  /// Disposes the camera controller and releases resources.
  Future<void> dispose() async {
    await _controller?.dispose();
    _controller = null;
  }
}
