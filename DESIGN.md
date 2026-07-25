# DESIGN.md — BabyHealth

## Resumen Ejecutivo

BabyHealth es una aplicación de orientación para padres primerizos que utiliza inteligencia artificial multimodal para analizar videos e imágenes de bebés y proporcionar recomendaciones sobre su estado de salud. La arquitectura es completamente serverless sobre AWS, con un frontend Flutter Web y soporte dual de modelos de IA (AWS Bedrock Claude y Google Gemini).

**URL de producción:** https://babyhealth.hmartinez.info

---

## Arquitectura General

```
┌──────────────────────────────────────────────────────────────────────────┐
│                          Flutter Web App                                  │
│   Provider (MVVM) · Amplify Auth · i18n (ES/EN) · Dark/Light Theme       │
└──────────────────────────────────┬───────────────────────────────────────┘
                                   │ HTTPS
                                   ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                          CloudFront CDN                                   │
│                     babyhealth.hmartinez.info                             │
└────────────────┬─────────────────────────────────────┬───────────────────┘
                 │                                     │
                 ▼                                     ▼
┌────────────────────────────┐          ┌──────────────────────────────────┐
│       S3 (Frontend)        │          │        API Gateway HTTP API       │
│   Static files (SPA)       │          │  JWT Auth (Cognito Authorizer)    │
└────────────────────────────┘          └───────────────┬──────────────────┘
                                                        │
                                                        ▼
                                        ┌──────────────────────────────────┐
                                        │        AWS Lambda                │
                                        │   FastAPI + Mangum (Python 3.11) │
                                        │   1024 MB · 60s timeout          │
                                        └───────────────┬──────────────────┘
                                                        │
                          ┌─────────────────────────────┼──────────────────┐
                          ▼                             ▼                   ▼
                ┌──────────────────┐        ┌────────────────┐   ┌─────────────────┐
                │   AWS Bedrock    │        │ Google Gemini  │   │   S3 (Videos)   │
                │ Claude Sonnet 4.5│        │   2.5 Flash    │   │  TTL 24 horas   │
                └──────────────────┘        └────────────────┘   └─────────────────┘
                          │                                               │
                          ▼                                               │
                ┌──────────────────┐                                      │
                │    DynamoDB      │◄─────────────────────────────────────┘
                │   (Resultados)   │
                └──────────────────┘

                ┌──────────────────┐
                │   AWS Cognito    │
                │ Google · Facebook│
                │  Email/Password  │
                └──────────────────┘
```

---

## Stack Tecnológico

| Capa | Tecnología | Versión / Detalle |
|------|-----------|-------------------|
| Frontend | Flutter Web (Dart) | SDK ^3.12.2 |
| Estado | Provider | ^6.1.2 (MVVM) |
| Autenticación | AWS Amplify + Cognito | ^2.0.0 |
| Backend | FastAPI (Python) | 3.11 + Mangum |
| IA Principal | AWS Bedrock | Claude Sonnet 4.5 |
| IA Alternativa | Google Gemini | 2.5 Flash |
| Infraestructura | AWS CDK | Python |
| CDN | CloudFront | HTTPS, SPA routing |
| Almacenamiento | S3 | Presigned URLs, 24h TTL |
| Base de datos | DynamoDB | PAY_PER_REQUEST |
| Logs | CloudWatch | JSON estructurado, 14 días |

---

## Componentes del Frontend

### Estructura de Carpetas

