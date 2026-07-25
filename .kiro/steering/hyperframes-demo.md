---
inclusion: manual
---

# HyperFrames Demo — Flujo de Trabajo BabyHealth

Este steering define la secuencia de trabajo para generar presentaciones y videos demo del proyecto BabyHealth usando HyperFrames. Sigue los pasos en orden estricto.

---

## Convención de Carpetas por Demo

Cada demo/presentación generada debe vivir en su **propia carpeta** dentro de `assets/hyperframes/` con el siguiente formato de nombre:

```
assets/hyperframes/babyhealth-demo-NNN/
```

**Reglas de versionado de carpeta:**
- Formato: `babyhealth-demo-NNN` donde NNN es un número consecutivo de 3 dígitos
- Para determinar el siguiente número, lista las carpetas existentes en `assets/hyperframes/` que coincidan con el patrón `babyhealth-demo-*` y usa el siguiente consecutivo
- Si no hay carpetas previas, inicia con `babyhealth-demo-001`
- Si solo existe `babyhealth-demo/` (sin número), trátala como la versión legacy y crea la siguiente como `babyhealth-demo-001`
- Ejemplo: si existen `babyhealth-demo/` y `babyhealth-demo-001/`, la siguiente es `babyhealth-demo-002`

**Estructura interna de cada carpeta de demo:**

```
assets/hyperframes/babyhealth-demo-NNN/
├── compositions/           # Composiciones HTML de HyperFrames
│   └── *.html
├── index.html              # Composición principal (copia de la composición activa)
├── package.json            # Config del proyecto HyperFrames
├── hyperframes.json        # Metadata de composiciones
├── CONTEXTO-DEMO.md        # Contexto generado en Paso 1
└── GUION-DEMO.md           # Guion generado en Paso 4
```

El video MP4 resultante se deposita en `assets/video/` con el **mismo número consecutivo** que la carpeta:

```
assets/video/BabyHealth-demo-NNN.mp4
```

Esto mantiene la trazabilidad: `babyhealth-demo-003/` → `BabyHealth-demo-003.mp4`.

---

## Pistas de Audio / Música de Fondo

Las presentaciones pueden incluir pistas de audio (música de fondo, efectos de sonido, narración). Los archivos de audio se gestionan así:

### Ubicación de archivos de audio

Todos los archivos de audio deben estar en:

```
assets/sounds/
```

**Formatos soportados:** `.mp3`, `.wav`, `.ogg`, `.m4a`, `.aac`

### Flujo de trabajo con audio

1. **Verificar disponibilidad:** En el Paso 2 (consulta al desarrollador), preguntar si desea incluir música/audio en la presentación.

2. **Notificar al desarrollador:** Si el desarrollador confirma que quiere audio, **SIEMPRE notificarle** que debe colocar los archivos de audio en `assets/sounds/` antes de proceder con el render. Mostrar este mensaje:

   > ⚠️ **Acción requerida:** Para incluir audio en la presentación, coloca los archivos de música en `assets/sounds/`. Formatos aceptados: `.mp3`, `.wav`, `.ogg`, `.m4a`, `.aac`.
   >
   > Ejemplos de nombres sugeridos:
   > - `background-music.mp3` — Música de fondo principal
   > - `intro-jingle.mp3` — Jingle de entrada
   > - `transition-sound.wav` — Efecto de transición
   > - `narration-es.mp3` — Narración en español
   >
   > Avísame cuando los archivos estén listos para continuar.

3. **Esperar confirmación:** No proceder con la composición HTML hasta que el desarrollador confirme que los archivos están en su lugar.

4. **Validar existencia:** Antes de referenciar un audio en la composición, verificar que el archivo existe en `assets/sounds/`.

5. **Integrar en la composición HTML:** Usar la etiqueta `<audio>` con `data-*` attributes de HyperFrames para sincronizar con la timeline:

   ```html
   <!-- Música de fondo - se reproduce durante toda la presentación -->
   <audio id="bg-music"
          src="../../../sounds/background-music.mp3"
          data-enter="0"
          data-exit="240"
          data-volume="0.3"
          data-fade-in="2"
          data-fade-out="3">
   </audio>

   <!-- Efecto puntual en una escena específica -->
   <audio id="sfx-transition"
          src="../../../sounds/transition-sound.wav"
          data-enter="20"
          data-exit="21"
          data-volume="0.6">
   </audio>
   ```

