import 'package:flutter/services.dart';
import '../models/audio_result.dart';

/// Clasificador de audio Android usando YAMNet via MethodChannel.
class AndroidAudioClassifier {
  static const MethodChannel _channel =
      MethodChannel('com.babyhealth/yamnet_classifier');

  /// Clasifica audio usando YAMNet en Android.
  Future<AudioResult?> classify(String audioPath) async {
    try {
      final result = await _channel.invokeMethod('classifyAudio', {
        'audioPath': audioPath,
      });

      if (result == null) return null;

      return AudioResult(
        category: result['category'] ?? 'desconocido',
        label: result['label'] ?? 'Sin clasificación',
        confidence: (result['confidence'] ?? 0.0).toDouble(),
        recommendation: result['recommendation'] ?? 'Consulte a su pediatra',
      );
    } on PlatformException catch (e) {
      throw Exception('Error en clasificador Android: ${e.message}');
    }
  }

  /// Verifica si el modelo YAMNet está disponible.
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod('isModelAvailable');
      return result == true;
    } catch (_) {
      return false;
    }
  }
}