```
frontend/lib/
├── main.dart                        # Entry point, providers, rutas
├── core/
│   ├── amplify_config.dart          # Configuración Cognito/Amplify
│   ├── api_config.dart              # URL base API (dart-define)
│   ├── app_localizations.dart       # Strings i18n (ES/EN)
│   ├── app_settings.dart            # Tema y preferencias persistentes
│   └── app_theme.dart               # Definición de temas Material
├── models/
│   ├── analysis_config.dart         # Configuración del análisis
│   ├── analysis_result.dart         # Modelo dominio resultado
│   ├── analysis_result_dto.dart     # DTO para deserialización API
│   ├── analysis_status.dart         # Enum: normal/requiere_atencion/urgente
│   ├── analyze_request_dto.dart     # DTO request con profileContext
│   ├── captured_media.dart          # Modelo de media capturada
│   └── profile_data.dart            # Datos del perfil (bebé/padres/pediatra)
├── repositories/
│   ├── analysis_repository.dart     # POST /analyze y /analyze-gemini
│   ├── capture_repository.dart      # Coordinación de captura de video
│   └── upload_repository.dart       # Upload a S3 con presigned URL
├── services/
│   ├── auth_service.dart            # Amplify Auth (sign in/up, social, JWT)
│   ├── http_client.dart             # HTTP con inyección de auth token
│   ├── platform_service.dart        # Detección de plataforma
│   ├── profile_service.dart         # Persistencia SharedPreferences
│   ├── storage_service.dart         # Almacenamiento local
│   └── video_capture_service.dart   # Captura de video (ImagePicker)
├── viewmodels/
│   ├── analysis_viewmodel.dart      # Estado del flujo de análisis
│   ├── auth_viewmodel.dart          # Estado de autenticación
│   ├── home_viewmodel.dart          # Estado pantalla principal
│   └── splash_viewmodel.dart        # Estado splash screen
├── views/
│   ├── analysis_screen.dart         # Captura + resultados
│   ├── auth_screen.dart             # Login/registro (email + social)
│   ├── home_screen.dart             # Pantalla principal
│   ├── model_selector_screen.dart   # Selección Bedrock vs Gemini
│   ├── profile_screen.dart          # Formulario de perfil
│   ├── splash_screen.dart           # Splash con disclaimer
│   ├── verify_email_screen.dart     # Verificación de código
│   ├── web_landing_screen.dart      # Landing page pública
│   └── web_record_screen.dart       # Grabación de video (web)
└── widgets/
    ├── auth_text_field.dart          # Input estilizado para auth
    ├── babyhealth_logo_widget.dart   # Logo animado
    ├── confidence_bar_widget.dart    # Barra de porcentaje confianza
    ├── disclaimer_widget.dart        # Disclaimer médico reutilizable
    ├── error_dialog_widget.dart      # Diálogo de error
    ├── phone_mockup_widget.dart      # Mockup de teléfono (landing)
    ├── settings_controls.dart        # Toggle tema/idioma
    └── traffic_light_widget.dart     # Semáforo visual (verde/amarillo/rojo)
```

### Patrón Arquitectónico: MVVM + Repository

```
View (Widgets) → ViewModel (ChangeNotifier) → Repository → Service/HttpClient
```

- **Views:** Pantallas UI, solo presentación.
- **ViewModels:** Lógica de presentación, estado reactivo con `ChangeNotifier`.
- **Repositories:** Coordinan llamadas API, traducen DTOs a modelos de dominio.
- **Services:** Interacción con SDKs externos (Amplify, SharedPreferences, HTTP).

### Navegación

```
/web-landing  →  /auth  →  /home  →  /model-selector  →  /analysis
                    ↕                       ↕
              /verify-email            /profile
```

- Ruta inicial: `/web-landing` (web) o `/splash` (mobile).
- Rutas protegidas requieren autenticación via Cognito.
- Login social (Google/Facebook) redirige via Hosted UI y resuelve por Hub event.

### Internacionalización

- Idiomas soportados: Español (`es`) y Inglés (`en`).
- Detección automática del idioma del sistema.
- Persistencia de preferencia en SharedPreferences.
- Los modelos de IA reciben directiva de idioma para generar texto en el idioma del usuario.

---

## Componentes del Backend

### Estructura de Carpetas

