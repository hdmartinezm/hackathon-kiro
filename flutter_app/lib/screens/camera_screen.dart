import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/analysis_result.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isProcessing = false;
  String _statusMessage = 'Inicializando cámara...';
  final ApiService _apiService = ApiService();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _statusMessage = 'No se encontraron cámaras disponibles';
        });
        return;
      }

      // Preferir cámara frontal
      final frontCamera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _statusMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error al inicializar cámara: $e';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Capturando y analizando...';
    });

    try {
      final XFile photo = await _cameraController!.takePicture();
      final Uint8List imageBytes = await photo.readAsBytes();

      // Enviar a /analyze-image
      final result = await _apiService.analyzeImageDirect(imageBytes, 'image/jpeg');

      if (mounted) {
        Navigator.pushNamed(context, '/result', arguments: result);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al analizar la imagen: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
      }
    }
  }

  Future<void> _uploadVideo() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Seleccionando video...';
    });

    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (video == null) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
        return;
      }

      setState(() {
        _statusMessage = 'Subiendo video...';
      });

      final Uint8List videoBytes = await video.readAsBytes();
      final String contentType =
          video.path.endsWith('.webm') ? 'video/webm' : 'video/mp4';

      // 1. Obtener URL de upload
      final uploadData = await _apiService.getVideoUploadUrl(contentType);
      final String uploadUrl = uploadData['upload_url'];
      final String videoKey = uploadData['video_key'];

      // 2. Subir a S3
      await _apiService.uploadToS3(uploadUrl, videoBytes, contentType);

      setState(() {
        _statusMessage = 'Analizando video...';
      });

      // 3. Analizar
      final result = await _apiService.analyzeVideo(videoKey);

      if (mounted) {
        Navigator.pushNamed(context, '/result', arguments: result);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al procesar el video: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = '';
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Visual'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitialized
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CameraPreview(_cameraController!),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(_statusMessage),
                      ],
                    ),
                  ),
          ),
          if (_statusMessage.isNotEmpty && _isProcessing)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(_statusMessage),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Upload video button (left)
                FloatingActionButton(
                  heroTag: 'upload',
                  onPressed: _isProcessing ? null : _uploadVideo,
                  backgroundColor: const Color(0xFF9C27B0),
                  child: const Icon(Icons.video_library, color: Colors.white),
                ),
                // Capture button (center)
                FloatingActionButton.large(
                  heroTag: 'capture',
                  onPressed:
                      (_isInitialized && !_isProcessing) ? _capturePhoto : null,
                  backgroundColor: const Color(0xFF6C63FF),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.camera, color: Colors.white, size: 36),
                ),
                // Placeholder for symmetry
                const SizedBox(width: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
