# Documento de Diseno - BabyHealth

## Overview

BabyHealth es una aplicacion web progresiva (Flutter Web) que utiliza IA para analizar videos de bebes y proporcionar orientacion a padres primerizos sobre el estado de salud de su bebe. La arquitectura es serverless sobre AWS con soporte para multiples modelos de IA (Bedrock Claude y Google Gemini).

**URL de Produccion:** https://babyhealth.hmartinez.info

## Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Flutter Web App                                  │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────────────┐  │
│  │  Landing   │  │   Home     │  │  Profile   │  │    Analysis      │  │
│  │   Page     │  │  Screen    │  │  Screen    │  │    Screen        │  │
│  │            │  │            │  │            │  │  (Video Capture) │  │
│  └────────────┘  └────────────┘  └────────────┘  └──────────────────┘  │
│                                                                          │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │                    Servicios y Estado                            │   │
│  │  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌──────────────┐   │   │
│  │  │AuthService│  │ProfileSvc │  │AppSettings│  │AnalysisRepo │   │   │
│  │  │(Amplify) │  │(SharedPref)│  │(Theme/i18n)│  │ (API calls) │   │   │
│  │  └──────────┘  └───────────┘  └──────────┘  └──────────────┘   │   │
│  └─────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │ HTTPS
                                 ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         CloudFront CDN                                  │
│                    babyhealth.hmartinez.info                           │
│                    (SSL via ACM Certificate)                            │
└────────────────────────────────┬───────────────────────────────────────┘
                                 │
               ┌─────────────────┼─────────────────┐
               ▼                 │                 ▼
┌──────────────────────┐         │    ┌──────────────────────────────────┐
│      S3 Bucket       │         │    │         API Gateway              │
│  (Static Frontend)   │         │    │  ┌────────────────────────────┐ │
│  - index.html        │         │    │  │ POST /analyze              │ │
│  - main.dart.js      │         │    │  │ POST /analyze-gemini       │ │
│  - assets/           │         │    │  │ POST /upload-url           │ │
└──────────────────────┘         │    │  │ GET  /health               │ │
                                 │    │  └────────────────────────────┘ │
                                 │    └──────────────┬───────────────────┘
                                 │                   │
                                 │                   ▼
                                 │    ┌──────────────────────────────────┐
                                 │    │         AWS Lambda               │
                                 │    │     (FastAPI + Mangum)           │
                                 │    │                                  │
                                 │    │  - Video frame extraction        │
                                 │    │  - AI model orchestration        │
                                 │    │  - Response formatting           │
                                 │    └──────────────┬───────────────────┘
                                 │                   │
                                 │     ┌─────────────┼─────────────┐
                                 │     ▼             ▼             ▼
                                 │  ┌────────┐  ┌────────┐  ┌────────────┐
                                 │  │Bedrock │  │Gemini  │  │ DynamoDB   │
                                 │  │(Claude)│  │  API   │  │ (Results)  │
                                 │  └────────┘  └────────┘  └────────────┘
                                 │
                                 ▼
                    ┌──────────────────────────────┐
                    │      AWS Cognito             │
                    │  - User Pool                 │
                    │  - Google OAuth              │
                    │  - Facebook OAuth            │
                    └──────────────────────────────┘
```

## Componentes del Frontend

### Estructura de Archivos

```
frontend/lib/
├── main.dart                    # Entry point, providers, rutas
├── core/
│   ├── amplify_config.dart      # Configuracion Cognito/Amplify
│   ├── app_localizations.dart   # Strings i18n (ES/EN)
│   ├── app_settings.dart        # Tema y preferencias
│   └── app_theme.dart           # Definicion de temas
├── models/
│   ├── analysis_result.dart     # Resultado del analisis
│   ├── analyze_request_dto.dart # Request con profileContext
│   └── profile_data.dart        # Datos del perfil
├── repositories/
│   └── analysis_repository.dart # Llamadas a API (Bedrock/Gemini)
├── services/
│   ├── auth_service.dart        # Autenticacion con Amplify
│   └── profile_service.dart     # Persistencia de perfil
├── viewmodels/
│   ├── analysis_viewmodel.dart  # Estado del analisis
│   └── auth_viewmodel.dart      # Estado de autenticacion
├── views/
│   ├── analysis_screen.dart     # Captura video + resultados
│   ├── auth_screen.dart         # Login social
│   ├── home_screen.dart         # Pantalla principal
│   ├── profile_screen.dart      # Formulario de perfil
│   └── web_landing_screen.dart  # Landing page publica
└── widgets/
    ├── baby_health_logo.dart    # Logo animado
    └── settings_controls.dart   # Toggle tema/idioma
