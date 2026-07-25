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
├── images/                 # Imágenes usadas en la presentación web
│   └── *.png, *.jpg, *.svg, *.webp
├── media/                  # Recursos multimedia del proyecto
│   ├── sound/             # Archivos de audio (música, efectos, narración)
│   │   └── *.mp3
│   └── video/             # Clips de video auxiliares (si aplica)
│       └── *.mp4
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

## Imágenes de la Presentación

Las composiciones HTML pueden incluir imágenes (logos, capturas de pantalla, íconos, ilustraciones, mockups). Todas las imágenes se almacenan dentro de la carpeta de la demo.

### Ubicación de imágenes

```
assets/hyperframes/babyhealth-demo-NNN/images/
```

**Formatos soportados:** `.png`, `.jpg`, `.jpeg`, `.svg`, `.webp`, `.gif`

### Convención de nombres

Usar nombres descriptivos en kebab-case:

```
images/logo-babyhealth.svg
images/screenshot-home.png
images/mockup-analysis-screen.png
images/icon-semaforo-verde.svg
images/team-photo.jpg
images/architecture-diagram.png
```

### Ruta en la composición HTML

Desde `index.html` o composiciones:

```html
<img id="logo" src="images/logo-babyhealth.svg" alt="BabyHealth logo" />
<img id="screenshot-1" src="images/screenshot-home.png" alt="Home screen" />
```

### Uso recomendado

- **Logos y branding** — SVG preferido para escalabilidad
- **Capturas de pantalla** — PNG para calidad, WebP para menor tamaño
- **Mockups de la app** — Capturas reales de la app en funcionamiento
- **Diagramas** — Arquitectura, flujos, exportados como PNG/SVG
- **Fotos del equipo** — JPG optimizado

### Integración con el flujo

En el Paso 3 (generación de la composición HTML):
- Si la presentación requiere imágenes (screenshots, logos, mockups), colocarlas en `images/`
- Referenciar con ruta root-relative: `images/nombre.ext`
- Agregar atributos `alt` descriptivos en cada `<img>` para accesibilidad

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

5. **Integrar en la composición HTML:** Usar la etiqueta `<audio>` con `data-*` attributes de HyperFrames para sincronizar con la timeline.

   **⚠️ IMPORTANTE — Usar audio en LOOP para evitar cortes abruptos:**

   Cuando la duración del archivo de audio es **menor** que la duración del slot asignado (`data-duration`), el renderer de HyperFrames trunca el slot a la longitud del archivo, dejando silencio después. Para evitar esto, **SIEMPRE usar `data-loop="true"`** en audios de fondo que deban cubrir un tramo mayor a su duración real.

   **Regla:** Si `data-duration > duración_real_del_archivo`, agregar `data-loop="true"`.

   ```html
   <!-- Música de fondo con LOOP - cubre toda la presentación sin cortes -->
   <audio id="bg-music"
          src="media/sound/background-music.mp3"
          data-start="0"
          data-duration="240"
          data-volume="0.25"
          data-fade-in="2"
          data-fade-out="3"
          data-loop="true">
   </audio>

   <!-- Dos pistas con crossfade y loop para cobertura completa -->
   <audio id="audio-track-1"
          src="media/sound/track-a.mp3"
          data-start="0"
          data-duration="120"
          data-volume="0.25"
          data-fade-in="2"
          data-fade-out="3"
          data-loop="true">
   </audio>
   <audio id="audio-track-2"
          src="media/sound/track-b.mp3"
          data-start="118"
          data-duration="122"
          data-volume="0.25"
          data-fade-in="2"
          data-fade-out="4"
          data-loop="true">
   </audio>

   <!-- Efecto puntual (sin loop, duración corta) -->
   <audio id="sfx-transition"
          src="media/sound/transition-sound.wav"
          data-start="20"
          data-duration="2"
          data-volume="0.6">
   </audio>
   ```

   **Notas técnicas sobre loop:**
   - `data-loop="true"` repite el audio desde el inicio cuando termina, sin gaps
   - El fade-out se aplica al final del `data-duration`, no al final de cada repetición
   - Para transiciones suaves entre pistas, usar overlap de 2-3 segundos con fade-in/fade-out
   - Los archivos de audio se copian a la subcarpeta `audio/` dentro de la demo para usar rutas root-relative (requerido por HyperFrames, no se permiten rutas con `../../../`)

   **Checklist antes de agregar audio:**
   1. Verificar duración real del archivo con `ffprobe -v error -show_entries format=duration -of csv=p=0 <archivo>`
   2. Si duración_archivo < data-duration → agregar `data-loop="true"`
   3. Mover archivos de `assets/sounds/` a `assets/hyperframes/babyhealth-demo-NNN/media/sound/`
   4. Usar rutas relativas desde la raíz del proyecto HyperFrames (e.g. `media/sound/nombre.mp3`)

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

