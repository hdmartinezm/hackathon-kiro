# 📱 Asignación: Francisco (Frontend Lead)

**Rol:** Frontend Flutter (UI/Pantallas)
**GitHub:** FranciscoJTHG
**Email:** franthielengaravito@gmail.com
**Rama base:** `dev`
**Convención de ramas:** `feat/ui-*` o `feat/screen-*`

---

## Resumen de Responsabilidades

Eres responsable de todas las pantallas de la app Flutter: splash, home, cámara, audio, resultados. Implementas la UI basándote en los mockups de Alvaro y consumes los servicios que William prepara. Tu foco es la experiencia de usuario.

---

## Distribución por Día

| Día | Entregable | Estado |
|-----|-----------|--------|
| **D1** | Setup Flutter + estructura base | ⬜ |
| **D2** | HomeScreen completa | ⬜ |
| **D3** | CameraScreen | ⬜ |
| **D4** | ResultScreen (visual + audio) | ⬜ |
| **D5** | Animaciones y micro-interacciones | ⬜ |
| **D6** | Fix bugs de UI | ⬜ |
| **D7** | Soporte en presentación | ⬜ |

---

## Día 1: Setup Flutter + Estructura Base

### Objetivos
- Proyecto Flutter configurado y corriendo
- Estructura de carpetas establecida
- Navegación entre pantallas configurada
- Splash screen con disclaimer funcional

### Tareas Específicas (del spec)

**Task 8: Flutter App - Estructura Base**
- [ ] 8.1 Crear `flutter_app/lib/config/app_config.dart` con URL base de API y constantes
- [ ] 8.4 Crear `flutter_app/lib/screens/splash_screen.dart` con disclaimer médico y animación
- [ ] 8.6 Configurar navegación: splash → home → cámara/audio → resultado

**Task 8 (modelos)**
- [ ] 8.2 Crear `flutter_app/lib/models/analysis_result.dart` (fromJson/toJson)
- [ ] 8.3 Crear `flutter_app/lib/models/audio_result.dart` (fromJson/toJson)

### Modelos de Datos

**analysis_result.dart**
```dart
class AnalysisResult {
  final String sessionId;
  final String estadoGeneral; // "normal" | "requiere_atencion" | "urgente"
  final List<String> observaciones;
  final List<String> recomendaciones;
  final double confianza; // 0.0 - 1.0
  final String disclaimer;
  final DateTime timestamp;

  factory AnalysisResult.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

**audio_result.dart**
```dart
class AudioResult {
  final String category;  // "hungry", "pain", "fatigue", etc.
  final String label;     // "Hambre", "Dolor", "Cansancio", etc.
  final double confidence;
  final String recommendation;

