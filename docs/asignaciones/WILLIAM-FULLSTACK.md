# 🔗 Asignación: William (Fullstack / Coordinador)

**Rol:** Coordinador + Fullstack (conecta frontend ↔ backend)
**GitHub:** izquierdowaws
**Email:** izquierdowo@gmail.com
**Rama base:** `dev`
**Convención de ramas:** `feat/integration-*` o `feat/services-*`

---

## Resumen de Responsabilidades

Eres el puente entre frontend y backend. Te encargas de los servicios Flutter que se comunican con la API, la integración end-to-end, el testing final, y la coordinación general del equipo (Trello, merges, standups).

---

## Distribución por Día

| Día | Entregable | Estado |
|-----|-----------|--------|
| **D1** | Ayudar setup (repo, CDK, Flutter) | ⬜ |
| **D2** | Servicios Flutter (api_service, camera_service, audio_service) | ⬜ |
| **D3** | Integrar servicios con UI | ⬜ |
| **D4** | Conectar E2E (flujo completo funcional) | ⬜ |
| **D5** | Testing funcional | ⬜ |
| **D6** | Testing final + fix bugs | ⬜ |
| **D7** | Soporte en presentación | ⬜ |

---

## Día 1: Ayudar Setup

### Objetivos
- Asegurar que todo el equipo tiene el entorno funcionando
- Verificar acceso AWS para todos
- Actualizar Trello con las tareas del spec

### Actividades
- [ ] Verificar que todos pueden clonar, instalar y correr el proyecto
- [ ] Ayudar a Hector con deploy CDK si necesita
- [ ] Configurar proyecto Flutter base (pubspec.yaml con dependencias)
- [ ] Crear cards en Trello basadas en las tareas del spec
- [ ] Verificar acceso a AWS Console para el equipo
- [ ] Compartir URL de API Gateway cuando esté disponible

### Dependencias Flutter a configurar
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  camera: ^0.10.5
  path_provider: ^2.1.0
  uuid: ^4.0.0
  # iOS audio (DeepInfant)
  # Android audio (tflite_flutter)
```

### Entregables del Día
```
✅ Todo el equipo con entorno funcional
✅ Trello actualizado con tareas asignadas
✅ Flutter project con dependencias base
✅ Primer standup realizado
```

---

## Día 2: Servicios Flutter

### Objetivos
- Crear la capa de servicios que conecta la UI con el backend
- Implementar api_service, camera_service y audio_service
- Estos servicios serán consumidos por las pantallas de Francisco

### Tareas Específicas (del spec)

**Task 9: Módulo de Cámara y Upload**
- [ ] 9.1 Crear `flutter_app/lib/services/camera_service.dart` con captura de imagen y validación local básica
- [ ] 9.2 Crear `flutter_app/lib/services/api_service.dart` con métodos para:
  - `getUploadUrl(fileType, sessionId)` → POST /upload-url
  - `uploadImage(url, imageBytes)` → PUT a S3
  - `analyzeImage(s3Key, sessionId)` → POST /analyze
  - `analyzeAudio(s3Key)` → POST /analyze-audio

**Task 11: Módulo de Audio**
- [ ] 11.1 Crear `flutter_app/lib/services/audio_service.dart` con grabación de 7 segundos

### api_service.dart — Interfaz

```dart
class ApiService {
  static const String baseUrl = 'https://{api-id}.execute-api.us-east-1.amazonaws.com/prod';

  // Solicitar URL pre-firmada
  Future<UploadUrlResponse> getUploadUrl(String fileType, String sessionId);
  
  // Subir imagen directamente a S3
  Future<void> uploadToS3(String uploadUrl, Uint8List imageBytes);
  
  // Analizar imagen
  Future<AnalysisResult> analyzeImage(String s3Key, String sessionId);
  
  // Analizar audio (Android)
  Future<AudioResult> analyzeAudio(String s3Key);
}
```

### camera_service.dart — Interfaz

```dart
class CameraService {
  // Capturar imagen desde cámara
  Future<Uint8List?> captureImage();
  
  // Validación local básica (tamaño, formato)
  bool validateImage(Uint8List imageData);
}
```

### audio_service.dart — Interfaz

```dart
class AudioService {
  // Grabar 7 segundos de audio
  Future<Uint8List> recordAudio({Duration duration = const Duration(seconds: 7)});
  
  // Clasificar con DeepInfant (iOS)
  Future<AudioResult?> classifyOnDevice(Uint8List audioData);
  
