# Documento de Diseño - BabyHealth

## Overview

Este documento describe el diseño técnico de BabyHealth, una aplicación móvil que combina análisis visual (cloud) y análisis de audio (on-device) para orientar a padres primerizos sobre el estado de salud de su bebé. La arquitectura es serverless sobre AWS con procesamiento híbrido cloud/edge.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter App (iOS/Android)              │
├─────────────────┬──────────────────┬────────────────────┤
│  Módulo Cámara  │  Módulo Audio    │  Módulo Resultados │
│  - Captura      │  - Grabación 7s  │  - Semáforo        │
│  - Validación   │  - CoreML (iOS)  │  - Observaciones   │
│  - Upload S3    │  - TFLite (And)  │  - Historial       │
└────────┬────────┴────────┬─────────┴─────────┬──────────┘
         │                 │                   │
         ▼                 ▼                   ▼
┌─────────────────────────────────────────────────────────┐
│              Amazon API Gateway (HTTPS)                   │
│              - Throttling por IP                          │
│              - CORS configurado                           │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│           AWS Lambda (FastAPI + Mangum)                   │
│  ┌──────────┐  ┌───────────┐  ┌──────────────────────┐ │
│  │ /health  │  │/upload-url│  │ /analyze             │ │
│  │          │  │           │  │ /analyze-audio       │ │
│  └──────────┘  └───────────┘  └──────────────────────┘ │
└────────┬───────────────┬───────────────┬────────────────┘
         │               │               │
         ▼               ▼               ▼
┌──────────────┐  ┌───────────┐  ┌───────────────┐
│ Amazon S3    │  │  Bedrock  │  │  DynamoDB     │
│ (imágenes)   │  │  Claude   │  │ (resultados)  │
│ TTL: 24h     │  │  Sonnet   │  │               │
└──────────────┘  └───────────┘  └───────────────┘
```

## Components and Interfaces

### 1. Backend API (FastAPI + Lambda)

**Tecnología:** Python 3.11, FastAPI, Mangum (adaptador Lambda)
**Despliegue:** AWS Lambda detrás de API Gateway

#### Estructura de Módulos

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app + Mangum handler
│   ├── config.py            # Configuración y variables de entorno
│   ├── models/
│   │   ├── __init__.py
│   │   ├── requests.py      # Modelos Pydantic de request
│   │   └── responses.py     # Modelos Pydantic de response
│   ├── routers/
│   │   ├── __init__.py
│   │   ├── health.py        # GET /health
│   │   ├── upload.py        # POST /upload-url
│   │   ├── analyze.py       # POST /analyze
│   │   └── audio.py         # POST /analyze-audio
│   ├── services/
│   │   ├── __init__.py
│   │   ├── s3_service.py    # Interacción con S3
│   │   ├── bedrock_service.py  # Interacción con Bedrock
│   │   └── dynamo_service.py   # Interacción con DynamoDB
│   └── utils/
│       ├── __init__.py
│       ├── retry.py         # Lógica de reintentos
│       └── validators.py    # Validaciones comunes
├── tests/
│   ├── __init__.py
│   ├── test_health.py
│   ├── test_upload.py
│   ├── test_analyze.py
│   └── test_audio.py
├── requirements.txt
└── lambda_handler.py        # Entry point para Lambda
```

### 2. Servicio S3 (Almacén de Imágenes)

**Configuración:**
- Bucket con políticas de acceso privado (sin acceso público)
- Lifecycle rule: eliminar objetos después de 24 horas
- Pre-signed URLs con expiración de 300 segundos
- Carpeta por sesión: `sessions/{session_id}/{filename}`

**Flujo de Upload:**
1. App solicita URL pre-firmada → Backend genera con boto3
2. App sube imagen directamente a S3 usando la URL
3. App envía s3_key al endpoint /analyze

### 3. Servicio Bedrock (Análisis Visual)

