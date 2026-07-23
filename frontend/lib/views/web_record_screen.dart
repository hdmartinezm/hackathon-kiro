import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/captured_media.dart';

/// Full-screen camera recorder for the web version.
///
/// Uses the `camera` plugin (backed by the browser MediaRecorder API on web)
/// to record a short video with audio. On completion it returns a
/// [CapturedMedia] via `Navigator.pop`, or `null` if the user cancels.
class WebRecordScreen extends StatefulWidget {
  const WebRecordScreen({super.key});

  @override
  State<WebRecordScreen> createState() => _WebRecordScreenState();
}

class _WebRecordScreenState extends State<WebRecordScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  bool _isRecording = false;
  bool _isProcessing = false;
  String? _error;

  // Elapsed recording time.
  Timer? _timer;
  int _seconds = 0;

  // Safety cap so recordings don't grow unbounded.
  static const int _maxSeconds = 30;

  @override
  void initState() {
    super.initState();
    _initFuture = _setupCamera();
  }

  Future<void> _setupCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error =
            'No se encontró ninguna cámara disponible en este dispositivo.');
        return;
      }

      // Prefer the front camera (better for showing the baby to the parent),
      // otherwise fall back to the first available camera.
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error =
          'No se pudo acceder a la cámara. Concede permisos de cámara y '
          'micrófono en el navegador e inténtalo de nuevo.\n\nDetalle: $e');
    }
  }

  Future<void> _startRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      await controller.startVideoRecording();
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _seconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _seconds++);
        if (_seconds >= _maxSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Error al iniciar la grabación: $e');
    }
  }

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_isRecording) return;

    _timer?.cancel();
    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    try {
      final xFile = await controller.stopVideoRecording();
      final bytes = await xFile.readAsBytes();

      // On web the container is typically WebM. MediaRecorder reports a MIME
      // type with codec parameters (e.g. 'video/webm;codecs="vp9,opus"'), but
      // the backend only accepts base types, so strip everything after ';'.
      final rawMime = xFile.mimeType ?? 'video/webm';
      final baseMime = rawMime.split(';').first.trim().toLowerCase();
      final mimeType =
          baseMime.startsWith('video/') ? baseMime : 'video/webm';
      final ext = mimeType.contains('mp4') ? 'mp4' : 'webm';
      final fileName =
          'grabacion_${DateTime.now().millisecondsSinceEpoch}.$ext';

      if (!mounted) return;
      Navigator.of(context).pop(
        CapturedMedia(
          bytes: bytes,
          fileName: fileName,
          mimeType: mimeType,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _error = 'Error al finalizar la grabación: $e';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Grabar video'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _error != null
          ? _buildError()
          : FutureBuilder<void>(
              future: _initFuture,
              builder: (context, snapshot) {
                final controller = _controller;
                if (controller == null || !controller.value.isInitialized) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }
                return _buildCamera(controller);
              },
            ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off_rounded,
                color: Colors.white70, size: 56),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCamera(CameraController controller) {
    return Stack(
      children: [
        // Camera preview centered.
        Center(
          child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller),
          ),
        ),

        // Recording timer badge.
        if (_isRecording)
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE87055),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(_seconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bottom controls.
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Center(
            child: _isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : GestureDetector(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isRecording ? 30 : 60,
                          height: _isRecording ? 30 : 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE87055),
                            borderRadius: BorderRadius.circular(
                                _isRecording ? 8 : 40),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),

        // Hint text.
        if (!_isRecording && !_isProcessing)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 130,
            child: Center(
              child: Text(
                'Toca para grabar (máx. 30s)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
      ],
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