Los archivos de audio **DEBEN** moverse desde `assets/sounds/` hacia la carpeta de media del demo:

```
assets/hyperframes/babyhealth-demo-NNN/media/sound/nombre-archivo.mp3
```

La ruta en el HTML es simplemente:

```
media/sound/nombre-archivo.mp3
```

**Proceso:**
1. El desarrollador deposita los archivos originales en `assets/sounds/`
2. Al generar la demo, **mover** (no copiar) los archivos necesarios a `babyhealth-demo-NNN/media/sound/`
3. Referenciar en la composición con ruta root-relative: `media/sound/nombre.mp3`
4. Si hay clips de video auxiliares, colocarlos en `babyhealth-demo-NNN/media/video/`

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
2. **Ejecutar pruebas funcionales de visibilidad** (ver sección "Pruebas Funcionales" más abajo)
3. Ejecutar `npx hyperframes render . --output <ruta_video> --fps 30 --quality standard`
4. Verificar que el archivo MP4 se generó correctamente
5. Si tiene audio, verificar que la pista se incluyó en el render (el render de HyperFrames mezcla audio automáticamente si los `<audio>` están bien configurados)

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

## Pruebas Funcionales de Visibilidad

Antes de renderizar, **SIEMPRE ejecutar el script de pruebas funcionales** para verificar que el contenido de la página es visible y funcional. Esto previene videos en negro o con escenas vacías.

### Script de pruebas

Ejecutar desde la carpeta de la demo:

```bash
node test-composition.js
```

El script `test-composition.js` debe crearse dentro de cada carpeta de demo con el siguiente contenido y ejecutarse antes del render:

```javascript
/**
 * Pruebas funcionales de visibilidad para composición HyperFrames.
 * Verifica que el index.html muestra contenido visible en cada escena.
 * 
 * Ejecutar: node test-composition.js
 * Requiere: Node.js (no necesita dependencias externas)
 */

const fs = require('fs');
const path = require('path');

const indexPath = path.join(__dirname, 'index.html');
const html = fs.readFileSync(indexPath, 'utf-8');

let errors = 0;
let warnings = 0;
let passed = 0;

function test(name, condition, detail) {
  if (condition) {
    console.log(`  ✅ ${name}`);
    passed++;
  } else {
    console.log(`  ❌ ${name}`);
    if (detail) console.log(`     → ${detail}`);
    errors++;
  }
}

function warn(name, condition, detail) {
  if (condition) {
    console.log(`  ✅ ${name}`);
    passed++;
  } else {
    console.log(`  ⚠️  ${name}`);
    if (detail) console.log(`     → ${detail}`);
    warnings++;
  }
}

console.log('\n🔍 Pruebas Funcionales de Composición HyperFrames\n');
console.log('━'.repeat(60));

// === 1. Estructura básica ===
console.log('\n📄 1. Estructura HTML básica\n');

test('index.html existe', fs.existsSync(indexPath));
test('Contiene <!DOCTYPE html>', html.includes('<!DOCTYPE html>'));
test('Contiene <body>', html.includes('<body>'));
test('Contiene elemento root con data-composition-id',
  /id="root"[^>]*data-composition-id/.test(html) || /data-composition-id[^>]*id="root"/.test(html),
  'El root debe tener id="root" y data-composition-id');
test('Contiene data-duration en el root',
  /data-duration="\d+"/.test(html),
  'data-duration define la duración total de la composición');

// === 2. Escenas ===
console.log('\n🎬 2. Escenas\n');

const sceneMatches = html.match(/class="scene"/g);
const sceneCount = sceneMatches ? sceneMatches.length : 0;
test('Tiene al menos 1 escena', sceneCount > 0, `Encontradas: ${sceneCount}`);
test('Tiene más de 2 escenas para una presentación', sceneCount >= 3,
  `Encontradas: ${sceneCount}. Una presentación debe tener al menos 3 escenas.`);

// Verificar que cada escena tiene data-enter y data-exit
const sceneRegex = /<div[^>]*class="scene"[^>]*>/g;
let sceneEl;
let sceneIndex = 0;
while ((sceneEl = sceneRegex.exec(html)) !== null) {
  sceneIndex++;
  const tag = sceneEl[0];
  test(`Escena ${sceneIndex} tiene data-enter`, /data-enter="\d+"/.test(tag),
    `Escena sin data-enter no se mostrará en el timeline`);
  test(`Escena ${sceneIndex} tiene data-exit`, /data-exit="\d+"/.test(tag),
    `Escena sin data-exit no desaparecerá del timeline`);
}

// Verificar IDs únicos en escenas
const idMatches = html.match(/id="scene-[^"]+"/g) || [];
const uniqueIds = new Set(idMatches);
test('Todas las escenas tienen IDs únicos',
  idMatches.length === uniqueIds.size,
  `${idMatches.length} IDs encontrados, ${uniqueIds.size} únicos`);

// === 3. Contenido visible ===
console.log('\n👁️  3. Contenido visible\n');

// Verificar que hay texto real (no solo tags vacíos)
const textContent = html.replace(/<[^>]+>/g, ' ').replace(/\s+/g, ' ').trim();
const meaningfulText = textContent.replace(/[{}();\s]/g, '');
test('Contiene texto significativo (>100 chars)', meaningfulText.length > 100,
  `Solo ${meaningfulText.length} caracteres de texto encontrados`);

// Verificar headings
const h1Count = (html.match(/<h1[^>]*>/g) || []).length;
const h2Count = (html.match(/<h2[^>]*>/g) || []).length;
const h3Count = (html.match(/<h3[^>]*>/g) || []).length;
test('Contiene headings (h1/h2/h3)', (h1Count + h2Count + h3Count) > 0,
  `h1:${h1Count}, h2:${h2Count}, h3:${h3Count}`);

// Verificar que los headings no están vacíos
const emptyHeadings = html.match(/<h[1-3][^>]*>\s*<\/h[1-3]>/g) || [];
test('No hay headings vacíos', emptyHeadings.length === 0,
  `${emptyHeadings.length} headings vacíos encontrados`);

// === 4. Visibilidad inicial ===
console.log('\n🖥️  4. Visibilidad inicial (scene-1 visible al cargar)\n');

// La primera escena DEBE ser visible al cargar (opacity > 0 o sin display:none)
test('CSS inicial: escenas comienzan con opacity:0',
  /\.scene[^{]*\{[^}]*opacity:\s*0/s.test(html),
  'Las escenas deben iniciar ocultas para que el timeline las controle');

// Verificar que el script de timeline existe y hace seek(0)
test('Script de timeline existe',
  /window\.__timelines/.test(html),
  'Debe registrar timeline en window.__timelines');
test('Timeline hace seek(0) al inicializar',
  /timeline\.seek\(0\)/.test(html) || /seek\(0\)/.test(html),
  'seek(0) muestra la primera escena al cargar');

// Verificar que la primera escena tiene data-enter="0"
test('Primera escena tiene data-enter="0"',
  /data-enter="0"/.test(html),
  'Sin data-enter="0" la primera escena no será visible al cargar');

// === 5. Timeline consistencia ===
console.log('\n⏱️  5. Timeline consistencia\n');

const enterExitRegex = /data-enter="(\d+)"[^>]*data-exit="(\d+)"/g;
let match;
let lastExit = 0;
let timelineGaps = [];
let overlaps = [];
let sceneIdx = 0;

while ((match = enterExitRegex.exec(html)) !== null) {
  sceneIdx++;
  const enter = parseInt(match[1]);
  const exit = parseInt(match[2]);
  
  test(`Escena ${sceneIdx}: enter(${enter}) < exit(${exit})`, enter < exit,
    'Una escena con enter >= exit nunca será visible');
  
  if (sceneIdx > 1 && enter > lastExit) {
    timelineGaps.push({ after: sceneIdx - 1, gap: enter - lastExit });
  }
  if (sceneIdx > 1 && enter < lastExit) {
    overlaps.push({ scenes: `${sceneIdx-1}-${sceneIdx}`, overlap: lastExit - enter });
  }
  lastExit = exit;
}

warn('Sin gaps mayores a 1s en el timeline',
  timelineGaps.filter(g => g.gap > 1).length === 0,
  timelineGaps.length > 0 ? `Gaps: ${JSON.stringify(timelineGaps)}` : 'OK');

// Verificar duración total vs última escena
const durationMatch = html.match(/data-duration="(\d+)"/);
if (durationMatch && lastExit > 0) {
  const totalDuration = parseInt(durationMatch[1]);
  warn('Última escena termina cerca de la duración total',
    Math.abs(totalDuration - lastExit) <= 5,
    `Duración: ${totalDuration}s, última escena termina: ${lastExit}s`);
}

// === 6. Estilos críticos ===
console.log('\n🎨 6. Estilos críticos\n');

test('Define color de texto (color o --text)',
  /color:\s*#|color:\s*var\(--text\)|color:\s*rgb/.test(html),
  'Sin color definido, el texto podría ser invisible sobre fondo oscuro');
test('Define fondo (background)',
  /background/.test(html),
  'Sin background definido la composición puede ser transparente');
test('Usa id="root" (no class="composition")',
  /id="root"/.test(html) && !/class="composition"/.test(html),
  'class="composition" rompe el scoping del runtime de HyperFrames');
test('Font-face declarado (no @import de Google Fonts)',
  /@font-face/.test(html),
  'Las fuentes deben declararse con @font-face, no @import');
warn('No usa @import url(fonts.googleapis.com)',
  !/@import\s+url\([^)]*fonts\.googleapis/.test(html),
  '@import de Google Fonts agrega latencia y puede fallar en render');

// === Resumen ===
console.log('\n' + '━'.repeat(60));
console.log(`\n📊 Resultados: ${passed} pasaron, ${errors} errores, ${warnings} advertencias\n`);

if (errors > 0) {
  console.log('❌ HAY ERRORES — La composición puede NO mostrar contenido correctamente.');
  console.log('   Corrige los errores antes de renderizar.\n');
  process.exit(1);
} else if (warnings > 0) {
  console.log('⚠️  Pasó con advertencias — Revisa los warnings antes de renderizar.\n');
  process.exit(0);
} else {
  console.log('✅ Todas las pruebas pasaron — La composición es funcional.\n');
  process.exit(0);
}
```