**Modelo:** `us.anthropic.claude-sonnet-4-5-20250929-v1:0`
**Región:** us-east-1
**Alternativa rápida:** `us.anthropic.claude-haiku-4-5-20251001-v1:0`

**Prompt del Sistema:**
```
Eres un asistente de orientación para padres. Analiza esta imagen de un bebé.

Evalúa:
- Coloración de piel (busca tonos amarillentos que podrían indicar ictericia)
- Expresión facial (signos de malestar o tranquilidad)
- Estado general visible

Responde SOLO en JSON válido con este formato exacto:
{
  "estado_general": "normal | requiere_atencion | urgente",
  "observaciones": ["observación 1", "observación 2"],
  "recomendaciones": ["recomendación 1", "recomendación 2"],
  "confianza": 0.87
}

Reglas:
- Si la imagen no es clara o no muestra un bebé, indica error de calidad
- Siempre incluye al menos una recomendación
- El valor de confianza refleja tu certeza (0.0-1.0)
- Si detectas posible ictericia, estado_general debe ser "requiere_atencion" o "urgente"
```

**Validación de Calidad:**
Bedrock evalúa calidad de imagen como primer paso. Si detecta problemas:
```json
{
  "error": "calidad_insuficiente",
  "mensaje": "La imagen no es lo suficientemente clara para un análisis confiable",
  "sugerencias": ["Mejore la iluminación", "Enfoque la cámara", "Centre el rostro del bebé"]
}
```

### 4. Servicio DynamoDB (Almacén de Resultados)

**Tabla:** `babyhealth-results`

| Atributo | Tipo | Descripción |
|----------|------|-------------|
| session_id (PK) | String (UUID) | Identificador de sesión |
| timestamp (SK) | String (ISO 8601) | Momento del análisis |
| analysis_type | String | "visual" o "audio" |
| result | Map | Resultado completo del análisis |
| created_at | String (ISO 8601) | Timestamp de creación |

### 5. Módulo Audio iOS (DeepInfant CoreML)

**Modelo:** DeepInfant V2
**Framework:** CoreML
**Capacidad offline:** Completa

**Flujo:**
1. Grabar 7 segundos de audio (AVAudioRecorder)
2. Convertir a espectrograma (vDSP/Accelerate framework)
3. Ejecutar inferencia con CoreML
4. Mapear salida a categoría de llanto
5. Eliminar buffer de audio inmediatamente

**Categorías de salida:**
| ID | Category | Label (ES) | Recomendación |
|----|----------|------------|---------------|
| 0 | hungry | Hambre | Ofrecer alimentación |
| 1 | pain | Dolor | Revisar, consultar si persiste |
| 2 | fatigue | Cansancio | Ambiente tranquilo, dormir |
| 3 | discomfort | Incomodidad | Revisar pañal, posición, ropa |
| 4 | burp | Eructo | Sostener vertical, palmaditas |
| 5 | temperature | Temperatura | Verificar si tiene frío/calor |
| 6 | fear | Miedo | Contacto, voz suave, mecer |
| 7 | loneliness | Soledad | Contacto físico, presencia |
| 8 | unknown | Desconocido | Intentar de nuevo en ambiente silencioso |

**Umbral de confianza:** Si confidence < 0.5 → categoría "unknown"

### 6. Módulo Audio Android (YAMNet + Bedrock)

**Detección local:** YAMNet TFLite
**Clasificación cloud:** Bedrock Claude

**Flujo:**
1. Grabar 7 segundos de audio
2. YAMNet detecta si es llanto de bebé (on-device)
3. Si no es llanto → retornar "No se detecta llanto de bebé"
4. Si es llanto → generar espectrograma
5. Subir espectrograma a S3
6. Llamar POST /analyze-audio con s3_key
7. Retornar resultado de clasificación

### 7. Flutter App (Frontend)

**Estructura de pantallas:**