6. **Documentar en el guion:** El `GUION-DEMO.md` debe incluir una sección de audio que indique:
   - Qué pistas se usan
   - En qué momentos entran/salen
   - Nivel de volumen relativo
   - Fade in/out

### Opciones de audio en el Paso 2

Al consultar al desarrollador, ofrecer estas opciones:

| Opción | Descripción |
|--------|-------------|
| `sin-audio` | Presentación silenciosa (solo visual) |
| `musica-fondo` | Música ambient/corporativa de fondo durante toda la presentación |
| `musica-por-escena` | Diferentes pistas según la escena (hook dramático, cuerpo suave, cierre épico) |
| `narración` | Voice-over narrado (el desarrollador provee el archivo de narración) |
| `completo` | Música de fondo + efectos de transición + narración |

### Ruta relativa desde la composición

Dado que las composiciones viven en `assets/hyperframes/babyhealth-demo-NNN/compositions/`, la ruta relativa a los archivos de audio es:

```
../../../sounds/nombre-archivo.mp3
```

Si el audio se copia dentro de la carpeta de la demo (para portabilidad), usar:

```
./audio/nombre-archivo.mp3
```

En ese caso, crear una subcarpeta `audio/` dentro de la demo y copiar ahí los archivos referenciados.

---

## Secuencia de Trabajo

### Paso 0: Determinar Versión

Antes de comenzar, determina el número de versión:

1. Lista carpetas en `assets/hyperframes/` que coincidan con `babyhealth-demo-*`
2. Extrae el número más alto existente
3. Incrementa en 1 para la nueva demo
4. Crea la carpeta `assets/hyperframes/babyhealth-demo-NNN/` con su estructura interna

### Paso 1: Análisis Completo y Generación de Contexto

Realiza un análisis exhaustivo del proyecto y genera el documento de contexto **dentro de la carpeta de la demo**:

```
assets/hyperframes/babyhealth-demo-NNN/CONTEXTO-DEMO.md
```

Estructura del documento:

```markdown
# Contexto de Presentación — BabyHealth (Demo NNN)

## Objetivo de la Aplicación
[Describir qué problema resuelve BabyHealth y para quién]

## Contexto Histórico
[Cuándo se creó, en qué hackathon, motivación original]

## Retos a Cubrir
[Desafíos técnicos y de producto que se resolvieron]

## Valor a Entregar
[Propuesta de valor para el usuario final]

## Stack Tecnológico
[Resumen del stack completo: frontend, backend, infra, IA]

## Equipo de Trabajo
[Nombre, rol, y responsabilidades de cada persona]
```

Fuentes para generar este contexto:
- #[[file:README.md]]
- #[[file:ESTRUCTURA-EQUIPO.md]]
- #[[file:RESUMEN-EQUIPO.md]]
- Código fuente del backend (`backend/app/`) y frontend (`frontend/lib/`)
- Infraestructura (`infra/`)

### Paso 2: Consulta al Desarrollador

**SIEMPRE pregunta al desarrollador antes de proceder con la generación:**

1. **Duración estimada** de la presentación (en segundos o minutos)
2. **Contexto o audiencia** — ¿Para quién es? (jueces de hackathon, inversionistas, equipo interno, público general)
3. **Tipo de presentación** — Opciones sugeridas:
   - `demo-tecnica` — Muestra funcionalidades en acción con énfasis técnico
   - `pitch` — Enfocada en problema/solución/valor para audiencia no técnica
   - `overview` — Recorrido general balanceado entre técnico y valor de negocio
   - `custom` — El desarrollador describe el formato deseado
4. **Audio** — ¿Incluir pistas de sonido? Opciones:
   - `sin-audio` — Solo visual
   - `musica-fondo` — Música ambient durante toda la presentación
   - `musica-por-escena` — Diferentes pistas por escena
   - `narración` — Voice-over (el desarrollador provee el archivo)
   - `completo` — Música + efectos + narración

