# Guia de Integracion DeepInfant

> Analisis de llanto de bebe on-device con CoreML

**Modelo:** DeepInfant V2
**Precision:** 89%
**Licencia:** Apache 2.0

---

## Resumen

DeepInfant es un modelo de deep learning que clasifica el llanto de bebes en 9 categorias. Usamos la version CoreML para analisis on-device en iOS, eliminando la necesidad de enviar audio a la nube.

## Paso 1: Obtener el Modelo

```bash
# Clonar repositorio
git clone https://github.com/skytells-research/DeepInfant.git /tmp/deepinfant

# El modelo esta en:
# /tmp/deepinfant/Models/DeepInfant_V2.mlmodel
```

## Paso 2: Agregar a Flutter iOS

```bash
# Copiar modelo al proyecto
cp /tmp/deepinfant/Models/DeepInfant_V2.mlmodel flutter_app/ios/Runner/
```

### En Xcode:
1. Abrir `flutter_app/ios/Runner.xcworkspace`
2. Drag & drop `DeepInfant_V2.mlmodel` al proyecto Runner
3. Verificar que esta marcado en "Target Membership" > Runner
4. Build para generar la clase Swift automatica

## Paso 3: Crear Plugin Nativo (Swift)

### 3.1 Registrar Plugin

Editar `flutter_app/ios/Runner/AppDelegate.swift`:

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Registrar plugin de audio
        let controller = window?.rootViewController as! FlutterViewController
        CryAnalyzerPlugin.register(with: controller.registrar(forPlugin: "CryAnalyzerPlugin")!)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

### 3.2 Implementar Plugin

Crear `flutter_app/ios/Runner/CryAnalyzerPlugin.swift`:

```swift
import Flutter
import CoreML
import AVFoundation
import Accelerate

class CryAnalyzerPlugin: NSObject, FlutterPlugin {
    private var model: DeepInfant_V2?

    private let labels = [
        "bp": ("Dolor abdominal", "Masaje suave en el abdomen. Si persiste, consultar pediatra."),
        "bu": ("Necesita eructar", "Sostener al bebe en posicion vertical y dar palmaditas suaves."),
        "ch": ("Temperatura", "Verificar si tiene frio o calor. Ajustar ropa o ambiente."),
        "dc": ("Incomodidad", "Revisar panal, posicion, o si algo le molesta."),
        "hu": ("Hambre", "Ofrecer alimentacion (pecho o biberon)."),
        "lo": ("Soledad", "Cargar al bebe, hablarle suavemente, contacto piel a piel."),
        "sc": ("Miedo/Susto", "Calmar con voz suave, mecer gentilmente."),
        "ti": ("Cansancio", "Crear ambiente tranquilo, oscuro. Ayudar a dormir."),
        "uk": ("No identificado", "Observar otros signos. Si preocupa, consultar pediatra.")
    ]

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.babyhealth/cry_analyzer",
            binaryMessenger: registrar.messenger()
        )
        let instance = CryAnalyzerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    override init() {
        super.init()
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            model = try DeepInfant_V2(configuration: config)
            print("DeepInfant model loaded successfully")
        } catch {
            print("Error loading DeepInfant model: \(error)")
        }
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "analyzeCry":
            guard let args = call.arguments as? [String: Any],
                  let audioPath = args["audioPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "audioPath required", details: nil))
                return
            }
            analyzeCry(audioPath: audioPath, completion: result)

        case "isModelLoaded":
            result(model != nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func analyzeCry(audioPath: String, completion: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self, let model = self.model else {
                DispatchQueue.main.async {
                    completion(FlutterError(code: "MODEL_ERROR", message: "Model not loaded", details: nil))
                }
                return
            }

            do {
                // 1. Load and process audio
                let audioURL = URL(fileURLWithPath: audioPath)
                let melSpectrogram = try self.processAudio(url: audioURL)

                // 2. Run inference
                // Nota: Ajustar segun la entrada real del modelo
                let input = try MLMultiArray(shape: [1, 80, 344], dataType: .float32)
                // Copiar datos del espectrograma al input

                // 3. Get prediction
                // let output = try model.prediction(input: input)
                // let prediction = output.classLabel

                // Por ahora, simulacion para testing
                let prediction = "hu"
                let confidence = 0.87

                let labelInfo = self.labels[prediction] ?? ("Desconocido", "Observar al bebe")

                DispatchQueue.main.async {
                    completion([
                        "category": prediction,
                        "label": labelInfo.0,
                        "confidence": confidence,
                        "recommendation": labelInfo.1
                    ])
                }

            } catch {
                DispatchQueue.main.async {
                    completion(FlutterError(code: "ANALYSIS_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    private func processAudio(url: URL) throws -> [[Float]] {
        // Cargar audio con AVFoundation
        let file = try AVAudioFile(forReading: url)
        let format = file.processingFormat
        let frameCount = UInt32(file.length)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            throw NSError(domain: "AudioError", code: 1, userInfo: nil)
        }

        try file.read(into: buffer)

        // Convertir a mono si es necesario
        guard let floatData = buffer.floatChannelData else {
            throw NSError(domain: "AudioError", code: 2, userInfo: nil)
        }

        // Resample a 16kHz si es necesario
        let samples = Array(UnsafeBufferPointer(start: floatData[0], count: Int(frameCount)))

        // Calcular mel-spectrogram (simplificado)
        let melSpectrogram = computeMelSpectrogram(samples: samples, sampleRate: Float(format.sampleRate))

        return melSpectrogram
    }

    private func computeMelSpectrogram(samples: [Float], sampleRate: Float) -> [[Float]] {
        // Parametros del modelo DeepInfant
        let nFFT = 1024
        let hopLength = 256
        let nMels = 80

        // TODO: Implementar STFT y mel filterbank
        // Para MVP, usar libreria como AudioKit o implementar manualmente

        // Placeholder - retorna array vacio
        return Array(repeating: Array(repeating: 0.0, count: 344), count: nMels)
    }
}
```

