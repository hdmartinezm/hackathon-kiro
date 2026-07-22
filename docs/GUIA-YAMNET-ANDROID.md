# Guia de Integracion YAMNet (Android)

> Deteccion de llanto de bebe con TensorFlow Lite

**Modelo:** YAMNet
**Clases:** 521 (incluye "Baby cry, infant cry")
**Formato:** TensorFlow Lite
**Tamaño:** 3.7 MB

---

## Resumen

YAMNet es un modelo pre-entrenado de Google que clasifica 521 tipos de sonidos. Incluye la clase **"Baby cry, infant cry"** (indice 20) con ~93% de precision.

Para Android usamos YAMNet para **detectar** si el audio es llanto de bebe, y luego enviamos a Bedrock para **clasificar** el tipo de llanto.

## Flujo Android

```
Audio (7s) → YAMNet → ¿Es llanto de bebe?
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
           SI (>70%)                   NO
              │                         │
              ▼                         ▼
        Espectrograma              "No se detecta
              │                    llanto de bebe"
              ▼
         S3 Upload
              │
              ▼
      Bedrock Vision
   (analiza espectrograma)
              │
              ▼
    Categoria + Recomendacion
```

## Paso 1: Agregar Dependencias

### pubspec.yaml

```yaml
dependencies:
  # ... otras dependencias
  tflite_flutter: ^0.10.4
  tflite_flutter_helper: ^0.4.0
  record: ^5.0.4
  path_provider: ^2.1.1
```

## Paso 2: Descargar Modelo

```bash
# Crear carpeta de assets
mkdir -p flutter_app/assets/models

# Descargar YAMNet TFLite
curl -L "https://tfhub.dev/google/lite-model/yamnet/classification/tflite/1?lite-format=tflite" \
  -o flutter_app/assets/models/yamnet.tflite

# Descargar mapa de clases
curl -L "https://raw.githubusercontent.com/tensorflow/models/master/research/audioset/yamnet/yamnet_class_map.csv" \
  -o flutter_app/assets/models/yamnet_class_map.csv
```

### Registrar assets en pubspec.yaml

```yaml
flutter:
  assets:
    - assets/models/yamnet.tflite
    - assets/models/yamnet_class_map.csv
```

## Paso 3: Servicio YAMNet (Dart)

Crear `flutter_app/lib/services/yamnet_service.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';

class YAMNetService {
  static Interpreter? _interpreter;
  static List<String>? _labels;

  // Indice de "Baby cry, infant cry" en YAMNet
  static const int babyCryClassIndex = 20;
  static const double detectionThreshold = 0.7;

  /// Inicializa el modelo (llamar al inicio de la app)
  static Future<void> initialize() async {
    // Cargar modelo
    final modelData = await rootBundle.load('assets/models/yamnet.tflite');
    final buffer = modelData.buffer.asUint8List();

    // Guardar temporalmente para TFLite
    final tempDir = await getTemporaryDirectory();
    final modelFile = File('${tempDir.path}/yamnet.tflite');
    await modelFile.writeAsBytes(buffer);

    _interpreter = await Interpreter.fromFile(modelFile);

    // Cargar labels
    final labelsData = await rootBundle.loadString('assets/models/yamnet_class_map.csv');
    _labels = labelsData
        .split('\n')
        .skip(1) // Skip header
        .map((line) => line.split(',').length > 2 ? line.split(',')[2] : '')
        .toList();
  }

  /// Analiza audio y detecta si es llanto de bebe
  static Future<YAMNetResult> analyzeAudio(String audioPath) async {
    if (_interpreter == null) {
      throw Exception('YAMNet no inicializado. Llama a initialize() primero.');
    }

    // Cargar y procesar audio
    final audioData = await _loadAndProcessAudio(audioPath);

    // Preparar input/output tensors
    // YAMNet espera: [batch, samples] float32
    final input = audioData.reshape([1, audioData.length]);

    // Output: [batch, frames, classes]
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.generate(
      outputShape[1],
      (_) => List.filled(outputShape[2], 0.0)
    );

    // Ejecutar inferencia
    _interpreter!.run(input, output);

    // Buscar deteccion de llanto de bebe
    double maxBabyCryScore = 0.0;
    for (final frame in output) {
      if (frame[babyCryClassIndex] > maxBabyCryScore) {
        maxBabyCryScore = frame[babyCryClassIndex];
      }
    }

    final isBabyCry = maxBabyCryScore >= detectionThreshold;

    return YAMNetResult(
      isBabyCry: isBabyCry,
      confidence: maxBabyCryScore,
      label: isBabyCry ? 'Llanto de bebe detectado' : 'No se detecta llanto',
    );
  }

  static Future<Float32List> _loadAndProcessAudio(String path) async {
    // TODO: Implementar carga de audio con audioplayers o similar
    // YAMNet espera audio a 16kHz, mono, float32

    // Placeholder - en produccion usar paquete de audio
    return Float32List(16000 * 7); // 7 segundos a 16kHz
  }

  static void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }
}

class YAMNetResult {
  final bool isBabyCry;
  final double confidence;
  final String label;

  YAMNetResult({
    required this.isBabyCry,
    required this.confidence,
    required this.label,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
}
```

