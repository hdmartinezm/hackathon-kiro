# BabyHealth - Plan Refinado

> Asistente de cuidado neonatal con IA multimodal

**Hackathon AWS:** 20-27 julio 2026
**Equipo:** 4 personas

---

## Resumen del Proyecto

App móvil (Flutter) que permite a padres primerizos obtener orientación sobre el estado de salud de su bebé mediante **análisis híbrido multimodal**:

| Modalidad | iOS | Android | Procesamiento |
|-----------|-----|---------|---------------|
| **Imagen** | Claude Vision (Bedrock) | Claude Vision (Bedrock) | Cloud |
| **Audio** | DeepInfant V2 (CoreML) | YAMNet (TFLite) | On-Device |

**Flujo Principal (Imagen):**
1. Usuario toma foto del bebé
2. App sube imagen a S3
3. Lambda invoca Bedrock Vision para análisis
4. Usuario recibe observaciones y recomendaciones

**Flujo Audio iOS (DeepInfant):**
1. Usuario graba 7 segundos de llanto
2. App procesa con DeepInfant CoreML
3. Clasificación en 9 categorías específicas
4. Resultado inmediato + recomendación

**Flujo Audio Android (YAMNet + Bedrock):**
1. Usuario graba 7 segundos de llanto
2. YAMNet detecta si es llanto de bebé (clase 20)
3. Si es llanto → genera espectrograma → Bedrock analiza
4. Resultado con recomendación contextual

---

## Arquitectura Híbrida

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Flutter App (iOS/Android)                         │
├─────────────────────────┬───────────────────────────────────────────────┤
│     IMAGEN (Cloud)      │              AUDIO (On-Device)                │
│     Ambas plataformas   │                                               │
│                         │    ┌─────────────┐      ┌─────────────┐       │
│  1. Captura foto        │    │    iOS      │      │   Android   │       │
│  2. Upload a S3         │    ├─────────────┤      ├─────────────┤       │
│  3. POST /analyze       │    │ DeepInfant  │      │   YAMNet    │       │
│         │               │    │ CoreML V2   │      │   TFLite    │       │
│         ▼               │    │ (89% acc)   │      │ (93% det)   │       │
│  ┌─────────────┐        │    │             │      │      │      │       │
│  │ API Gateway │        │    │ 9 categorías│      │      ▼      │       │
│  └──────┬──────┘        │    │ específicas │      │ ¿Es llanto? │       │
│         │               │    │      │      │      │   Sí → S3   │       │
│         ▼               │    │      ▼      │      │      ↓      │       │
│  ┌─────────────┐        │    │  Resultado  │      │  Bedrock    │       │
│  │   Lambda    │        │    │  inmediato  │      │  (detalle)  │       │
│  │  (FastAPI)  │        │    └─────────────┘      └─────────────┘       │
│  └──────┬──────┘        │                                               │
│         │               │                                               │
│    ┌────┴────┐          │                                               │
│    ▼         ▼          │                                               │
│ ┌─────┐ ┌────────┐      │                                               │
│ │ S3  │ │Bedrock │      │                                               │
│ └─────┘ │ Vision │      │                                               │
│         └────────┘      │                                               │
│         │               │                                               │
│         ▼               │                                               │
│  ┌─────────────┐        │                                               │
│  │  DynamoDB   │        │                                               │
│  └─────────────┘        │                                               │
└─────────────────────────┴───────────────────────────────────────────────┘
```

### Comparativa de Modelos de Audio

| Aspecto | iOS (DeepInfant) | Android (YAMNet) |
|---------|------------------|------------------|
| **Modelo** | DeepInfant V2 CoreML | YAMNet TFLite |
| **Tamaño** | ~50 MB | 3.7 MB |
| **Precisión** | 89% (9 clases) | 93% (detección) |
| **Offline** | ✅ Completo | ✅ Detección |
| **Categorías** | 9 específicas | Detecta → Bedrock |
| **Latencia** | < 1 segundo | < 1s + 2-3s cloud |

### Ventajas del Enfoque Híbrido

| Aspecto | Imagen (Cloud) | Audio iOS | Audio Android |
|---------|----------------|-----------|---------------|
| **Latencia** | 2-5 seg | < 1 seg | 1-4 seg |
| **Offline** | ❌ | ✅ | Parcial |
| **Privacidad** | AWS | Local | Local + Cloud |
| **Costo** | Bedrock | Gratis | Bedrock |
| **Detalle** | Alto | Alto | Alto |

### Servicios AWS

| Servicio | Uso |
|----------|-----|
| **Bedrock** | Análisis multimodal (ver modelos abajo) |
| **Lambda** | Backend FastAPI con mangum |
| **API Gateway** | Endpoint HTTPS público |
| **S3** | Almacenamiento de imágenes/videos (pre-signed URLs) |
| **DynamoDB** | Sesiones y resultados |
| **CloudWatch** | Logs y monitoreo |

### Modelos de Bedrock Disponibles

| Modelo | ID | Capacidades | Uso recomendado |
|--------|-----|-------------|-----------------|
| **Claude Sonnet 4.5** | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` | Texto, Imagen | Análisis detallado de fotos |
| **Claude Haiku 4.5** | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Texto, Imagen | Análisis rápido (menor costo) |
| **Amazon Nova Pro** | `amazon.nova-pro-v1:0` | Texto, Imagen, **Video** | Análisis de video del bebé |