```
backend/
├── lambda_handler.py            # Entry point Lambda (Mangum)
├── app/
│   ├── main.py                  # FastAPI app, middleware, routers
│   ├── config.py                # Settings con pydantic-settings
│   ├── models/
│   │   ├── requests.py          # AnalyzeRequest (video_key, session_id, language)
│   │   └── responses.py         # AnalysisResult, UploadUrlResponse, ErrorResponse
│   ├── routers/
│   │   ├── health.py            # GET /health
│   │   ├── upload.py            # GET /upload-url, GET /upload-image-url
│   │   ├── analyze.py           # POST /analyze (Bedrock: frame + spectrogram)
│   │   ├── analyze_gemini.py    # POST /analyze-gemini (multimodal nativo)
│   │   └── analyze_image.py     # POST /analyze-image (upload directo)
│   ├── services/
│   │   ├── s3_service.py        # Presigned URLs, download objects
│   │   ├── bedrock_service.py   # Claude Sonnet: visual + cry analysis
│   │   ├── gemini_service.py    # Gemini 2.5 Flash: multimodal nativo
│   │   └── dynamo_service.py    # Persistencia de resultados
│   ├── middleware/
│   │   ├── error_handler.py     # Error handler global + validation handler
│   │   └── logging_middleware.py # Logging JSON estructurado (CloudWatch)
│   └── utils/
│       ├── retry.py             # Retry con exponential backoff
│       └── secrets.py           # AWS Secrets Manager + fallback env vars
└── requirements.txt
```

### Endpoints API

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| `GET` | `/health` | Público | Health check (status + versión) |
| `GET` | `/upload-url` | JWT | Presigned URL para video (mp4/webm) |
| `GET` | `/upload-image-url` | JWT | Presigned URL para imagen (jpeg/png) |
| `POST` | `/analyze` | JWT | Análisis con Bedrock (frame extraction + spectrogram) |
| `POST` | `/analyze-gemini` | JWT | Análisis con Gemini (multimodal nativo) |
| `POST` | `/analyze-image` | JWT | Análisis directo de imagen (multipart upload) |

### Flujo de Análisis: Bedrock (`/analyze`)

```
Video (S3) → Descargar → Extraer frame (ffmpeg) → Analizar visual (Claude)
                        → Generar espectrograma audio → Clasificar llanto (Claude)
                        → Combinar resultados → Guardar DynamoDB → Response
```

### Flujo de Análisis: Gemini (`/analyze-gemini`)

```
Video (S3) → Descargar → Enviar completo a Gemini → Análisis multimodal nativo
           → Response con visual + audio integrado → Guardar DynamoDB → Response
```

### Modelo de Respuesta: `AnalysisResult`

```python
{
    "status": "normal" | "requiere_atencion" | "urgente",
    "observations": "Texto descriptivo del estado observado",
    "recommendations": "Recomendaciones para el cuidador",
    "confidence": 0.87,          # 0.0 - 1.0
    "cry_category": "hambre",    # nullable
    "cry_label": "Hambre",       # nullable
    "cry_confidence": 0.82,      # nullable
    "cry_recommendation": "...", # nullable
    "error": null,               # null = éxito, string = degradación parcial
    "session_id": "uuid",
    "disclaimer": "Esta herramienta es solo orientativa..."
}
```

### Middleware Stack

1. **ErrorHandlerMiddleware** — Captura excepciones no manejadas, retorna JSON.
2. **StructuredLoggingMiddleware** — Log JSON por request (path, method, status, duration_ms).
3. **CORSMiddleware** — Origins permitidos, headers, methods.

---

## Infraestructura AWS (CDK)

### Recursos Desplegados

