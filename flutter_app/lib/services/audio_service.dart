import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File, Platform;
import '../config/app_config.dart';
import '../models/audio_result.dart';
import 'api_service.dart';

/// Servicio de grabación de audio (7 segundos).
class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final ApiService _apiService = ApiService();
  String? _recordingPath;

  /// Inicia grabación de audio.
  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Permiso de micrófono denegado');
    }

    if (kIsWeb) {
      // Web: grabar en memoria
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: '',
      );
    } else {
      // Móvil: grabar a archivo
      final dir = await getTemporaryDirectory();
      _recordingPath = '${dir.path}/baby_cry_recording.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );
    }
  }

  /// Detiene grabación y retorna bytes.
  Future<Uint8List?> stopRecording() async {
    final path = await _recorder.stop();

    if (kIsWeb) {
      // En web, path contiene la URL del blob
      if (path == null) return null;
      // No se puede leer directamente en web desde path
      return null;
    } else {
      if (path == null && _recordingPath == null) return null;
      final filePath = path ?? _recordingPath!;
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        // Limpiar archivo temporal
        await file.delete();
        return bytes;
      }
      return null;
    }
  }

  /// Analiza audio grabado.
  Future<AudioResult> analyzeAudio(Uint8List audioBytes) async {
    return await _apiService.analyzeAudio(audioBytes);
  }

  /// Libera recursos.
  void dispose() {
    _recorder.dispose();
  }
}