```
lib/
├── main.dart
├── config/
│   └── app_config.dart       # URLs, constantes
├── models/
│   ├── analysis_result.dart  # Modelo de resultado visual
│   └── audio_result.dart     # Modelo de resultado audio
├── screens/
│   ├── splash_screen.dart    # Disclaimer + animación
│   ├── home_screen.dart      # Selección: foto o audio
│   ├── camera_screen.dart    # Captura de imagen
│   ├── audio_screen.dart     # Grabación de audio
│   ├── result_screen.dart    # Resultado visual (semáforo)
│   └── audio_result_screen.dart  # Resultado audio
├── services/
│   ├── api_service.dart      # Comunicación con backend
│   ├── audio_service.dart    # Grabación y clasificación
│   └── camera_service.dart   # Captura y upload
└── widgets/
    ├── disclaimer_widget.dart    # Widget reutilizable de disclaimer
    ├── traffic_light_widget.dart # Indicador semáforo
    └── confidence_bar.dart       # Barra de confianza
```

**Navegación:**
```
Splash (disclaimer) → Home → [Cámara | Audio] → Resultado
                                                     ↓
                                              [Nuevo Análisis]
                                              [Contactar Pediatra]
```

## Data Models

### Request: Upload URL
```python
class UploadUrlRequest(BaseModel):
    file_type: Literal["image/jpeg", "image/png"]
    session_id: UUID
```

### Request: Analyze
```python
class AnalyzeRequest(BaseModel):
    s3_key: str
    session_id: UUID
```

### Request: Analyze Audio
```python
class AnalyzeAudioRequest(BaseModel):
    s3_key: str
```

### Response: Upload URL
```python
class UploadUrlResponse(BaseModel):
    upload_url: str
    s3_key: str
    expires_in: int = 300
```

### Response: Analyze (Visual)
```python
class AnalyzeResponse(BaseModel):
    session_id: UUID
    estado_general: Literal["normal", "requiere_atencion", "urgente"]
    observaciones: list[str]
    recomendaciones: list[str]
    confianza: float  # 0.0 - 1.0
    disclaimer: str = "Consulte a su pediatra"
    timestamp: datetime
```

### Response: Analyze Audio
```python
class AudioAnalysisResponse(BaseModel):
    category: str
    label: str
    confidence: float
    recommendation: str
```

### DynamoDB Schema

**Tabla:** `babyhealth-results`

| Atributo | Tipo | Descripción |
|----------|------|-------------|
| session_id (PK) | String (UUID) | Identificador de sesión |
| timestamp (SK) | String (ISO 8601) | Momento del análisis |
| analysis_type | String | "visual" o "audio" |
| result | Map | Resultado completo del análisis |
| created_at | String (ISO 8601) | Timestamp de creación |

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Integridad de respuesta visual

*For any* imagen válida analizada, la respuesta DEBE contener exactamente los campos: estado_general, observaciones, recomendaciones, confianza, disclaimer, timestamp. Además, estado_general DEBE ser uno de: "normal", "requiere_atencion", "urgente", y confianza DEBE estar en el rango [0.0, 1.0].

**Validates: Requirements 1.1, 1.2**

### Property 2: Consistencia de clasificación de audio

*For any* audio clasificado, la categoría DEBE ser una de las 9 categorías de llanto definidas. Si confidence < umbral → categoría DEBE ser "unknown". El label DEBE corresponder exactamente a la categoría en la tabla de mapeo.

**Validates: Requirements 2.1, 2.2**

### Property 3: Idempotencia de URL pre-firmada

*For any* sesión y tipo de archivo, generar múltiples URLs pre-firmadas DEBE producir URLs válidas independientes. Cada URL generada DEBE expirar exactamente después de 300 segundos.

**Validates: Requirements 3.1**

### Property 4: Persistencia de resultados (round-trip)

*For any* resultado almacenado en DynamoDB, DEBE ser recuperable por session_id. El orden de resultados por timestamp DEBE ser determinista y descendente.

**Validates: Requirements 4.1**

### Property 5: Aislamiento de audio iOS

*For any* inferencia de audio en iOS, el buffer de audio DEBE ser eliminado inmediatamente después de la inferencia CoreML. Ningún dato de audio DEBE persistir en disco o transmitirse por red.