  // Detectar llanto con YAMNet (Android)  
  Future<bool> detectCry(Uint8List audioData);
}
```

### Entregables del Día
```
✅ api_service.dart funcional (probado con curl/Postman contra API de Hector)
✅ camera_service.dart con captura básica
✅ audio_service.dart con grabación de 7s
✅ Servicios disponibles para que Francisco los use en las pantallas
```

---

## Día 3: Integrar Servicios con UI

### Objetivos
- Conectar los servicios con las pantallas que Francisco está construyendo
- Implementar el flujo completo de cámara → análisis
- Implementar manejo de errores de red

### Tareas Específicas

**Task 9 (continuación)**
- [ ] 9.4 Implementar flujo completo: captura → URL pre-firmada → upload S3 → /analyze
- [ ] 9.5 Manejo de error de conexión con opción de reintento
- [ ] 9.6 Renovación automática de URL pre-firmada si expira

**Task 11 (continuación)**
- [ ] 11.2 Integración con DeepInfant CoreML para iOS (clasificación on-device)
- [ ] 11.3 Integración con YAMNet TFLite para Android (detección de llanto)
- [ ] 11.5 Lógica de umbral de confianza: si confidence < 0.5 → categoría "desconocido"
- [ ] 11.6 Eliminación del buffer de audio inmediatamente después de clasificación (iOS)
- [ ] 11.7 Flujo Android: YAMNet detecta → si llanto → upload espectrograma → /analyze-audio

### Flujo Visual End-to-End
```
[Francisco: CameraScreen] 
    → captureImage() [William: camera_service]
    → getUploadUrl() [William: api_service]
    → uploadToS3() [William: api_service]  
    → analyzeImage() [William: api_service]
    → [Hector: Backend /analyze]
    → AnalysisResult
[Francisco: ResultScreen muestra resultado]
```

### Entregables del Día
```
✅ Flujo imagen funciona end-to-end en emulador
✅ Flujo audio iOS clasificación on-device funciona
✅ Flujo audio Android detecta llanto y clasifica
✅ Errores de red mostrados con UI amigable
```

---

## Día 4: Conectar E2E

### Objetivos
- Toda la app funciona de punta a punta con la API real
- Verificar todos los casos de uso principales
- Resolver bugs de integración

### Casos de Prueba a Verificar

| # | Caso | Resultado Esperado |
|---|------|-------------------|
| CP1 | Foto normal → análisis | estado="normal", < 5s |
| CP2 | Foto amarillenta → análisis | estado="requiere_atencion" |
| CP3 | Audio llanto iOS | Categoría + confianza > 0.7 |
| CP4 | Audio sin llanto | "No se detecta llanto" |
| CP5 | iOS sin internet → audio | Funciona offline |
| CP6 | Foto borrosa | Error amigable, pide nueva foto |

### Entregables del Día
```
✅ Todos los CP verificados manualmente
✅ Bugs reportados y/o corregidos
✅ App funcional en dispositivo real (si es posible)
✅ Compartir estado en #general
```

---

## Día 5: Testing

### Objetivos
- Testing exhaustivo de todos los flujos
- Documentar bugs encontrados
- Asegurar estabilidad para la demo

### Actividades
- [ ] Probar en iOS simulator y Android emulator
- [ ] Probar con conexión lenta (throttling)
- [ ] Probar caso offline (audio iOS)
- [ ] Verificar disclaimer visible en todas las pantallas
- [ ] Verificar semáforo muestra colores correctos
- [ ] Medir latencia real end-to-end
- [ ] Documentar cualquier bug en Trello con etiqueta 🔴

---

## Día 6: Testing Final + Bugs

### Objetivos
- Resolver bugs críticos restantes
- Smoke test completo antes de la demo
- Asegurar que la app no crashea

### Checklist Final
- [ ] App abre sin crash
- [ ] Splash muestra disclaimer
- [ ] Captura foto funciona
- [ ] Upload y análisis completa sin error
- [ ] Resultado visual correcto (semáforo, observaciones)
- [ ] Grabación audio funciona
- [ ] Clasificación audio retorna resultado
- [ ] Botones "Nuevo Análisis" y "Contactar Pediatra" funcionan
- [ ] No hay pantallas blancas o errores sin manejar

---

## Día 7: Soporte Presentación

- [ ] Tener la app lista en un dispositivo para demo en vivo
- [ ] Backup: screenshots/video del flujo funcionando
- [ ] Estar disponible para resolver problemas técnicos de último minuto
- [ ] Hacer merge final a `main` si todo está listo

---

## Responsabilidades de Coordinación

### Trello
- Actualizar cards al inicio de cada día
- Mover tareas entre columnas
- Reportar bloqueos inmediatamente

### Merges
- Revisar PRs de Francisco y Alvaro
- Hacer merge a `dev` cuando estén listos
- Merge a `main` solo cuando todo funciona

### Standups (cada 4-6 horas)
```
🟢 HECHO: [qué completaste]
🔵 HACIENDO: [en qué estás ahora]
🔴 BLOQUEADO: [qué te detiene]
```

---

## Contactos para Coordinación

| Necesito de... | Para... |
|----------------|---------|
| Hector | URL de API Gateway, resolver errores de backend |
| Francisco | Pantallas listas para conectar servicios |
| Alvaro | Assets exportados para integrar en la app |
