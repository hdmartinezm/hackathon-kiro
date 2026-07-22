import 'dart:typed_data';
import 'package:camera/camera.dart';

/// Servicio de cámara con captura y validación.
class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];

  /// Inicializa la cámara.
  Future<CameraController> initialize({
    CameraLensDirection preferredDirection = CameraLensDirection.front,
    ResolutionPreset resolution = ResolutionPreset.medium,
  }) async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw Exception('No se encontraron cámaras disponibles');
    }

    final camera = _cameras.firstWhere(
      (c) => c.lensDirection == preferredDirection,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(camera, resolution, enableAudio: false);
    await _controller!.initialize();
    return _controller!;
  }

  /// Captura una foto y retorna bytes.
  Future<Uint8List> capture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      throw Exception('Cámara no inicializada');
    }

    final XFile photo = await _controller!.takePicture();
    final bytes = await photo.readAsBytes();

    // Validar tamaño mínimo
    if (bytes.length < 1000) {
      throw Exception('Imagen capturada es demasiado pequeña');
    }

    return bytes;
  }

  /// Valida que la imagen tenga un tamaño razonable.
  bool validateImage(Uint8List bytes, {int maxSizeMb = 10}) {
    final sizeInMb = bytes.length / (1024 * 1024);
    return sizeInMb <= maxSizeMb && bytes.length > 1000;
  }

  /// Libera recursos.
  void dispose() {
    _controller?.dispose();
  }
}