Si el desarrollador elige cualquier opción con audio, **notificar inmediatamente** que debe depositar los archivos en `assets/sounds/` y esperar confirmación antes de continuar.

### Paso 3: Generación de la Página Web (Composición HTML)

Genera la composición HTML de HyperFrames en:

```
assets/hyperframes/babyhealth-demo-NNN/compositions/
```

La composición debe:
- Usar el contexto generado en el Paso 1 como contenido
- Respetar la duración solicitada en el Paso 2
- Adaptar tono y estructura al tipo de presentación elegido
- Incluir los colores de la marca BabyHealth (verde salud, tonos cálidos)
- Seguir el contrato de composición de HyperFrames (data-* attributes, timeline seekable)
- Usar `id="root"` en el elemento raíz (no class) para compatibilidad con el runtime
- Agregar IDs únicos a cada escena (e.g. `id="scene-hook"`)
- Declarar fuentes con `@font-face` (no `@import` de Google Fonts)
- **Si se eligió audio:** Incluir elementos `<audio>` con las pistas referenciadas y sincronizadas con la timeline

Además, copiar la composición principal como `index.html` en la raíz de la carpeta de demo para que `hyperframes check` funcione.

### Paso 4: Guion de la Presentación

Genera un guion detallado **dentro de la carpeta de la demo**:

```
assets/hyperframes/babyhealth-demo-NNN/GUION-DEMO.md
```

El guion debe contener:
- **Escena por escena** con tiempos de entrada/salida
- **Narración** (texto que podría leerse o usarse como voice-over)
- **Elementos visuales** que aparecen en cada momento
- **Transiciones** entre escenas
- **Notas de producción** (énfasis, pausas, timing)
- **Especificaciones técnicas** (resolución, FPS, paleta de colores, tipografía)
- **Pistas de audio** (si aplica):
  - Archivo utilizado
  - Tiempo de entrada/salida
  - Volumen
  - Fade in/out
  - Propósito (fondo, efecto, narración)

### Paso 5: Generación del Video MP4

Genera el video final y deposítalo en:

```
assets/video/BabyHealth-demo-NNN.mp4
```

Usa el mismo número NNN de la carpeta para mantener trazabilidad.

**Proceso de render:**
1. Ejecutar `npx hyperframes check` en la carpeta de la demo para validar
2. Ejecutar `npx hyperframes render . --output <ruta_video> --fps 30 --quality standard`
3. Verificar que el archivo MP4 se generó correctamente
4. Si tiene audio, verificar que la pista se incluyó en el render (el render de HyperFrames mezcla audio automáticamente si los `<audio>` están bien configurados)

---

## Resumen del Flujo

```
0. Determinar versión NNN → crear carpeta babyhealth-demo-NNN/
1. Analizar proyecto → babyhealth-demo-NNN/CONTEXTO-DEMO.md
2. Preguntar al dev → duración, audiencia, tipo, audio
   └── Si audio → notificar: depositar archivos en assets/sounds/ → esperar confirmación
3. Generar composición HTML → babyhealth-demo-NNN/compositions/ + index.html
   └── Si audio → incluir <audio> elements sincronizados con timeline
4. Escribir guion → babyhealth-demo-NNN/GUION-DEMO.md
   └── Si audio → documentar pistas, tiempos y volúmenes
5. Renderizar video → assets/video/BabyHealth-demo-NNN.mp4
```

---

## Información del Proyecto (referencia rápida)

- **App:** BabyHealth — orientación de salud infantil con IA multimodal
- **Stack:** Flutter Web + FastAPI + AWS (Lambda, Bedrock, Cognito, S3, DynamoDB)
- **IA:** AWS Bedrock (Claude Sonnet) y Google Gemini
- **Equipo:** Hector (Coordinador+Backend), Alvaro (Diseño+Frontend), William (Fullstack), Francisco (Frontend)
- **URL:** https://babyhealth.hmartinez.info
- **Repo:** https://github.com/hdmartinezm/hackathon-kiro