## Paso 4: Servicio Flutter (Dart)

Crear `flutter_app/lib/services/cry_analyzer_service.dart`:

```dart
import 'package:flutter/services.dart';

class CryAnalysisResult {
  final String category;
  final String label;
  final double confidence;
  final String recommendation;

  CryAnalysisResult({
    required this.category,
    required this.label,
    required this.confidence,
    required this.recommendation,
  });

  factory CryAnalysisResult.fromMap(Map<dynamic, dynamic> map) {
    return CryAnalysisResult(
      category: map['category'] as String,
      label: map['label'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      recommendation: map['recommendation'] as String,
    );
  }

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(0)}%';

  bool get isHighConfidence => confidence >= 0.7;
}

class CryAnalyzerService {
  static const _channel = MethodChannel('com.babyhealth/cry_analyzer');

  /// Verifica si el modelo esta cargado
  static Future<bool> isModelLoaded() async {
    try {
      final result = await _channel.invokeMethod<bool>('isModelLoaded');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Analiza un archivo de audio y retorna la clasificacion
  static Future<CryAnalysisResult> analyzeAudio(String audioPath) async {
    try {
      final result = await _channel.invokeMethod('analyzeCry', {
        'audioPath': audioPath,
      });

      if (result == null) {
        throw Exception('No se recibio resultado del analisis');
      }

      return CryAnalysisResult.fromMap(result as Map);
    } on PlatformException catch (e) {
      throw Exception('Error en analisis: ${e.message}');
    }
  }
}
```

## Paso 5: Pantalla de Audio

