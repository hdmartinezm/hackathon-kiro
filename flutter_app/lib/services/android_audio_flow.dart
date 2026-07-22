import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'android_audio_classifier.dart';
import 'confidence_filter.dart';
import '../models/audio_result.dart';
import 'api_service.dart';

/// Orquestador del flujo de audio en Android.
/// Intenta clasificar localmente con YAMNet, si no hay confianza
/// suficiente, envía al backend.
class AndroidAudioFlow {
  final AndroidAudioClassifier _classifier = AndroidAudioClassifier();
  final ConfidenceFilter _filter = ConfidenceFilter();
  final ApiService _apiService = ApiService();

  /// Procesa audio: intenta local primero, fallback a backend.
  Future<AudioResult> process(Uint8List audioBytes) async {
    // Intentar clasificación local
    try {
      final isAvailable = await _classifier.isAvailable();
      if (isAvailable) {
        // Guardar temporalmente para el clasificador nativo
        final dir = await getTemporaryDirectory();
        final tempFile = File('${dir.path}/temp_classify.wav');
        await tempFile.writeAsBytes(audioBytes);

        final localResult = await _classifier.classify(tempFile.path);
        await tempFile.delete();

        if (localResult != null && _filter.isConfident(localResult.confidence)) {
          return localResult;
        }
      }
    } catch (_) {
      // Si falla local, usar backend
    }

    // Fallback: enviar al backend
    return await _apiService.analyzeAudio(audioBytes);
  }
}