**Validates: Requirements 5.1**

### Property 6: Presencia obligatoria de disclaimer

*For any* respuesta de análisis visual, DEBE contener el campo disclaimer no vacío. La UI DEBE renderizar el disclaimer en splash, home footer, y cada pantalla de resultado.

**Validates: Requirements 6.1**

### Property 7: Round-trip de modelos de datos

*For any* AnalyzeResponse válido, serializar y deserializar DEBE producir un objeto equivalente al original. Lo mismo aplica para AudioAnalysisResponse.

**Validates: Requirements 1.1, 2.1**

## Error Handling

### Lógica de Reintentos (Bedrock)

```
Intento 1 → timeout 10s → espera 1s
Intento 2 → timeout 10s → espera 2s
Intento 3 → timeout 10s → error amigable
```

### Validación de Calidad de Imagen

Bedrock evalúa calidad de imagen como primer paso. Si detecta problemas:
```json
{
  "error": "calidad_insuficiente",
  "mensaje": "La imagen no es lo suficientemente clara para un análisis confiable",
  "sugerencias": ["Mejore la iluminación", "Enfoque la cámara", "Centre el rostro del bebé"]
}
```

### Umbral de Confianza Audio

Si confidence < 0.5 → categoría "unknown" con mensaje: "Intentar de nuevo en ambiente silencioso"

### Errores de Red y Timeout

- Si la conexión falla, la app muestra un mensaje amigable y permite reintentar
- Los uploads a S3 con URL pre-firmada expirada retornan error 403 → la app solicita nueva URL
- Timeout en Bedrock se maneja con la lógica de reintentos descrita arriba

## Testing Strategy

### Enfoque Dual de Testing

**Unit Tests:** Verifican ejemplos específicos, edge cases y condiciones de error.
**Property Tests:** Verifican propiedades universales a través de todos los inputs.

### Property-Based Testing

**Librería:** Hypothesis (Python)
**Configuración:** Mínimo 100 iteraciones por property test.
**Tag format:** `Feature: babyhealth-app, Property {number}: {property_text}`

Los property tests cubren:
- Serialización round-trip de modelos (Property 7)
- Validación de respuestas (Property 1, Property 2)
- Generación de URLs pre-firmadas (Property 3)
- Consistencia de clasificación de audio (Property 2)

### Unit Tests

- Test de endpoints con mocks de servicios AWS
- Test de validación de requests con payloads inválidos
- Test de flujo de audio con señales simuladas
- Test de integración con LocalStack para S3 y DynamoDB

### Integration Tests

- Test end-to-end del flujo de upload → análisis → resultado
- Test de expiración de URLs pre-firmadas
- Test de lifecycle rules en S3

## Decisiones de Diseño

### D1: Procesamiento híbrido (cloud/edge)
- **Decisión:** Audio en dispositivo, imagen en la nube
- **Justificación:** Audio requiere baja latencia y máxima privacidad. Imagen requiere Claude Vision que solo está en la nube.

### D2: URLs pre-firmadas para upload
- **Decisión:** La app sube directamente a S3 sin pasar por Lambda
- **Justificación:** Evita timeout de Lambda por uploads grandes, reduce carga del backend.

### D3: Mangum como adaptador
- **Decisión:** Usar Mangum para ejecutar FastAPI en Lambda
- **Justificación:** Permite desarrollo local con uvicorn y despliegue en Lambda sin cambios de código.

### D4: Retry con backoff exponencial
- **Decisión:** 3 intentos con espera 1s, 2s para Bedrock
- **Justificación:** Bedrock puede tener latencia variable; reintentos mejoran resiliencia sin saturar el servicio.

### D5: TTL de 24 horas en S3
- **Decisión:** Las imágenes se eliminan automáticamente después de 24 horas
- **Justificación:** Minimiza almacenamiento de datos sensibles (fotos de bebés) mientras permite re-análisis inmediato.