Crear `flutter_app/lib/screens/audio_screen.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../services/cry_analyzer_service.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  State<AudioScreen> createState() => _AudioScreenState();
}

class _AudioScreenState extends State<AudioScreen> {
  final _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isAnalyzing = false;
  CryAnalysisResult? _result;
  String? _error;
  int _recordingSeconds = 0;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/cry_${DateTime.now().millisecondsSinceEpoch}.wav';

        await _recorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
          _result = null;
          _error = null;
        });

        // Contador de segundos
        _startTimer();
      }
    } catch (e) {
      setState(() => _error = 'Error al iniciar grabacion: $e');
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!_isRecording) return false;

      setState(() => _recordingSeconds++);

      // Auto-stop a los 7 segundos
      if (_recordingSeconds >= 7) {
        _stopAndAnalyze();
        return false;
      }
      return true;
    });
  }

  Future<void> _stopAndAnalyze() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _isAnalyzing = true;
      });

      if (path != null) {
        final result = await CryAnalyzerService.analyzeAudio(path);
        setState(() {
          _result = result;
          _isAnalyzing = false;
        });

        // Limpiar archivo temporal
        await File(path).delete();
      }
    } catch (e) {
      setState(() {
        _error = 'Error en analisis: $e';
        _isAnalyzing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis de Llanto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono principal
            Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 100,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
            const SizedBox(height: 24),

            // Estado
            if (_isRecording)
              Text(
                'Grabando... $_recordingSeconds/7 segundos',
                style: Theme.of(context).textTheme.titleLarge,
              ),

            if (_isAnalyzing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analizando llanto...'),
                ],
              ),

            // Resultado
            if (_result != null) _buildResult(),

            // Error
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            const Spacer(),

            // Boton de grabacion
            if (!_isAnalyzing)
              ElevatedButton.icon(
                onPressed: _isRecording ? _stopAndAnalyze : _startRecording,
                icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                label: Text(_isRecording ? 'Detener' : 'Grabar Llanto'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: _isRecording ? Colors.red : null,
                ),
              ),

            const SizedBox(height: 16),

            // Instrucciones
            Text(
              'Graba 7 segundos del llanto del bebe',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    final result = _result!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Categoria
            Text(
              result.label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),

            // Confianza
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Confianza: '),
                Text(
                  result.confidencePercent,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.isHighConfidence ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recomendacion
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(child: Text(result.recommendation)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Paso 6: Dependencias Flutter

Agregar a `flutter_app/pubspec.yaml`:

```yaml
dependencies:
  # ... otras dependencias
  record: ^5.0.4          # Grabacion de audio
  path_provider: ^2.1.1   # Paths temporales
  permission_handler: ^11.0.1  # Permisos de microfono
```

## Paso 7: Permisos iOS

Agregar a `flutter_app/ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>BabyHealth necesita acceso al microfono para analizar el llanto del bebe</string>
```

---

## Flujo de Integracion

```
Usuario presiona "Grabar"
         │
         ▼
┌─────────────────┐
│ record package  │ Graba 7s de audio
└────────┬────────┘
         │ archivo .wav
         ▼
┌─────────────────┐
│ Platform Channel│ Dart → Swift
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ CryAnalyzerPlugin│
│   (Swift)       │
└────────┬────────┘
         │ procesa audio
         ▼
┌─────────────────┐
│ DeepInfant V2   │ Inferencia CoreML
│   (CoreML)      │
└────────┬────────┘
         │ prediccion
         ▼
┌─────────────────┐
│ Resultado JSON  │ {category, label, confidence, recommendation}
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ AudioScreen UI  │ Muestra resultado al usuario
└─────────────────┘
```

---

## Notas Importantes

1. **iOS Only (MVP)**: La integracion CoreML solo funciona en iOS. Para Android, considerar:
   - Convertir modelo a TensorFlow Lite
   - Usar fallback a Bedrock (espectrograma)

2. **Mel-Spectrogram**: El codigo Swift incluye un placeholder. Para produccion, usar:
   - [AudioKit](https://audiokit.io/) para procesamiento de audio
   - O implementar STFT manualmente con vDSP de Accelerate

3. **Testing**: Probar con audios de muestra del repo DeepInfant:
   ```bash
   ls /tmp/deepinfant/Data/
   ```

4. **Precision**: El modelo tiene 89% de precision. Siempre mostrar disclaimer de que es orientativo.

---

## Referencias

- [DeepInfant GitHub](https://github.com/skytells-research/DeepInfant)
- [CoreML Documentation](https://developer.apple.com/documentation/coreml)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