  factory AudioResult.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
}
```

### Texto del Disclaimer (obligatorio en splash)
```
"BabyHealth es una herramienta de orientación. Los resultados son 
informativos y NO sustituyen la consulta con un profesional de la 
salud. Ante cualquier duda o emergencia, consulte a su pediatra 
o acuda a urgencias."
```

### Entregables del Día
```
✅ Flutter app corre sin errores en emulador
✅ Splash screen muestra disclaimer y navega a Home
✅ Navegación configurada entre todas las pantallas (aunque vacías)
✅ Modelos de datos definidos
✅ Commit: feat: setup flutter base + splash screen
```

---

## Día 2: HomeScreen

### Objetivos
- Pantalla principal con las dos opciones de análisis
- Disclaimer visible en footer
- Diseño limpio basado en mockups de Alvaro

### Tareas Específicas

**Task 8.5: Home Screen**
- [ ] Crear `flutter_app/lib/screens/home_screen.dart`
- [ ] Dos opciones claras: "Analizar Foto" y "Analizar Audio"
- [ ] Footer con disclaimer médico (siempre visible)
- [ ] Logo/branding de BabyHealth en la parte superior

### Wireframe de Referencia
```
┌──────────────────────────┐
│      🍼 BabyHealth       │
│                          │
│   ¿Cómo te puedo ayudar? │
│                          │
│  ┌────────────────────┐  │
│  │  📸 Analizar Foto  │  │
│  │  Detecta ictericia │  │
│  └────────────────────┘  │
│                          │
│  ┌────────────────────┐  │
│  │  🎤 Analizar Audio │  │
│  │  Clasifica llanto  │  │
│  └────────────────────┘  │
│                          │
│                          │
│  ⚠️ Disclaimer médico   │
└──────────────────────────┘
```

### Widget Reutilizable del Disclaimer

**Task 12.2: Disclaimer Widget**
- [ ] Crear `flutter_app/lib/widgets/disclaimer_widget.dart`

```dart
class DisclaimerWidget extends StatelessWidget {
  // Texto completo del disclaimer
  // Estilo: texto pequeño, gris, con icono ⚠️
  // Reutilizable en splash, home, y results
}
```

### Entregables del Día
```
✅ HomeScreen con dos opciones de análisis
✅ DisclaimerWidget reutilizable creado
✅ Footer disclaimer visible en Home
✅ Navegación Home → Camera y Home → Audio funcionan
✅ Commit: feat: home screen + disclaimer widget
```

---

## Día 3: CameraScreen

### Objetivos
- Pantalla de cámara con preview en tiempo real
- Botón de captura
- Indicador de carga mientras se procesa

### Tareas Específicas

**Task 9.3: Camera Screen**
- [ ] Crear `flutter_app/lib/screens/camera_screen.dart`
- [ ] Preview de cámara en tiempo real
- [ ] Botón de captura centrado abajo
- [ ] Indicador de progreso después de capturar:
  - "Subiendo imagen..."
  - "Analizando..."
  - Spinner/animación

**Task 11.4: Audio Screen**
- [ ] Crear `flutter_app/lib/screens/audio_screen.dart`
- [ ] Indicador de grabación (micrófono animado)
- [ ] Countdown circular de 7 segundos
- [ ] Estado: "Grabando..." → "Analizando..." → Resultado

### Wireframe Camera
```
┌──────────────────────────┐
│  ← Volver                │
│                          │
│  ┌────────────────────┐  │
│  │                    │  │
│  │   PREVIEW CÁMARA   │  │
│  │                    │  │
│  │                    │  │
│  └────────────────────┘  │
│                          │
│  💡 Asegúrate de buena   │
│     iluminación          │
│                          │
│        [ 📸 ]            │
│                          │
└──────────────────────────┘
```

### Wireframe Audio
```
┌──────────────────────────┐
│  ← Volver                │
│                          │
│                          │
│        🎤                │
│                          │
│     ┌─────────┐          │
│     │  0:07   │          │
│     │   ◯     │  ← countdown circular
│     └─────────┘          │
│                          │
│   Grabando llanto...     │
│                          │
│   Acerca el micrófono    │
│   al bebé               │
│                          │
└──────────────────────────┘
```

### Entregables del Día
```
✅ CameraScreen con preview funcional
✅ AudioScreen con countdown de 7 segundos
✅ Loading states implementados
✅ Conectado con servicios de William (camera_service, audio_service)
✅ Commit: feat: camera + audio screens
```

---

## Día 4: ResultScreen

### Objetivos
- Pantalla de resultado visual con semáforo
- Pantalla de resultado audio con categoría
- Ambas con disclaimer y botones de acción

### Tareas Específicas

**Task 12: Pantallas de Resultado**
- [ ] 12.1 Crear `flutter_app/lib/widgets/traffic_light_widget.dart` (semáforo)
- [ ] 12.3 Crear `flutter_app/lib/widgets/confidence_bar.dart` (barra confianza)
- [ ] 12.4 Crear `flutter_app/lib/screens/result_screen.dart` (visual)
- [ ] 12.5 Crear `flutter_app/lib/screens/audio_result_screen.dart` (audio)
- [ ] 12.6 Resaltado visual cuando estado es "urgente"
- [ ] 12.7 Botones "Nuevo Análisis" y "Contactar Pediatra"

### Semáforo Widget

```dart
class TrafficLightWidget extends StatelessWidget {
  final String estado; // "normal", "requiere_atencion", "urgente"
  
  // Verde = normal
  // Amarillo = requiere_atencion
  // Rojo = urgente
  
  // Incluye icono y texto del estado
}
```

### Barra de Confianza

```dart
class ConfidenceBar extends StatelessWidget {
  final double confidence; // 0.0 - 1.0
  