## Paso 4: Servicio Combinado (YAMNet + Bedrock)

Crear `flutter_app/lib/services/android_cry_service.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'yamnet_service.dart';
import 'api_service.dart';
import 's3_service.dart';

class AndroidCryService {
  /// Analiza llanto en Android: YAMNet local + Bedrock para detalle
  static Future<CryAnalysisResult> analyzeAudio(String audioPath) async {
    // Paso 1: Detectar si es llanto con YAMNet
    final yamnetResult = await YAMNetService.analyzeAudio(audioPath);

    if (!yamnetResult.isBabyCry) {
      return CryAnalysisResult(
        category: 'none',
        label: 'No detectado',
        confidence: yamnetResult.confidence,
        recommendation: 'No se detecta llanto de bebe en el audio. '
            'Intenta grabar cuando el bebe este llorando.',
        source: 'yamnet',
      );
    }

    // Paso 2: Generar espectrograma
    final spectrogramPath = await _generateSpectrogram(audioPath);

    // Paso 3: Subir a S3
    final s3Key = await S3Service.uploadFile(spectrogramPath);

    // Paso 4: Analizar con Bedrock
    final bedrockResult = await ApiService.analyzeAudioSpectrogram(s3Key);

    // Limpiar archivo temporal
    await File(spectrogramPath).delete();

    return CryAnalysisResult(
      category: bedrockResult.category,
      label: bedrockResult.label,
      confidence: yamnetResult.confidence,
      recommendation: bedrockResult.recommendation,
      source: 'bedrock',
    );
  }

  /// Genera espectrograma como imagen PNG
  static Future<String> _generateSpectrogram(String audioPath) async {
    // Cargar audio
    final audioFile = File(audioPath);
    final audioBytes = await audioFile.readAsBytes();

    // TODO: Implementar FFT y mel-spectrogram
    // Por ahora, crear imagen placeholder
    // En produccion usar: fft, just_audio, o llamar a codigo nativo

    final image = img.Image(width: 344, height: 80);
    // Llenar con datos del espectrograma...

    final pngBytes = img.encodePng(image);

    final tempDir = Directory.systemTemp;
    final outputPath = '${tempDir.path}/spectrogram_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(outputPath).writeAsBytes(pngBytes);

    return outputPath;
  }
}

class CryAnalysisResult {
  final String category;
  final String label;
  final double confidence;
  final String recommendation;
  final String source; // 'yamnet', 'bedrock', 'deepinfant'

  CryAnalysisResult({
    required this.category,
    required this.label,
    required this.confidence,
    required this.recommendation,
    required this.source,
  });
}
```

## Paso 5: Servicio Unificado (iOS + Android)

Crear `flutter_app/lib/services/cry_service.dart`:

```dart
import 'dart:io';
import 'cry_analyzer_service.dart'; // iOS - DeepInfant
import 'android_cry_service.dart';  // Android - YAMNet

class CryService {
  /// Analiza llanto usando el modelo apropiado para la plataforma
  static Future<UnifiedCryResult> analyzeAudio(String audioPath) async {
    if (Platform.isIOS) {
      // Usar DeepInfant CoreML
      final result = await CryAnalyzerService.analyzeAudio(audioPath);
      return UnifiedCryResult(
        category: result.category,
        label: result.label,
        confidence: result.confidence,
        recommendation: result.recommendation,
        platform: 'ios',
        model: 'DeepInfant V2',
      );
    } else if (Platform.isAndroid) {
      // Usar YAMNet + Bedrock
      final result = await AndroidCryService.analyzeAudio(audioPath);
      return UnifiedCryResult(
        category: result.category,
        label: result.label,
        confidence: result.confidence,
        recommendation: result.recommendation,
        platform: 'android',
        model: result.source == 'bedrock' ? 'YAMNet + Bedrock' : 'YAMNet',
      );
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }
  }
}

class UnifiedCryResult {
  final String category;
  final String label;
  final double confidence;
  final String recommendation;
  final String platform;
  final String model;

  UnifiedCryResult({
    required this.category,
    required this.label,
    required this.confidence,
    required this.recommendation,
    required this.platform,
    required this.model,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';
  bool get isHighConfidence => confidence >= 0.7;
}
```

## Paso 6: Endpoint Backend para Espectrograma

Agregar a `backend/app/routes/analyze.py`:

```python
@router.post("/analyze-audio")
async def analyze_audio_spectrogram(request: AudioAnalysisRequest):
    """
    Analiza un espectrograma de audio de llanto de bebe.
    Usado por Android cuando YAMNet detecta llanto.
    """
    # Descargar espectrograma de S3
    spectrogram_data = await s3_service.get_object(request.s3_key)

    # Convertir a base64 para Bedrock
    spectrogram_b64 = base64.b64encode(spectrogram_data).decode()

    # Prompt especializado para espectrogramas
    prompt = """Analiza este espectrograma de audio de llanto de bebe.

El espectrograma muestra la frecuencia (eje Y) vs tiempo (eje X).
Los patrones de llanto tienen caracteristicas distintas:
- Hambre: patron ritmico y repetitivo
- Dolor: frecuencias altas sostenidas
- Cansancio: frecuencias bajas, espaciadas
- Incomodidad: patron irregular

Responde en JSON:
{
  "category": "hungry|pain|tired|discomfort|unknown",
  "label": "Nombre en espanol",
  "confidence": 0.0-1.0,
  "recommendation": "Que hacer"
}"""

    # Llamar a Bedrock Vision
    result = await bedrock_service.analyze_image(
        image_b64=spectrogram_b64,
        prompt=prompt
    )

    return result
```

---

## Clases YAMNet Relevantes

| Index | Clase | Uso |
|-------|-------|-----|
| 14 | Baby laughter | Detectar risa |
| 19 | Crying, sobbing | Llanto general |
| **20** | **Baby cry, infant cry** | **Principal** |
| 21 | Whimper | Quejido |
| 22 | Wail, moan | Lamento |

---

## Comparativa iOS vs Android

| Aspecto | iOS (DeepInfant) | Android (YAMNet) |
|---------|------------------|------------------|
| Deteccion | Incluida | YAMNet local |
| Clasificacion | 9 clases locales | Bedrock (cloud) |
| Offline | Completo | Solo deteccion |
| Latencia | < 1 seg | 1-4 seg |
| Precision | 89% | 93% det + Bedrock |

---

## Inicializacion en main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar modelo de audio segun plataforma
  if (Platform.isAndroid) {
    await YAMNetService.initialize();
  }
  // iOS: DeepInfant se carga automaticamente via CoreML

  runApp(const BabyHealthApp());
}
```

---

## Referencias

- [YAMNet TensorFlow Hub](https://www.tensorflow.org/hub/tutorials/yamnet)
- [Transfer Learning with YAMNet](https://www.tensorflow.org/tutorials/audio/transfer_learning_audio)
- [TFLite Flutter](https://pub.dev/packages/tflite_flutter)
- [YAMNet Class Map](https://github.com/tensorflow/models/blob/master/research/audioset/yamnet/yamnet_class_map.csv)