#### Capacidades por modalidad

| Modalidad | Plataforma | Solución | Estado |
|-----------|------------|----------|--------|
| **Imagen** | iOS/Android | Claude Sonnet 4.5 (Bedrock) | ✅ Verificado |
| **Video** | iOS/Android | Amazon Nova Pro (Bedrock) | ✅ Disponible |
| **Audio** | iOS | DeepInfant V2 (CoreML) | ✅ Disponible |
| **Audio** | Android | YAMNet (TFLite) + Bedrock | ✅ Disponible |

#### Datasets de Entrenamiento (Referencia)

| Dataset | Samples | Clases | Uso |
|---------|---------|--------|-----|
| [Donate-a-Cry](https://github.com/gveres/donateacry-corpus) | 457 | 5 | Fine-tuning futuro |
| [Kaggle Features](https://www.kaggle.com/datasets/bhoomikavalani/donateacrycorpusfeaturesdataset) | 457 | 5 | MFCCs extraídos |

---

## DeepInfant - Análisis de Audio On-Device

### Modelo
- **Nombre:** DeepInfant V2
- **Precisión:** 89%
- **Formato:** CoreML (.mlmodel)
- **Fuente:** https://github.com/skytells-research/DeepInfant
- **Licencia:** Apache 2.0 ✓

### Especificaciones de Audio
| Parámetro | Valor |
|-----------|-------|
| Sample rate | 16,000 Hz |
| Duración | 7 segundos |
| Formato | WAV, CAF, 3GP |
| Procesamiento | Mel-spectrogram (80 mels) |

### Categorías de Llanto (9 clases)

| Código | Categoría | Patrón | Recomendación |
|--------|-----------|--------|---------------|
| `hu` | Hambre | Rítmico, repetitivo | Ofrecer alimentación |
| `bu` | Eructo | Corto, entrecortado | Ayudar a eructar |
| `bp` | Dolor abdominal | Agudo, intenso | Masaje suave, consultar médico |
| `dc` | Incomodidad | Intermitente | Revisar pañal, posición |
| `ch` | Temperatura | Quejumbroso | Verificar ropa/ambiente |
| `ti` | Cansancio | Gruñidos | Ambiente tranquilo, dormir |
| `sc` | Miedo | Agudo, repentino | Contacto, consuelo |
| `lo` | Soledad | Baja intensidad | Contacto físico |
| `uk` | Desconocido | Variable | Observar otros signos |

### Integración en Flutter (iOS)

```
flutter_app/
├── ios/
│   └── Runner/
│       └── DeepInfant_V2.mlmodel    # Modelo CoreML
├── lib/
│   └── services/
│       └── cry_analyzer_service.dart # Platform channel
```

### Platform Channel (Dart → Swift)

```dart
// lib/services/cry_analyzer_service.dart
import 'package:flutter/services.dart';

class CryAnalyzerService {
  static const _channel = MethodChannel('com.babyhealth/cry_analyzer');

  /// Analiza audio de llanto y retorna clasificación
  static Future<CryAnalysisResult> analyzeAudio(String audioPath) async {
    final result = await _channel.invokeMethod('analyzeCry', {
      'audioPath': audioPath,
    });
    return CryAnalysisResult.fromJson(result);
  }
}

class CryAnalysisResult {
  final String category;      // hu, bu, bp, dc, etc.
  final String label;         // Hambre, Eructo, etc.
  final double confidence;    // 0.0 - 1.0
  final String recommendation;

  // ... constructor y fromJson
}
```

### Código Swift (iOS Native)

```swift
// ios/Runner/CryAnalyzerPlugin.swift
import Flutter
import CoreML
import AVFoundation

class CryAnalyzerPlugin: NSObject, FlutterPlugin {
    private var model: DeepInfant_V2?

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
        model = try? DeepInfant_V2(configuration: MLModelConfiguration())
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method == "analyzeCry" {
            guard let args = call.arguments as? [String: Any],
                  let audioPath = args["audioPath"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }

            analyzeCry(audioPath: audioPath, completion: result)
        }
    }

    private func analyzeCry(audioPath: String, completion: @escaping FlutterResult) {
        // 1. Cargar audio
        // 2. Convertir a mel-spectrogram
        // 3. Ejecutar modelo
        // 4. Retornar resultado

        // TODO: Implementar procesamiento de audio con librosa-like
        // Por ahora, usar Audio ToolBox de iOS
    }
}
```

### Alternativa: Android (TensorFlow Lite)

Para Android, el modelo CoreML debe convertirse a TensorFlow Lite:

```bash
# Conversión (pre-hackathon si hay tiempo)
coremltools convert DeepInfant_V2.mlmodel --target tensorflow
```

**Nota:** Para el hackathon, priorizar iOS. Android puede usar fallback a Bedrock.

---

## Distribución por Roles

### Hector (Coordinador + Backend)
**Responsabilidades:**
- Coordinar equipo y Trello
- Infraestructura AWS (CDK)
- Backend Python/FastAPI
- Integración con Bedrock
- Lambda y API Gateway
- Preparar demo/pitch

**Tareas principales:**
- [ ] Día 1: Setup CDK + deploy infra base
- [ ] Día 1: Solicitar acceso a Bedrock (CRÍTICO)
- [ ] Día 2: Implementar endpoint /analyze
- [ ] Día 2: Integración Bedrock Vision
- [ ] Día 4: Conectar con Flutter
- [ ] Día 6-7: Demo y pitch

---

### Alvaro (Diseño + Frontend)
**Responsabilidades:**
- Diseño UI/UX de la app
- Mockups y wireframes
- Estilos y tema de la app
- Assets (iconos, logos)
- Ayudar con componentes Flutter

**Tareas principales:**
- [ ] Día 1: Wireframes de las 3 pantallas
- [ ] Día 2: Mockups de alta fidelidad
- [ ] Día 3: Definir tema/colores/tipografía
- [ ] Día 4: Exportar assets
- [ ] Día 5: Pulir UI con Francisco
- [ ] Día 7: Preparar slides de presentación

---

### William (Fullstack)
**Responsabilidades:**
- Integración Frontend ↔ Backend
- Servicios Flutter (API, S3)
- Ayudar con backend si necesario
- Testing end-to-end
- Resolver bloqueos entre equipos

**Tareas principales:**
- [ ] Día 2: Implementar servicios S3 en Flutter
- [ ] Día 3: Implementar servicio API en Flutter
- [ ] Día 4: Integración completa app ↔ backend
- [ ] Día 5: Testing edge cases
- [ ] Día 6: Bugs y optimizaciones

---

### Francisco (Frontend Lead)
**Responsabilidades:**
- Estructura Flutter
- Pantallas principales (Home, Camera, Result)
- Lógica de UI
- Manejo de cámara
- Responsive design

**Tareas principales:**
- [ ] Día 1: Setup proyecto Flutter
- [ ] Día 2: HomeScreen + navegación
- [ ] Día 3: CameraScreen con captura
- [ ] Día 4: ResultScreen con estados
- [ ] Día 5: Polish y animaciones
- [ ] Día 6: Testing en dispositivos

---

## Cronograma Día a Día

### Día 1 (Domingo) - Setup
| Quién | Tarea |
|-------|-------|
| **Hector** | CDK deploy (S3, DynamoDB, Lambda, API Gateway) |
| **Hector** | Solicitar acceso a Bedrock (URGENTE) |
| **Alvaro** | Wireframes de 3 pantallas |
| **William** | Ayudar con setup Flutter si necesario |
| **Francisco** | Setup proyecto Flutter + estructura |

**Entregables:**
- [ ] Infra AWS desplegada
- [ ] Acceso a Bedrock solicitado
- [ ] Proyecto Flutter creado
- [ ] Wireframes listos

---

### Día 2 (Lunes) - Backend + UI Base
| Quién | Tarea |
|-------|-------|
| **Hector** | Backend: /health, /upload-url, S3 service |
| **Hector** | Backend: Bedrock service + /analyze |
| **Alvaro** | Mockups de alta fidelidad |
| **William** | Flutter: api_service.dart, s3_service.dart |
| **Francisco** | Flutter: HomeScreen, DisclaimerWidget |

**Entregables:**
- [ ] Backend funcional con todos los endpoints
- [ ] Mockups aprobados
- [ ] HomeScreen funcionando

---

### Día 3 (Martes) - Flutter Core
| Quién | Tarea |
|-------|-------|
| **Hector** | Probar pipeline completo en AWS |
| **Hector** | Ajustar prompts de Bedrock |
| **Alvaro** | Definir tema Flutter (colores, tipografía) |
| **William** | Integrar servicios con pantallas |
| **Francisco** | CameraScreen con captura de imagen |

**Entregables:**
- [ ] Pipeline imagen→S3→Bedrock funcionando
- [ ] CameraScreen captura fotos
- [ ] Tema visual definido

---

### Día 4 (Miércoles) - Integración
| Quién | Tarea |
|-------|-------|
| **Hector** | Soporte backend, debug |
| **Alvaro** | Exportar assets finales |
| **William** | Conectar CameraScreen → API → ResultScreen |
| **Francisco** | ResultScreen con estados (loading, error, success) |

**Entregables:**
- [ ] Flujo completo end-to-end funcionando
- [ ] App conectada al backend real

---

### Día 5 (Jueves) - Polish + Audio
| Quién | Tarea |
|-------|-------|
| **Hector** | Grabar video de respaldo |
| **Hector** | Integrar DeepInfant CoreML (iOS) |
| **Alvaro** | Pulir UI con Francisco |
| **William** | Testing edge cases + AudioScreen |
| **Francisco** | AudioScreen UI + Animaciones |

**Entregables:**
- [ ] UI pulida
- [ ] Video de demo grabado
- [ ] Casos edge manejados
- [ ] Análisis de audio funcionando (iOS)

---

### Día 6 (Viernes) - Buffer
| Quién | Tarea |
|-------|-------|
| **Hector** | Práctica de pitch |
| **Alvaro** | Preparar slides de arquitectura |
| **William** | Testing final |
| **Francisco** | Bugs menores |

**Entregables:**
- [ ] Pitch ensayado
- [ ] Diagrama de arquitectura listo

---

### Día 7 (Sábado) - Presentación
| Quién | Tarea |
|-------|-------|
| **Todos** | Checklist pre-demo |
| **Hector** | Calentar Lambda 5 min antes |
| **Hector** | Presentar pitch |
| **Todos** | Soporte durante Q&A |

---

## Checklist Día 1 (CRÍTICO)

### Hector
- [ ] `cdk bootstrap` (si es primera vez)
- [ ] `cdk deploy` - verificar outputs
- [ ] Ir a Bedrock console → Request model access → Claude 3.5 Sonnet
- [ ] Crear archivo `.env` con configuración

### Francisco
- [ ] `flutter create flutter_app --org com.babyhealth`
- [ ] Agregar dependencias en pubspec.yaml
- [ ] `flutter pub get`
- [ ] Verificar que compila: `flutter analyze`

### Alvaro
- [ ] Crear wireframes en Figma/papel
- [ ] Compartir en Google Drive

### William
- [ ] Revisar plan de integración
- [ ] Preparar estructura de servicios

---

## Estructura del Proyecto

```
hackathon-kiro/
├── flutter_app/              # App Flutter
│   ├── ios/
│   │   └── Runner/
│   │       ├── DeepInfant_V2.mlmodel  # Modelo CoreML para audio
│   │       └── CryAnalyzerPlugin.swift # Plugin nativo
│   ├── lib/
│   │   ├── config/           # Constantes, configuración
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── camera_screen.dart
│   │   │   ├── audio_screen.dart      # Nueva pantalla de audio
│   │   │   └── result_screen.dart
│   │   ├── services/
│   │   │   ├── api_service.dart
│   │   │   ├── s3_service.dart
│   │   │   └── cry_analyzer_service.dart  # Nuevo servicio audio
│   │   ├── models/
│   │   │   ├── analysis_result.dart
│   │   │   └── cry_analysis_result.dart   # Nuevo modelo
│   │   └── widgets/
│   └── pubspec.yaml
├── backend/                  # Python + FastAPI
│   ├── app/
│   │   ├── routes/
│   │   ├── services/
│   │   │   ├── s3_service.py
│   │   │   ├── bedrock_service.py
│   │   │   └── dynamodb_service.py
│   │   └── models/
│   └── requirements.txt
├── infra/                    # AWS CDK
│   ├── stacks/
│   └── app.py
├── models/                   # Modelos ML (nuevo)
│   └── DeepInfant_V2.mlmodel # Descargar de GitHub
└── docs/
```

---

## Comandos Útiles

```bash
# Backend local
cd backend && source venv/bin/activate && uvicorn app.main:app --reload

# Deploy infra
cd infra && cdk deploy

# Flutter
cd flutter_app && flutter run

# Logs Lambda
aws logs tail /aws/lambda/BabyHealthStack-ApiFunction --follow --profile Sandbox-Hackathon

# Probar Bedrock (imagen)
aws bedrock-runtime invoke-model \
  --model-id us.anthropic.claude-sonnet-4-5-20250929-v1:0 \
  --region us-east-1 \
  --profile Sandbox-Hackathon \
  --content-type application/json \
  --accept application/json \
  --body "$(echo '{"anthropic_version":"bedrock-2023-05-31","max_tokens":100,"messages":[{"role":"user","content":"Hola"}]}' | base64)" \
  /tmp/test.json && cat /tmp/test.json

# Probar Amazon Nova Pro (video)
aws bedrock-runtime invoke-model \
  --model-id amazon.nova-pro-v1:0 \
  --region us-east-1 \
  --profile Sandbox-Hackathon \
  --content-type application/json \
  --accept application/json \
  --body "$(echo '{"messages":[{"role":"user","content":[{"text":"Hola"}]}],"inferenceConfig":{"maxTokens":100}}' | base64)" \
  /tmp/nova-test.json && cat /tmp/nova-test.json
```

---

## Links Importantes

| Recurso | URL |
|---------|-----|
| Bedrock Console | https://us-east-1.console.aws.amazon.com/bedrock |
| CloudWatch | https://us-east-1.console.aws.amazon.com/cloudwatch |
| GitHub | https://github.com/hdmartinezm/hackathon-kiro |
| Trello | https://trello.com/b/sSyhs88y/hackathon-kiro |
| Drive | https://drive.google.com/drive/folders/1DkNVXJSykjKp0vQEu7TzQqcRcU9T9c-9 |
| **DeepInfant** | https://github.com/skytells-research/DeepInfant |
| DeepInfant Models | https://github.com/skytells-research/DeepInfant/tree/main/Models |

---

## Comandos para DeepInfant

```bash
# Clonar repo DeepInfant para obtener modelo
git clone https://github.com/skytells-research/DeepInfant.git /tmp/deepinfant

# Copiar modelo CoreML al proyecto Flutter
cp /tmp/deepinfant/Models/DeepInfant_V2.mlmodel flutter_app/ios/Runner/

# Verificar que el modelo está incluido en Xcode
# 1. Abrir flutter_app/ios/Runner.xcworkspace
# 2. Drag & drop DeepInfant_V2.mlmodel al proyecto
# 3. Asegurar que está en "Copy Bundle Resources"
```
