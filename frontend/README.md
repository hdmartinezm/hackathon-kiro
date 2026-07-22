# BabyHealth — Frontend (Flutter App)

Aplicación Flutter multiplataforma (Android APK + Web) para la asistencia y orientación neonatal con Inteligencia Artificial multimodal en AWS Bedrock.

---

## 🚀 Requisitos Previos

- **Flutter SDK**: >= 3.44.6
- **Dart SDK**: >= 3.0.0
- **Navegador**: Google Chrome (para desarrollo Web)
- **Dispositivo Móvil / Emulador**: Android Studio / AVD / Dispositivo físico Android con depuración USB habilitada

---

## 🛠️ Instalación y Setup

1. Entrar al directorio del frontend:
   ```bash
   cd frontend
   ```

2. Descargar e instalar las dependencias:
   ```bash
   flutter pub get
   ```

3. Verificar que el entorno esté correcto:
   ```bash
   flutter analyze
   ```

---

## 💻 Ejecución en Local

### 1. Ejecución en la Web (Landing Page Informativa + Simulador)
Al ejecutar en la Web, la aplicación inicia en la **Landing Page promocional** que incluye el simulador de teléfono interactivo:

```bash
# Ejecución por defecto (con mock/fallback)
flutter run -d chrome

# Ejecución especificando URL base del backend FastAPI
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

### 2. Ejecución en Móvil (App Nativa Android)
Al ejecutar en un dispositivo Android o emulador, la aplicación inicia en el **flujo móvil nativo** (`SplashScreen` → `HomeScreen` → `AnalysisScreen`):

```bash
# 1. Listar dispositivos o emuladores disponibles
flutter devices

# 2. Ejecutar en el emulador (ej. emulator-5554)
flutter run -d emulator-5554

# O ejecutar en un dispositivo Android conectado vía USB
flutter run -d android

# Con URL base del backend configurada
flutter run -d android --dart-define=API_BASE_URL=http://localhost:8000
```

---

## 📦 Builds de Producción

### Generar Build para la Web
```bash
flutter build web --release --dart-define=API_BASE_URL=https://api.tu-dominio.com
```
Los archivos estáticos listos para desplegar en S3/CloudFront o Firebase Hosting quedarán en `build/web/`.

### Generar APK para Android
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.tu-dominio.com
```
El archivo APK generado quedará en `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🧪 Pruebas Automáticas

Ejecutar la suite completa de unit y widget tests (180+ tests):

```bash
flutter test
```

---

## 🏗️ Arquitectura y Estructura

El proyecto sigue la arquitectura **MVVM (Model-View-ViewModel)** con gestión de estado mediante `Provider`:

```text
lib/
├── core/         # Configuración y ApiConfig (--dart-define)
├── models/       # Modelos de dominio (AnalysisResult, CapturedMedia) y DTOs API
├── services/     # HttpClient, PlatformService, VideoCaptureService, StorageService
├── repositories/ # AnalysisRepository, UploadRepository, CaptureRepository
├── viewmodels/   # ViewModels (ChangeNotifier) y snapshots inmutables de estado
├── views/        # Pantallas (WebLandingScreen, SplashScreen, HomeScreen, AnalysisScreen)
└── widgets/      # Widgets reutilizables (Disclaimer, TrafficLight, PhoneMockup, Logo)
```