  // Barra horizontal con porcentaje
  // Color varía según nivel
}
```

### Wireframe Result Visual
```
┌──────────────────────────┐
│                          │
│      🟢 NORMAL           │
│   Estado de tu bebé      │
│                          │
│  Observaciones:          │
│  • Coloración normal     │
│  • Expresión tranquila   │
│                          │
│  Recomendaciones:        │
│  • Monitoreo regular     │
│  • Si nota cambios,      │
│    consulte pediatra     │
│                          │
│  Confianza: ████████░ 87%│
│                          │
│  [  🔄 Nuevo Análisis  ]│
│  [  📞 Contactar Pediatra]│
│                          │
│  ⚠️ Disclaimer médico   │
└──────────────────────────┘
```

### Wireframe Result Audio
```
┌──────────────────────────┐
│                          │
│      🍼 HAMBRE           │
│   Tipo de llanto         │
│                          │
│  Recomendación:          │
│  Ofrecer alimentación    │
│                          │
│  Confianza: ██████░ 82%  │
│                          │
│  [  🎤 Grabar de Nuevo ]│
│                          │
│  ⚠️ Disclaimer médico   │
└──────────────────────────┘
```

### Categorías de Audio (referencia)

| Category | Label | Recomendación |
|----------|-------|---------------|
| hungry | Hambre | Ofrecer alimentación |
| pain | Dolor | Revisar, consultar si persiste |
| fatigue | Cansancio | Ambiente tranquilo, dormir |
| discomfort | Incomodidad | Revisar pañal, posición, ropa |
| burp | Eructo | Sostener vertical, palmaditas |
| temperature | Temperatura | Verificar si tiene frío/calor |
| fear | Miedo | Contacto, voz suave, mecer |
| loneliness | Soledad | Contacto físico, presencia |
| unknown | Desconocido | Intentar de nuevo en ambiente silencioso |

### Entregables del Día
```
✅ ResultScreen visual con semáforo funcional
✅ AudioResultScreen con categoría y recomendación
✅ ConfidenceBar mostrando porcentaje
✅ Botones de acción funcionan (navegan correctamente)
✅ Disclaimer visible en ambas pantallas
✅ Commit: feat: result screens + widgets
```

---

## Día 5: Animaciones

### Objetivos
- Micro-animaciones para mejorar UX
- Transiciones suaves entre pantallas
- Feedback visual durante la carga

### Animaciones a Implementar
- [ ] Transición suave splash → home (fade)
- [ ] Semáforo: animación de "encendido" al aparecer resultado
- [ ] Barra de confianza: animación de llenado progresivo
- [ ] Countdown audio: animación circular fluida
- [ ] Botón captura: feedback visual al presionar
- [ ] Loading: shimmer o pulse animation mientras analiza
- [ ] Estado urgente: borde pulsante rojo en las recomendaciones

### Entregables del Día
```
✅ Animaciones implementadas sin afectar performance
✅ UX fluida y responsive
✅ App se siente "pulida"
```

---

## Día 6: Fix Bugs de UI

### Objetivos
- Resolver bugs visuales reportados por William en testing
- Ajustar responsive en diferentes tamaños de pantalla
- Verificar accesibilidad básica

### Checklist
- [ ] Textos no se cortan en pantallas pequeñas
- [ ] Colores del semáforo correctos
- [ ] Disclaimer legible
- [ ] Botones tienen tamaño touch adecuado (mínimo 44x44)
- [ ] No hay overflow de texto
- [ ] Orientación portrait forzada
- [ ] Estado "urgente" se distingue claramente

---

## Día 7: Soporte

- [ ] App estable para demo
- [ ] Screenshots de cada pantalla para las slides de Alvaro
- [ ] Disponible para fix de último minuto

---

## Estructura de Archivos (tu dominio)

```
flutter_app/lib/
├── main.dart
├── config/
│   └── app_config.dart          ← Constantes, URL API
├── models/
│   ├── analysis_result.dart     ← Modelo resultado visual
│   └── audio_result.dart        ← Modelo resultado audio
├── screens/
│   ├── splash_screen.dart       ← D1
│   ├── home_screen.dart         ← D2
│   ├── camera_screen.dart       ← D3
│   ├── audio_screen.dart        ← D3
│   ├── result_screen.dart       ← D4
│   └── audio_result_screen.dart ← D4
├── services/                    ← William los crea, tú los consumes
│   ├── api_service.dart
│   ├── camera_service.dart
│   └── audio_service.dart
└── widgets/
    ├── disclaimer_widget.dart   ← D2
    ├── traffic_light_widget.dart← D4
    └── confidence_bar.dart      ← D4
```

---

## Importante: Disclaimer Médico

El disclaimer DEBE aparecer en:
1. ✅ Splash screen (texto completo + aceptar)
2. ✅ Home screen (footer)
3. ✅ Result screen visual
4. ✅ Result screen audio

**Texto completo:**
> "BabyHealth es una herramienta de orientación. Los resultados son informativos y NO sustituyen la consulta con un profesional de la salud. Ante cualquier duda o emergencia, consulte a su pediatra o acuda a urgencias."

---

## Contactos para Coordinación

| Necesito de... | Para... |
|----------------|---------|
| William | api_service.dart y camera_service.dart listos para consumir |
| Alvaro | Mockups, paleta de colores, tema, iconos |
| Hector | Formato exacto de las responses JSON |