```

### Pantallas Principales

#### 1. Landing Page (`web_landing_screen.dart`)
- Hero section con CTA
- Seccion de caracteristicas (6 cards)
- Seccion de arquitectura tecnica
- Responsivo (mobile/tablet/desktop)
- Animaciones hover en botones

#### 2. Home Screen (`home_screen.dart`)
- Boton para iniciar analisis
- Acceso a perfil
- Controles de configuracion
- Logout

#### 3. Profile Screen (`profile_screen.dart`)
- **Seccion Padres:** Nombre de mama y papa
- **Seccion Bebe:** Nombre, fecha nacimiento, peso (nacimiento/actual), altura, semanas gestacionales
- **Seccion Pediatra:** Nombre, telefono, clinica
- Persistencia local con SharedPreferences
- Datos enviados como contexto al analisis IA

#### 4. Analysis Screen (`analysis_screen.dart`)
- Captura de video (5 segundos)
- Seleccion de modelo (Bedrock/Gemini)
- Visualizacion de resultado tipo semaforo
- Lista de observaciones y recomendaciones

### Sistema de Localizacion

```dart
// Uso: context.l10n.nombreClave
class AppLocalizations {
  static const _strings = {
    'es': {
      'appTitle': 'BabyHealth',
      'profile': 'Perfil',
      'parents': 'Padres',
      'baby': 'Bebe',
      // ... 50+ strings
    },
    'en': {
      'appTitle': 'BabyHealth',
      'profile': 'Profile',
      'parents': 'Parents',
      'baby': 'Baby',
      // ... 50+ strings
    },
  };
}
```

## Componentes del Backend

### Estructura de Archivos

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                  # FastAPI app + Mangum handler
│   ├── config.py                # Variables de entorno
│   ├── models/
│   │   ├── requests.py          # Pydantic request models
│   │   └── responses.py         # Pydantic response models
│   ├── routers/
│   │   ├── health.py            # GET /health
│   │   ├── upload.py            # POST /upload-url
│   │   ├── analyze.py           # POST /analyze (Bedrock)
│   │   └── analyze_gemini.py    # POST /analyze-gemini
│   └── services/
│       ├── s3_service.py        # Upload/download S3
│       ├── bedrock_service.py   # Claude Sonnet
│       └── gemini_service.py    # Google Gemini
└── requirements.txt
```

### Endpoints API

| Metodo | Endpoint | Descripcion |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/upload-url` | Genera URL pre-firmada para S3 |
| POST | `/analyze` | Analiza video con Bedrock Claude |
| POST | `/analyze-gemini` | Analiza video con Google Gemini |

### Request: Analyze

```python
class AnalyzeRequest(BaseModel):
    video_key: str              # S3 key del video
    session_id: Optional[str]   # ID de sesion
    profile_context: Optional[dict]  # Contexto del perfil
```

### Response: Analyze

```python
class AnalyzeResponse(BaseModel):
    session_id: str
    estado_general: Literal["normal", "requiere_atencion", "urgente"]
    observaciones: list[str]
    recomendaciones: list[str]
    confianza: float  # 0.0 - 1.0
    disclaimer: str
    timestamp: datetime
```

### Prompt del Sistema (Bedrock/Gemini)

```
Eres un asistente de orientacion para padres. Analiza este video/imagen de un bebe.

Contexto del bebe (si disponible):
{profile_context}

Evalua:
- Coloracion de piel (tonos amarillentos pueden indicar ictericia)
- Expresion facial (signos de malestar o tranquilidad)
- Movimientos y postura
- Estado general visible