| Servicio | Recurso | Configuración Clave |
|----------|---------|--------------------|
| **S3** | Bucket Videos/Imágenes | Lifecycle 24h, block public, CORS |
| **S3** | Bucket Frontend | Static hosting, block public |
| **CloudFront** | Distribution | HTTPS redirect, SPA error→index.html |
| **Cognito** | User Pool | Email sign-in, auto-verify email |
| **Cognito** | Google IdP | OAuth via Secrets Manager |
| **Cognito** | Facebook IdP | OAuth via Secrets Manager |
| **Cognito** | App Client | Authorization code grant, 1h tokens, 30d refresh |
| **API Gateway** | HTTP API | Throttle 50 rps / 100 burst, CORS, Cognito authorizer |
| **Lambda** | Function | Python 3.11, 1024MB, 60s timeout, video-processing layer |
| **Lambda Layer** | Video Processing | numpy, matplotlib, pillow, ffmpeg |
| **DynamoDB** | Table | PK: session_id, SK: timestamp, PAY_PER_REQUEST |
| **CloudWatch** | Log Group | 14 días retención |
| **Secrets Manager** | Gemini API Key | `babyhealth/gemini-api-key` |
| **Secrets Manager** | Google OAuth | `babyhealth/google-oauth` |
| **Secrets Manager** | Facebook OAuth | `babyhealth/facebook-oauth` |
| **IAM** | Lambda Role | S3 rw, Bedrock invoke/converse, DynamoDB put/query |

### Diagrama de Seguridad

```
Internet → CloudFront (HTTPS) → S3 Frontend (private, OAI)
         → API Gateway (JWT) → Lambda → S3 Videos (presigned only)
                                       → Bedrock (IAM role)
                                       → DynamoDB (IAM role)
                                       → Secrets Manager (IAM role)
```

- **Autenticación:** OAuth 2.0 via Cognito (JWT validados en API Gateway).
- **Autorización:** Cognito User Pool Authorizer en rutas protegidas.
- **Datos:** Videos eliminados automáticamente a las 24h. Perfil solo en dispositivo.
- **Secretos:** API keys en Secrets Manager, nunca en código fuente.
- **CORS:** Configurado en API Gateway y S3.

---

## Modelo de Datos

### ProfileData (Frontend — SharedPreferences)

| Campo | Tipo | Descripción |
|-------|------|-------------|
| motherName | String? | Nombre de la madre |
| fatherName | String? | Nombre del padre |
| babyName | String? | Nombre del bebé |
| birthDate | DateTime? | Fecha de nacimiento |
| birthWeightKg | double? | Peso al nacer (kg) |
| currentWeightKg | double? | Peso actual (kg) |
| birthHeightCm | double? | Altura al nacer (cm) |
| currentHeightCm | double? | Altura actual (cm) |
| gestationalWeeks | int? | Semanas de gestación |
| pediatricianName | String? | Nombre del pediatra |
| pediatricianPhone | String? | Teléfono del pediatra |
| clinicName | String? | Nombre de la clínica |

Se envía como `profileContext` al backend para contextualizar el análisis de IA.

### DynamoDB: Resultados de Análisis

| Atributo | Tipo | Clave |
|----------|------|-------|
| session_id | String | Partition Key |
| timestamp | String (ISO 8601) | Sort Key |
| result_id | String (UUID) | — |
| analysis_type | String | "visual" / "audio" / "multimodal" |
| status | String | Nivel de urgencia |
| observations | String | Observaciones del análisis |
| recommendations | String | Recomendaciones |
| confidence | Number | 0.0 - 1.0 |
| cry_category | String? | Categoría del llanto |

---

## Modelos de IA

### AWS Bedrock — Claude Sonnet 4.5

- **Uso:** Análisis visual (frame de video) + clasificación de llanto (espectrograma).
- **Invocación:** Converse API con imagen inline.
- **Prompt visual:** Evalúa coloración de piel, expresión facial, postura, estado general.
- **Prompt audio:** Clasifica espectrograma en categorías de llanto (hambre, dolor, sueño, etc.).
- **Temperature:** 0.1 (determinístico).
- **Max tokens:** 1024.

