# BabyHealth

**Aplicacion de orientacion para padres primerizos** que utiliza IA para analizar videos de bebes y proporcionar recomendaciones sobre su estado de salud.

**Live Demo:** [https://babyhealth.hmartinez.info](https://babyhealth.hmartinez.info)

## Caracteristicas

- **Analisis de Video con IA** - Captura video del bebe y obtiene analisis usando AWS Bedrock (Claude) o Google Gemini
- **Sistema de Semaforo** - Resultados claros: Verde (normal), Amarillo (atencion), Rojo (urgente)
- **Perfil Personalizado** - Datos del bebe, padres y pediatra para contextualizar los analisis
- **Bilingue** - Soporte completo en Espanol e Ingles
- **Modo Oscuro/Claro** - Interfaz adaptable a preferencias del usuario
- **Responsive** - Funciona en movil, tablet y escritorio
- **Autenticacion Social** - Login con Google o Facebook via AWS Cognito

## Stack Tecnologico

### Frontend
- **Framework:** Flutter Web
- **Estado:** Provider
- **Auth:** AWS Amplify + Cognito
- **Persistencia Local:** SharedPreferences

### Backend
- **Runtime:** Python 3.11 + FastAPI
- **Despliegue:** AWS Lambda + API Gateway
- **IA:**
  - AWS Bedrock (Claude Sonnet)
  - Google Gemini (alternativo)

### Infraestructura (AWS)
- **CDN:** CloudFront
- **Hosting:** S3
- **Auth:** Cognito (Google/Facebook OAuth)
- **API:** API Gateway + Lambda
- **Almacenamiento:** S3 (videos temporales, TTL 24h)
- **Base de Datos:** DynamoDB
- **IaC:** AWS CDK (TypeScript)

## Estructura del Proyecto

```
hackathon-Kiro/
├── frontend/                 # Flutter Web App
│   ├── lib/
│   │   ├── core/            # Configuracion, temas, localizacion
│   │   ├── models/          # Modelos de datos (ProfileData, etc.)
│   │   ├── repositories/    # Capa de acceso a datos
│   │   ├── services/        # Servicios (Auth, Profile, etc.)
│   │   ├── viewmodels/      # ViewModels (MVVM)
│   │   ├── views/           # Pantallas
│   │   └── widgets/         # Componentes reutilizables
│   └── test/                # Tests unitarios
├── backend/                  # Python FastAPI
│   ├── app/
│   │   ├── main.py          # Entry point + Mangum handler
│   │   ├── routers/         # Endpoints (analyze, upload, etc.)
│   │   └── services/        # Servicios (S3, Bedrock, Gemini)
│   └── tests/
├── infra/                    # AWS CDK
│   ├── lib/                 # Stacks de CDK
│   └── layers/              # Lambda Layers
└── docs/                     # Documentacion
```

## Inicio Rapido

### Requisitos
- Flutter SDK 3.x
- Python 3.11+
- AWS CLI configurado
- Node.js 18+ (para CDK)

### Frontend (Desarrollo Local)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

### Backend (Desarrollo Local)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### Despliegue

```bash
# Infraestructura
cd infra
npm install
cdk deploy

# Frontend
cd frontend
flutter build web --release
aws s3 sync build/web/ s3://YOUR_BUCKET_NAME/ --delete
aws cloudfront create-invalidation --distribution-id YOUR_DIST_ID --paths "/*"
```

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                    Flutter Web App                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐│
│  │ Landing  │  │  Home    │  │ Profile  │  │ Analysis Screen ││
│  │  Page    │  │ Screen   │  │ Screen   │  │ (Video + Results)││
│  └──────────┘  └──────────┘  └──────────┘  └──────────────────┘│
└───────────────────────────┬─────────────────────────────────────┘
                            │ HTTPS
                            ▼
┌───────────────────────────────────────────────────────────────┐
│                    CloudFront CDN                              │
│                 babyhealth.hmartinez.info                      │
└───────────────────────────┬───────────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
┌─────────────────────────┐   ┌─────────────────────────────────┐
│     S3 Bucket           │   │      API Gateway                │
│  (Static Frontend)      │   │   /analyze, /upload-url, etc.   │
└─────────────────────────┘   └───────────────┬─────────────────┘
                                              │
                                              ▼
                              ┌───────────────────────────────────┐
                              │        AWS Lambda                 │
                              │    (FastAPI + Mangum)             │
                              └───────────────┬───────────────────┘
                                              │
                    ┌─────────────────────────┼─────────────────────────┐
                    ▼                         ▼                         ▼
          ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
          │   AWS Bedrock    │    │   Google Gemini  │    │    DynamoDB      │
          │  (Claude Sonnet) │    │   (Alternative)  │    │   (Results)      │
          └──────────────────┘    └──────────────────┘    └──────────────────┘
```

## Autores

- **Hector Martinez** - Backend & Infraestructura
- **[Equipo Hackathon Kiro]**

## Licencia

Este proyecto fue desarrollado durante el Hackathon Kiro 2026.

---

*Nota: Esta aplicacion es solo para orientacion. Siempre consulte con su pediatra para decisiones medicas.*
