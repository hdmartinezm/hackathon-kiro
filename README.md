<div align="center">

# 👶 BabyHealth

### Orientación inteligente para padres primerizos

[![Live Demo](https://img.shields.io/badge/Demo-Live-brightgreen?style=for-the-badge&logo=vercel)](https://babyhealth.hmartinez.info)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com)
[![Claude AI](https://img.shields.io/badge/Claude_AI-Bedrock-orange?style=for-the-badge&logo=anthropic)](https://aws.amazon.com/bedrock/)

<img src="docs/screenshots/pic03.png" alt="BabyHealth Hero" width="400"/>

**Analiza videos de tu bebé con IA y recibe orientación instantánea sobre su estado de salud**

[Probar Demo](https://babyhealth.hmartinez.info) · [English Version](#-babyhealth-1)

</div>

---

# 🇪🇸 Versión en Español

## 🎯 El Problema

Los **padres primerizos** enfrentan una constante incertidumbre sobre la salud de sus bebés:

- 😰 **Ansiedad nocturna**: ¿Mi bebé está respirando bien? ¿Por qué llora así?
- 🏥 **Visitas innecesarias a urgencias**: El 60% de las consultas de emergencia pediátricas no son urgentes
- 🌍 **Acceso limitado**: Familias en zonas rurales sin acceso rápido a pediatras
- 🗣️ **Barrera del idioma**: Padres que no dominan el idioma local en servicios de salud

## 💡 Nuestra Solución

**BabyHealth** utiliza **Inteligencia Artificial multimodal** para analizar videos de bebés y proporcionar orientación inmediata, funcionando como un **primer filtro inteligente** que ayuda a los padres a decidir cuándo es realmente necesario buscar atención médica.

### ¿Cómo funciona?

```
📱 Graba un video    →    🤖 IA analiza    →    🚦 Resultado claro    →    📋 Recomendaciones
   de tu bebé              el contenido         (Verde/Amarillo/Rojo)       personalizadas
```

---

## ✨ Características Principales

<table>
<tr>
<td width="50%">

### 🎥 Análisis de Video con IA
- Captura video directamente desde la app
- Extracción inteligente de frames clave
- Análisis multimodal con **Claude (Bedrock)** o **Gemini**
- Detección de patrones visuales del bebé

</td>
<td width="50%">

### 🚦 Sistema de Semáforo
- **🟢 Verde (Normal)**: Tu bebé parece estar bien
- **🟡 Amarillo (Atención)**: Observa y consulta si persiste
- **🔴 Rojo (Urgente)**: Busca atención médica pronto

</td>
</tr>
<tr>
<td width="50%">

### 👤 Perfil Personalizado
- Datos del bebé (nombre, fecha de nacimiento)
- Información de los padres
- Datos del pediatra de cabecera
- Contexto para análisis más precisos

</td>
<td width="50%">

### 🌐 Accesibilidad Total
- **Bilingüe**: Español e Inglés completo
- **Responsive**: Móvil, tablet y escritorio
- **Tema adaptable**: Modo claro y oscuro
- **PWA Ready**: Instalable como app nativa

</td>
</tr>
</table>

---

## 🖥️ Capturas de Pantalla

<div align="center">

| Landing Page | Selector de IA | Análisis en Proceso |
|:---:|:---:|:---:|
| Página de bienvenida con acceso rápido | Elige entre Bedrock o Gemini | Procesamiento del video |

| Resultado del Análisis | Perfil del Bebé | Configuración |
|:---:|:---:|:---:|
| Sistema de semáforo visual | Personalización del contexto | Idioma y tema |

</div>

> 📸 *Accede a la [demo en vivo](https://babyhealth.hmartinez.info) para ver la aplicación funcionando*

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CLIENTE (Flutter Web)                              │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐│
│  │   Landing   │ │    Home     │ │   Profile   │ │    Analysis Screen     ││
│  │    Page     │ │   Screen    │ │   Screen    │ │  (Capture + Results)   ││
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────────────────┘│
│                              │                                               │
│  ┌───────────────────────────┴───────────────────────────────────────────┐  │
│  │  AWS Amplify + Cognito (Google/Facebook OAuth)                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │ HTTPS
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AWS CLOUDFRONT CDN                                    │
│                     babyhealth.hmartinez.info                                │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    ▼                                   ▼
┌───────────────────────────────┐     ┌───────────────────────────────────────┐
│         S3 BUCKET             │     │           API GATEWAY                 │
│     (Frontend Estático)       │     │    /analyze  /upload-url  /health     │
└───────────────────────────────┘     └───────────────────┬───────────────────┘
                                                          │
                                                          ▼
                                      ┌───────────────────────────────────────┐
                                      │           AWS LAMBDA                  │
                                      │      Python 3.11 + FastAPI            │
                                      │         (Mangum Adapter)              │
                                      └───────────────────┬───────────────────┘
                                                          │
                    ┌─────────────────┬─────────────────┬─┴─────────────────┐
                    ▼                 ▼                 ▼                   ▼
          ┌─────────────────┐ ┌─────────────────┐ ┌───────────┐ ┌─────────────────┐
          │  AWS BEDROCK    │ │  GOOGLE GEMINI  │ │    S3     │ │    DYNAMODB     │
          │ Claude Sonnet 4 │ │   (Fallback)    │ │  (Videos) │ │   (Resultados)  │
          │   Multimodal    │ │   Multimodal    │ │  TTL: 24h │ │                 │
          └─────────────────┘ └─────────────────┘ └───────────┘ └─────────────────┘
```

---

## 🛠️ Stack Tecnológico

### Frontend
| Tecnología | Uso |
|------------|-----|
| **Flutter 3.x** | Framework multiplataforma (Web, iOS, Android) |
| **Provider** | Gestión de estado reactiva |
| **AWS Amplify** | SDK de autenticación y servicios AWS |
| **SharedPreferences** | Persistencia local de configuración |

### Backend
| Tecnología | Uso |
|------------|-----|
| **Python 3.11** | Runtime del servidor |
| **FastAPI** | Framework web de alto rendimiento |
| **Mangum** | Adapter para AWS Lambda |
| **Pydantic** | Validación de datos y schemas |

### Inteligencia Artificial
| Proveedor | Modelo | Capacidad |
|-----------|--------|-----------|
| **AWS Bedrock** | Claude Sonnet 4 | Análisis multimodal (imágenes + texto) |
| **Google** | Gemini 2.5 Flash | Análisis de video nativo (alternativo) |

### Infraestructura AWS
| Servicio | Función |
|----------|---------|
| **CloudFront** | CDN global con SSL |
| **S3** | Hosting estático + almacenamiento de videos |
| **API Gateway** | REST API con throttling y autorización |
| **Lambda** | Compute serverless |
| **Cognito** | Autenticación OAuth (Google/Facebook) |
| **DynamoDB** | Base de datos de resultados |
| **Secrets Manager** | Gestión segura de API keys |
| **CDK (TypeScript)** | Infraestructura como código |

---

## 🚀 Flujo de Usuario

```mermaid
graph LR
    A[👤 Usuario] --> B[Landing Page]
    B --> C{¿Autenticado?}
    C -->|No| D[Login Google/Facebook]
    C -->|Sí| E[Home Screen]
    D --> E
    E --> F[Configurar Perfil]
    E --> G[Iniciar Análisis]
    G --> H[Seleccionar IA]
    H --> I[Grabar Video]
    I --> J[Subir a S3]
    J --> K[Procesar con IA]
    K --> L[Ver Resultados]
    L --> M{🚦 Estado}
    M -->|🟢| N[Todo bien]
    M -->|🟡| O[Observar]
    M -->|🔴| P[Buscar atención]
```

---

## 📁 Estructura del Proyecto

```
hackathon-Kiro/
├── 📱 frontend/                  # Flutter Web App
│   ├── lib/
│   │   ├── core/                # Configuración, temas, i18n
│   │   ├── models/              # Modelos de datos
│   │   ├── repositories/        # Capa de acceso a datos
│   │   ├── services/            # Auth, Profile, API
│   │   ├── viewmodels/          # MVVM ViewModels
│   │   ├── views/               # Pantallas UI
│   │   └── widgets/             # Componentes reutilizables
│   └── test/                    # Tests unitarios
│
├── ⚙️ backend/                   # Python FastAPI
│   ├── app/
│   │   ├── main.py              # Entry point + Mangum
│   │   ├── config.py            # Configuración centralizada
│   │   ├── routers/             # Endpoints REST
│   │   │   ├── analyze.py       # POST /analyze (Bedrock)
│   │   │   ├── analyze_gemini.py# POST /analyze-gemini
│   │   │   └── upload.py        # Presigned URLs S3
│   │   └── services/            # Lógica de negocio
│   │       ├── bedrock_service.py
│   │       ├── gemini_service.py
│   │       └── s3_service.py
│   └── lambda_package/          # Paquete desplegable
│
├── 🏗️ infra/                     # AWS CDK (TypeScript)
│   ├── lib/
│   │   └── infra-stack.ts       # Stack principal
│   └── layers/                  # Lambda Layers
│
└── 📚 docs/                      # Documentación
    ├── screenshots/             # Capturas de pantalla
    └── superpowers/             # Specs de diseño
```

---

## 🏃‍♂️ Inicio Rápido

### Requisitos Previos
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
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### Despliegue Completo

```bash
# 1. Infraestructura AWS
cd infra
npm install
cdk deploy --all

# 2. Backend Lambda
cd ../backend
./deploy.sh  # o: aws lambda update-function-code ...

# 3. Frontend
cd ../frontend
flutter build web --release
aws s3 sync build/web/ s3://$BUCKET_NAME/ --delete
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

---

## 🔒 Seguridad y Privacidad

| Aspecto | Implementación |
|---------|----------------|
| **Autenticación** | OAuth 2.0 via AWS Cognito (Google/Facebook) |
| **Transporte** | HTTPS obligatorio (CloudFront SSL) |
| **Videos** | Almacenamiento temporal con TTL de 24 horas |
| **API Keys** | AWS Secrets Manager (nunca en código) |
| **CORS** | Configuración restrictiva por dominio |

---

## 🌟 Innovación y Diferenciadores

1. **Multimodal Real**: Análisis de video completo, no solo imágenes estáticas
2. **Multi-IA**: Flexibilidad entre Bedrock y Gemini según disponibilidad/preferencia
3. **Serverless Puro**: Escalabilidad infinita, costo por uso
4. **IaC Completo**: Infraestructura reproducible con AWS CDK
5. **UX Centrada en Padres**: Sistema de semáforo intuitivo, no jerga médica
6. **Bilingüe Nativo**: No es traducción, es diseño desde el inicio

---

## 🗺️ Roadmap Futuro

- [ ] **Análisis de llanto**: Clasificación de tipos de llanto (hambre, dolor, sueño)
- [ ] **Historial de análisis**: Seguimiento del bebé en el tiempo
- [ ] **Alertas inteligentes**: Notificaciones basadas en patrones
- [ ] **Integración con pediatras**: Compartir reportes directamente
- [ ] **App nativa iOS/Android**: Flutter ya lo soporta, solo empaquetar
- [ ] **Soporte offline**: Análisis básico sin conexión

---

## 👥 Equipo

<table>
<tr>
<td align="center">
<b>Héctor Martínez</b><br>
<sub>Backend & Infraestructura AWS</sub>
</td>
</tr>
</table>

---

<div align="center">

### ⚠️ Aviso Importante

**BabyHealth es una herramienta de ORIENTACIÓN, no de diagnóstico médico.**
Siempre consulte con su pediatra para decisiones sobre la salud de su bebé.

</div>

---

<br><br>

<div align="center">

# ═══════════════════════════════════════════════════════════

# 🇺🇸 ENGLISH VERSION

# ═══════════════════════════════════════════════════════════

</div>

<br><br>

---

<div align="center">

# 👶 BabyHealth

### Smart guidance for first-time parents

[![Live Demo](https://img.shields.io/badge/Demo-Live-brightgreen?style=for-the-badge&logo=vercel)](https://babyhealth.hmartinez.info)
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![AWS](https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white)](https://aws.amazon.com)
[![Claude AI](https://img.shields.io/badge/Claude_AI-Bedrock-orange?style=for-the-badge&logo=anthropic)](https://aws.amazon.com/bedrock/)

<img src="docs/screenshots/pic03.png" alt="BabyHealth Hero" width="400"/>

**Analyze videos of your baby with AI and receive instant guidance on their health status**

[Try Demo](https://babyhealth.hmartinez.info) · [Versión en Español](#-babyhealth)

</div>

---

## 🎯 The Problem

**First-time parents** face constant uncertainty about their babies' health:

- 😰 **Nighttime anxiety**: Is my baby breathing well? Why are they crying like this?
- 🏥 **Unnecessary ER visits**: 60% of pediatric emergency consultations are not urgent
- 🌍 **Limited access**: Families in rural areas without quick access to pediatricians
- 🗣️ **Language barrier**: Parents who don't speak the local language in healthcare services

## 💡 Our Solution

**BabyHealth** uses **multimodal Artificial Intelligence** to analyze baby videos and provide immediate guidance, working as a **smart first filter** that helps parents decide when it's really necessary to seek medical attention.

### How does it work?

```
📱 Record a video    →    🤖 AI analyzes    →    🚦 Clear result       →    📋 Personalized
   of your baby            the content          (Green/Yellow/Red)         recommendations
```

---

## ✨ Key Features

<table>
<tr>
<td width="50%">

### 🎥 AI Video Analysis
- Capture video directly from the app
- Smart extraction of key frames
- Multimodal analysis with **Claude (Bedrock)** or **Gemini**
- Detection of baby's visual patterns

</td>
<td width="50%">

### 🚦 Traffic Light System
- **🟢 Green (Normal)**: Your baby seems fine
- **🟡 Yellow (Attention)**: Monitor and consult if it persists
- **🔴 Red (Urgent)**: Seek medical attention soon

</td>
</tr>
<tr>
<td width="50%">

### 👤 Personalized Profile
- Baby data (name, date of birth)
- Parents' information
- Primary pediatrician data
- Context for more accurate analysis

</td>
<td width="50%">

### 🌐 Full Accessibility
- **Bilingual**: Complete Spanish and English
- **Responsive**: Mobile, tablet, and desktop
- **Adaptive theme**: Light and dark mode
- **PWA Ready**: Installable as native app

</td>
</tr>
</table>

---

## 🖥️ Screenshots

<div align="center">

| Landing Page | AI Selector | Analysis in Progress |
|:---:|:---:|:---:|
| Welcome page with quick access | Choose between Bedrock or Gemini | Video processing |

| Analysis Result | Baby Profile | Settings |
|:---:|:---:|:---:|
| Visual traffic light system | Context customization | Language and theme |

</div>

> 📸 *Access the [live demo](https://babyhealth.hmartinez.info) to see the application in action*

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CLIENT (Flutter Web)                               │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────────────────┐│
│  │   Landing   │ │    Home     │ │   Profile   │ │    Analysis Screen     ││
│  │    Page     │ │   Screen    │ │   Screen    │ │  (Capture + Results)   ││
│  └─────────────┘ └─────────────┘ └─────────────┘ └─────────────────────────┘│
│                              │                                               │
│  ┌───────────────────────────┴───────────────────────────────────────────┐  │
│  │  AWS Amplify + Cognito (Google/Facebook OAuth)                        │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │ HTTPS
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        AWS CLOUDFRONT CDN                                    │
│                     babyhealth.hmartinez.info                                │
└─────────────────────────────────────┬───────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    ▼                                   ▼
┌───────────────────────────────┐     ┌───────────────────────────────────────┐
│         S3 BUCKET             │     │           API GATEWAY                 │
│     (Static Frontend)         │     │    /analyze  /upload-url  /health     │
└───────────────────────────────┘     └───────────────────┬───────────────────┘
                                                          │
                                                          ▼
                                      ┌───────────────────────────────────────┐
                                      │           AWS LAMBDA                  │
                                      │      Python 3.11 + FastAPI            │
                                      │         (Mangum Adapter)              │
                                      └───────────────────┬───────────────────┘
                                                          │
                    ┌─────────────────┬─────────────────┬─┴─────────────────┐
                    ▼                 ▼                 ▼                   ▼
          ┌─────────────────┐ ┌─────────────────┐ ┌───────────┐ ┌─────────────────┐
          │  AWS BEDROCK    │ │  GOOGLE GEMINI  │ │    S3     │ │    DYNAMODB     │
          │ Claude Sonnet 4 │ │   (Fallback)    │ │  (Videos) │ │   (Results)     │
          │   Multimodal    │ │   Multimodal    │ │  TTL: 24h │ │                 │
          └─────────────────┘ └─────────────────┘ └───────────┘ └─────────────────┘
```

---

## 🛠️ Tech Stack

### Frontend
| Technology | Use |
|------------|-----|
| **Flutter 3.x** | Cross-platform framework (Web, iOS, Android) |
| **Provider** | Reactive state management |
| **AWS Amplify** | Authentication SDK and AWS services |
| **SharedPreferences** | Local settings persistence |

### Backend
| Technology | Use |
|------------|-----|
| **Python 3.11** | Server runtime |
| **FastAPI** | High-performance web framework |
| **Mangum** | AWS Lambda adapter |
| **Pydantic** | Data validation and schemas |

### Artificial Intelligence
| Provider | Model | Capability |
|----------|-------|------------|
| **AWS Bedrock** | Claude Sonnet 4 | Multimodal analysis (images + text) |
| **Google** | Gemini 2.5 Flash | Native video analysis (alternative) |

### AWS Infrastructure
| Service | Function |
|---------|----------|
| **CloudFront** | Global CDN with SSL |
| **S3** | Static hosting + video storage |
| **API Gateway** | REST API with throttling and authorization |
| **Lambda** | Serverless compute |
| **Cognito** | OAuth authentication (Google/Facebook) |
| **DynamoDB** | Results database |
| **Secrets Manager** | Secure API keys management |
| **CDK (TypeScript)** | Infrastructure as code |

---

## 🚀 User Flow

```mermaid
graph LR
    A[👤 User] --> B[Landing Page]
    B --> C{Authenticated?}
    C -->|No| D[Login Google/Facebook]
    C -->|Yes| E[Home Screen]
    D --> E
    E --> F[Configure Profile]
    E --> G[Start Analysis]
    G --> H[Select AI]
    H --> I[Record Video]
    I --> J[Upload to S3]
    J --> K[Process with AI]
    K --> L[View Results]
    L --> M{🚦 Status}
    M -->|🟢| N[All good]
    M -->|🟡| O[Monitor]
    M -->|🔴| P[Seek attention]
```

---

## 📁 Project Structure

```
hackathon-Kiro/
├── 📱 frontend/                  # Flutter Web App
│   ├── lib/
│   │   ├── core/                # Configuration, themes, i18n
│   │   ├── models/              # Data models
│   │   ├── repositories/        # Data access layer
│   │   ├── services/            # Auth, Profile, API
│   │   ├── viewmodels/          # MVVM ViewModels
│   │   ├── views/               # UI screens
│   │   └── widgets/             # Reusable components
│   └── test/                    # Unit tests
│
├── ⚙️ backend/                   # Python FastAPI
│   ├── app/
│   │   ├── main.py              # Entry point + Mangum
│   │   ├── config.py            # Centralized configuration
│   │   ├── routers/             # REST endpoints
│   │   │   ├── analyze.py       # POST /analyze (Bedrock)
│   │   │   ├── analyze_gemini.py# POST /analyze-gemini
│   │   │   └── upload.py        # S3 presigned URLs
│   │   └── services/            # Business logic
│   │       ├── bedrock_service.py
│   │       ├── gemini_service.py
│   │       └── s3_service.py
│   └── lambda_package/          # Deployable package
│
├── 🏗️ infra/                     # AWS CDK (TypeScript)
│   ├── lib/
│   │   └── infra-stack.ts       # Main stack
│   └── layers/                  # Lambda Layers
│
└── 📚 docs/                      # Documentation
    ├── screenshots/             # Screenshots
    └── superpowers/             # Design specs
```

---

## 🏃‍♂️ Quick Start

### Prerequisites
- Flutter SDK 3.x
- Python 3.11+
- AWS CLI configured
- Node.js 18+ (for CDK)

### Frontend (Local Development)

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

### Backend (Local Development)

```bash
cd backend
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

### Full Deployment

```bash
# 1. AWS Infrastructure
cd infra
npm install
cdk deploy --all

# 2. Backend Lambda
cd ../backend
./deploy.sh  # or: aws lambda update-function-code ...

# 3. Frontend
cd ../frontend
flutter build web --release
aws s3 sync build/web/ s3://$BUCKET_NAME/ --delete
aws cloudfront create-invalidation --distribution-id $DIST_ID --paths "/*"
```

---

## 🔒 Security and Privacy

| Aspect | Implementation |
|--------|----------------|
| **Authentication** | OAuth 2.0 via AWS Cognito (Google/Facebook) |
| **Transport** | Mandatory HTTPS (CloudFront SSL) |
| **Videos** | Temporary storage with 24-hour TTL |
| **API Keys** | AWS Secrets Manager (never in code) |
| **CORS** | Restrictive per-domain configuration |

---

## 🌟 Innovation and Differentiators

1. **Real Multimodal**: Complete video analysis, not just static images
2. **Multi-AI**: Flexibility between Bedrock and Gemini based on availability/preference
3. **Pure Serverless**: Infinite scalability, pay-per-use
4. **Complete IaC**: Reproducible infrastructure with AWS CDK
5. **Parent-Centered UX**: Intuitive traffic light system, no medical jargon
6. **Native Bilingual**: Not a translation, designed from the start

---

## 🗺️ Future Roadmap

- [ ] **Cry analysis**: Classification of cry types (hunger, pain, sleep)
- [ ] **Analysis history**: Baby tracking over time
- [ ] **Smart alerts**: Pattern-based notifications
- [ ] **Pediatrician integration**: Share reports directly
- [ ] **Native iOS/Android app**: Flutter already supports it, just package
- [ ] **Offline support**: Basic analysis without connection

---

## 👥 Team

<table>
<tr>
<td align="center">
<b>Héctor Martínez</b><br>
<sub>Backend & AWS Infrastructure</sub>
</td>
</tr>
</table>

---

## 📄 License

Developed during **Hackathon Kiro 2025**

---

<div align="center">

### ⚠️ Important Notice

**BabyHealth is a GUIDANCE tool, not a medical diagnosis.**
Always consult with your pediatrician for decisions about your baby's health.

---

<img src="docs/screenshots/pic01.png" alt="Baby" width="200"/>

**With love, for parents around the world** 💙

[⬆ Back to top](#-babyhealth)

</div>