### Google Gemini 2.5 Flash

- **Uso:** Análisis multimodal nativo (video completo con audio).
- **Invocación:** Inline data (<20MB) o Files API (>20MB).
- **Ventaja:** No requiere extracción de frames ni generación de espectrograma.
- **Temperature:** 0.1.
- **Max tokens:** 2048.

### Comparación de Pipelines

| Aspecto | Bedrock (Claude) | Gemini |
|---------|-----------------|--------|
| Preprocesamiento | ffmpeg (frame + audio) | Ninguno |
| Input | Imagen JPEG + PNG espectrograma | Video completo |
| Análisis audio | Via espectrograma (imagen) | Nativo (audio en video) |
| Latencia | Mayor (procesamiento local) | Menor (una sola llamada) |
| Dependencias | ffmpeg, numpy, matplotlib | google-genai SDK |
| Costo | Bedrock pricing | Gemini API pricing |

---

## Decisiones de Diseño

| Decisión | Justificación |
|----------|---------------|
| Flutter Web (no nativo) | Desarrollo rápido, una sola codebase, demo web accesible |
| Dual AI (Bedrock + Gemini) | Redundancia, comparación de resultados, fallback |
| Perfil local (SharedPreferences) | Privacidad, no requiere backend para datos personales |
| Video 5s (no solo imagen) | Captura movimiento, expresiones, mejor análisis multimodal |
| Sistema semáforo | Comunicación clara y universal del estado |
| i18n desde día 1 | Mercado LATAM + US, escalabilidad |
| Presigned URLs | Upload directo a S3 sin proxy por Lambda |
| Serverless completo | Cero administración de servidores, escala automática |
| Cognito Hosted UI | Social login sin gestionar OAuth flow manualmente |
| CDK Python (no TypeScript) | Consistencia con backend Python del equipo |

---

## Resiliencia y Manejo de Errores

- **Retry con backoff exponencial:** 3 intentos, delays 1s → 2s → 4s.
- **Timeout de Lambda:** 60 segundos (suficiente para procesamiento de video).
- **Degradación parcial:** Si el análisis de audio falla, retorna resultado visual con campo `error`.
- **Fallback de ffmpeg:** Si no está disponible, genera imagen placeholder.
- **Fallback de Gemini API Key:** Si Secrets Manager falla, usa variable de entorno.
- **Error handler global:** Captura excepciones no manejadas, retorna JSON 500 estructurado.
- **Validación de entrada:** Pydantic models + FastAPI validation con mensajes descriptivos.

---

## Equipo

| Rol | Nombre | GitHub | Responsabilidad |
|-----|--------|--------|-----------------|
| Coordinador + Backend | Hector | @hdmartinezm | API, AWS, CDK, Deploy |
| Diseño + Frontend | Alvaro | @ajha63 | UI/UX, Estilos, Assets |
| Fullstack | William | @izquierdowaws | Integración API-Frontend |
| Frontend Lead | Francisco | @FranciscoJTHG | Componentes Flutter |

---

## Cómo Ejecutar

### Frontend (Desarrollo Local)

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

### Backend (Desarrollo Local)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### Deploy Infraestructura

```bash
cd infra
pip install -r requirements.txt
cdk deploy
```

### Deploy Frontend

```bash
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://hhcfovkc7h.execute-api.us-east-1.amazonaws.com
aws s3 sync build/web/ s3://FRONTEND_BUCKET/ --delete
aws cloudfront create-invalidation --distribution-id DIST_ID --paths "/*"
```

---

## Mejoras Futuras

- Análisis de audio on-device (DeepInfant CoreML para iOS, YAMNet TFLite para Android)
- Historial de análisis persistente con consulta por usuario
- Notificaciones push para recordatorios de chequeo
- Modo offline con cache de resultados
- Exportar reportes PDF para el pediatra
- Integración con Apple Health / Google Fit
- Tests end-to-end con LocalStack
