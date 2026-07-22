import 'package:image_picker/image_picker.dart';

import '../models/captured_media.dart';
import 'platform_service.dart';

/// Abstract interface for video capture operations.
///
/// Implementations handle platform-specific recording and file selection,
/// returning [CapturedMedia] with the correct MIME type for each platform.
abstract class VideoCaptureService {
  /// Records a video using the device camera.
  ///
  /// Throws [UnsupportedError] if the platform does not support recording.
  /// Throws an [Exception] if the user cancels or recording fails.
  Future<CapturedMedia> recordVideo();

  /// Picks an existing video from the device gallery.
  ///
  /// Throws an [Exception] if the user cancels or selection fails.
  Future<CapturedMedia> pickVideo();
}

/// Implementation of [VideoCaptureService] using `image_picker`.
///
/// Uses [ImagePicker.pickVideo] for both recording (camera source) and
/// selection (gallery source). On platforms without recording support
/// (e.g. Web), [recordVideo] throws [UnsupportedError] and the caller
/// should fall back to [pickVideo].
class ImagePickerVideoCaptureService implements VideoCaptureService {
  final ImagePicker _picker;
  final PlatformService _platformService;

  ImagePickerVideoCaptureService({
    required PlatformService platformService,
    ImagePicker? picker,
  })  : _platformService = platformService,
        _picker = picker ?? ImagePicker();

  @override
  Future<CapturedMedia> recordVideo() async {
    if (!_platformService.hasVideoRecordingSupport) {
      throw UnsupportedError(
        'La grabación de video no está disponible en la versión web. '
        'Por favor, selecciona un video existente usando el botón "Seleccionar Video".',
      );
    }

    final xFile = await _picker.pickVideo(source: ImageSource.camera);
    if (xFile == null) {
      throw Exception('Video recording was cancelled by the user.');
    }

    return _xFileToCapturedMedia(xFile);
  }

  @override
  Future<CapturedMedia> pickVideo() async {
    try {
      final xFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (xFile == null) {
        throw Exception('Selección de video cancelada por el usuario.');
      }

      return _xFileToCapturedMedia(xFile);
    } catch (e) {
      if (_platformService.isWeb) {
        throw Exception(
          'Error al seleccionar el video en la versión web. '
          'Asegúrate de que el navegador tenga permisos para acceder a archivos. '
          'Error: $e',
        );
      }
      rethrow;
    }
  }

  /// Converts an [XFile] from image_picker into a [CapturedMedia].
  Future<CapturedMedia> _xFileToCapturedMedia(XFile xFile) async {
    final bytes = await xFile.readAsBytes();
    final mimeType = xFile.mimeType ?? _mimeTypeFromExtension(xFile.name);

    // Validación de MIME para Web
    if (_platformService.isWeb && !mimeType.startsWith('video/')) {
      throw Exception(
        'El archivo seleccionado no es un video válido. '
        'Por favor, selecciona un archivo de video (MP4, WebM, etc.).',
      );
    }

    return CapturedMedia(
      bytes: bytes,
      fileName: xFile.name,
      mimeType: mimeType,
    );
  }

  /// Derives a MIME type from the file extension as fallback.
  static String _mimeTypeFromExtension(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/avi';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'video/mp4';
    }
  }
}