### Qué validan las pruebas

| Categoría | Validación |
|-----------|-----------|
| **Estructura HTML** | DOCTYPE, body, root con data-composition-id y data-duration |
| **Escenas** | Al menos 3 escenas, cada una con data-enter/data-exit, IDs únicos |
| **Contenido visible** | Texto significativo (>100 chars), headings no vacíos |
| **Visibilidad inicial** | scene-1 visible al cargar via seek(0), primera escena con data-enter="0" |
| **Timeline** | enter < exit en cada escena, sin gaps >1s, cobertura total de duración |
| **Estilos** | Color de texto definido, background presente, id="root", @font-face |

### Cuándo ejecutar

- **ANTES** de `npx hyperframes render` — si las pruebas fallan, NO renderizar
- **DESPUÉS** de crear/modificar `index.html` — para validación rápida
- Resultado `exit 1` = errores bloqueantes, `exit 0` = puede renderizar

### Integración en el flujo

El Paso 5 actualizado queda:

```
5. Renderizar video:
   a. npx hyperframes check → validar lint/runtime
   b. node test-composition.js → validar visibilidad y contenido
   c. npx hyperframes render . --output <ruta> --fps 30 --quality standard
   d. Verificar MP4 generado
```

---

## Información del Proyecto (referencia rápida)

- **App:** BabyHealth — orientación de salud infantil con IA multimodal
- **Stack:** Flutter Web + FastAPI + AWS (Lambda, Bedrock, Cognito, S3, DynamoDB)
- **IA:** AWS Bedrock (Claude Sonnet) y Google Gemini
- **Equipo:** Hector (Coordinador+Backend), Alvaro (Diseño+Frontend), William (Fullstack), Francisco (Frontend)
- **URL:** https://babyhealth.hmartinez.info
- **Repo:** https://github.com/hdmartinezm/hackathon-kiro
