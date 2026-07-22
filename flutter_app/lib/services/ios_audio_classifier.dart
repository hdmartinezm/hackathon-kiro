import 'package:flutter/services.dart';
import '../models/audio_result.dart';

/// Clasificador de audio iOS usando CoreML via MethodChannel.
class IosAudioClassifier {
  static const MethodChannel _channel =
      MethodChannel('com.babyhealth/audio_classifier');

  /// Clasifica audio usando el modelo CoreML de iOS.
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
      throw Exception('Error en clasificador iOS: ${e.message}');
    }
  }

  /// Verifica si el modelo CoreML está disponible.
  Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod('isModelAvailable');
      return result == true;
    } catch (_) {
      return false;
    }
  }
}