Responde SOLO en JSON con este formato:
{
  "estado_general": "normal | requiere_atencion | urgente",
  "observaciones": ["observacion 1", "observacion 2"],
  "recomendaciones": ["recomendacion 1", "recomendacion 2"],
  "confianza": 0.87
}
```

## Infraestructura AWS (CDK)

### Recursos Desplegados

| Servicio | Recurso | Proposito |
|----------|---------|-----------|
| S3 | `babyhealthstack-*-bucket` | Frontend estatico |
| S3 | `babyhealthstack-*-videos` | Videos temporales (TTL 24h) |
| CloudFront | Distribution | CDN con SSL |
| Route 53 | A Record | DNS `babyhealth.hmartinez.info` |
| ACM | Certificate | SSL para dominio custom |
| Cognito | User Pool | Autenticacion |
| Cognito | Identity Providers | Google, Facebook |
| API Gateway | REST API | Endpoints backend |
| Lambda | Function | FastAPI runtime |
| Lambda Layer | Dependencies | numpy, opencv, etc. |
| DynamoDB | Table | Resultados de analisis |

### Configuracion de Cognito

```typescript
// OAuth Callback URLs
const callbackUrls = [
  'https://babyhealth.hmartinez.info/',
  'https://d272sj5fujdytw.cloudfront.net/',
  'http://localhost:8443/'
];

// Identity Providers
const identityProviders = ['Google', 'Facebook', 'COGNITO'];

// OAuth Scopes
const scopes = ['openid', 'email', 'profile'];
```

## Modelo de Datos

### ProfileData (Frontend)

```dart
class ProfileData {
  final String? motherName;
  final String? fatherName;
  final String? babyName;
  final DateTime? birthDate;
  final double? birthWeightKg;
  final double? currentWeightKg;
  final double? birthHeightCm;
  final double? currentHeightCm;
  final int? gestationalWeeks;
  final String? pediatricianName;
  final String? pediatricianPhone;
  final String? clinicName;

  // Calcula edad en meses
  int? get ageInMonths { ... }

  // Genera contexto para IA
  Map<String, dynamic> toAnalysisContext() { ... }
}
```

### AnalysisResult (Frontend)

```dart
class AnalysisResult {
  final String sessionId;
  final String estadoGeneral;  // normal, requiere_atencion, urgente
  final List<String> observaciones;
  final List<String> recomendaciones;
  final double confianza;
  final String disclaimer;
  final DateTime timestamp;
}
```

## Diseno Responsivo

### Breakpoints

| Dispositivo | Ancho | Layout |
|-------------|-------|--------|
| Mobile | < 360px | Compacto, iconos reducidos |
| Mobile | 360-600px | Normal mobile |
| Tablet | 600-900px | Hibrido |
| Desktop | > 900px | Full, 3 columnas |

### Adaptaciones Mobile

- **HomeScreen AppBar:** Profile/logout en popup menu en < 400px
- **ProfileScreen:** Campos apilados verticalmente en < 350px
- **Landing Features:** Column en lugar de Grid para altura flexible
- **SettingsControls:** Oculta texto de idioma en < 360px

## Seguridad

### Autenticacion
- OAuth 2.0 via AWS Cognito
- Tokens JWT validados en cada request
- Session storage para tokens (no localStorage)

### Datos
- Videos eliminados automaticamente (TTL 24h)
- Datos de perfil solo en dispositivo (SharedPreferences)
- HTTPS obligatorio (CloudFront redirect)
- CORS configurado solo para dominios permitidos

### Privacidad
- Disclaimer obligatorio en cada analisis
- No se almacenan imagenes/videos permanentemente
- Perfil nunca enviado a terceros (solo como contexto a IA)

## Testing

### Frontend (Flutter)

```bash
cd frontend
flutter test
```

- Unit tests para ViewModels
- Widget tests para componentes criticos
- Mock de servicios AWS

### Backend (Python)

```bash
cd backend
pytest
```

- Unit tests con mocks de AWS
- Integration tests con LocalStack
- Property-based tests con Hypothesis

## Decisiones de Diseno

| Decision | Justificacion |
|----------|---------------|
| Flutter Web (no nativo) | Desarrollo rapido, una sola codebase, demo web accesible |
| Dual AI (Bedrock + Gemini) | Redundancia, comparacion de resultados, fallback |
| Profile local (SharedPreferences) | Privacidad, no requiere backend para datos personales |
| Video 5s (no imagen) | Captura movimiento, expresiones, mejor analisis |
| Sistema semaforo | Comunicacion clara y universal del estado |
| i18n desde dia 1 | Mercado LATAM + US, escalabilidad |

## Mejoras Futuras

- [ ] Analisis de audio (llanto) con modelo on-device
- [ ] Historial de analisis persistente
- [ ] Notificaciones push para recordatorios
- [ ] Modo offline con cache de resultados
- [ ] Exportar reportes PDF para pediatra
- [ ] Integracion con Apple Health / Google Fit
