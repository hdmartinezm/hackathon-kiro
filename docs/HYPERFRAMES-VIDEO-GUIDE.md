# Guía: Generar Video Demos con HyperFrames para BabyHealth

## Descripción General

Este proyecto usa [HyperFrames](https://hyperframes.heygen.com/) de HeyGen para crear videos demo animados de la aplicación BabyHealth directamente desde HTML, CSS y JavaScript. Los videos se generan frame-by-frame usando GSAP para animaciones y se renderizan a MP4/WebM con FFmpeg.

## Estructura del Proyecto

```
assets/video/
├── videoworkshop/           ← Proyecto HyperFrames (aquí se edita)
│   ├── hyperframes.json     ← Configuración del proyecto
│   ├── index.html           ← Composición raíz (entry point del video)
│   ├── meta.json            ← Metadata del proyecto
│   ├── package.json         ← Dependencias
│   ├── compositions/        ← Escenas individuales del video
│   │   ├── title.html
│   │   ├── problem.html
│   │   ├── overview.html
│   │   ├── growth.html
│   │   ├── milestones.html
│   │   ├── doctor.html
│   │   ├── alerts.html
│   │   ├── social.html
│   │   └── outro.html
│   ├── agent/skills/        ← Skills de AI para workflows
│   └── .agents/skills/      ← Skills adicionales (symlinked)
└── *.mp4 / *.mov            ← Videos renderizados (output)
```

## Requisitos

- **Node.js 22+**
- **FFmpeg** (para encoding de video local)
- **Docker** (opcional, para renders determinísticos)

Verificar instalación:
```bash
node --version    # v22+
ffmpeg -version   # cualquier versión reciente
```

## Comandos Principales

Todos los comandos se ejecutan desde `assets/video/videoworkshop/`:

```bash
cd assets/video/videoworkshop
```

### Vista previa en navegador (hot reload)

```bash
npx hyperframes preview
```

Abre el Hyperframes Studio en el navegador. Los cambios en los archivos HTML se reflejan al instante.

### Validar composiciones

```bash
npx hyperframes lint
```

Verifica que la estructura HTML cumple con el contrato de HyperFrames (data attributes, timelines, etc.). Debe dar 0 errores antes de renderizar.

### Renderizar a MP4

```bash
# Render básico (30fps, calidad estándar)
npx hyperframes render --output ../babyhealth-demo.mp4

# Render de alta calidad
npx hyperframes render --output ../babyhealth-demo.mp4 --quality high --fps 60

# Render determinístico (con Docker)
npx hyperframes render --docker --output ../babyhealth-demo.mp4
```

El video se genera en `assets/video/babyhealth-demo.mp4`.

### Listar composiciones

```bash
npx hyperframes compositions
```

Muestra todas las escenas con su duración, resolución y número de elementos.

### Diagnóstico del entorno

```bash
npx hyperframes doctor
```

Verifica que Chrome, FFmpeg y las dependencias están correctamente instaladas.

## Estructura de una Composición

Cada escena es un archivo HTML con esta estructura:

```html
<template>
  <div data-composition-id="mi-escena"
       data-width="1920" data-height="1080"
       data-duration="15"
       style="position: absolute; inset: 0;">

    <style>
      /* Estilos scoped a esta composición */
    </style>

    <!-- Contenido visual -->
    <div id="titulo" class="clip" data-start="0" data-duration="10">
      Texto animado
    </div>

    <script>
      // Timeline GSAP (siempre paused)
      window.__timelines = window.__timelines || {};
      const tl = gsap.timeline({ paused: true });
      tl.fromTo("#titulo", { opacity: 0, y: 50 }, { opacity: 1, y: 0, duration: 1 }, 0);
      window.__timelines["mi-escena"] = tl;
    </script>
  </div>
</template>
```

### Reglas clave:

1. **Root element** debe tener `data-composition-id`, `data-width`, `data-height`, `data-duration`
2. **Timeline GSAP** debe crearse con `{ paused: true }` y registrarse en `window.__timelines`
3. **Elementos animados** usan `id` para targeting con GSAP
4. Las duraciones están en **segundos**

## Composición Raíz (index.html)

El `index.html` orquesta las sub-composiciones con tiempos de entrada:

```html
<div data-composition-id="root" data-start="0" data-width="1920" data-height="1080" data-duration="90">
  <div data-composition-src="compositions/title.html" data-start="0" data-duration="8"></div>
  <div data-composition-src="compositions/problem.html" data-start="8" data-duration="12"></div>
  <!-- ... más escenas ... -->
</div>
```

- `data-start`: segundo en que aparece la escena dentro del video total
- `data-duration`: cuánto dura la escena
- `data-composition-src`: archivo HTML de la escena

## Video Demo Actual de BabyHealth

El video actual dura **90 segundos** (1920×1080) con 9 escenas:

| # | Escena | Inicio | Duración | Contenido |
|---|--------|--------|----------|-----------|
| 1 | Title | 0s | 8s | Logo ♡ + "BabyHealth" + tagline |
| 2 | Problem | 8s | 12s | Estadísticas del problema (87% ansiedad, 5+ apps) |
| 3 | Overview | 20s | 15s | Mockup del teléfono con dashboard de "Emma" |
| 4 | Growth | 35s | 15s | Gráfica de crecimiento WHO con percentiles |
| 5 | Milestones | 50s | 12s | Timeline de hitos del desarrollo (0-12 meses) |
| 6 | Doctor | 62s | 10s | Chat con pediatra (Dr. Sarah Chen) |
| 7 | Alerts | 72s | 8s | Alertas inteligentes (vacunas, feeding, checkups) |
| 8 | Social | 80s | 7s | Prueba social (4.9★, 500K+ familias, reviews) |
| 9 | Outro | 87s | 3s | CTA "Download Now" |

## Paleta de Colores

| Color | Hex | Uso |
|-------|-----|-----|
| Fondo principal | `#0a0a1a` | Background oscuro |
| Púrpura primario | `#6C63FF` | Acentos, gradientes, logo |
| Teal/Mint | `#4ECDC4` | Acentos secundarios, milestones |
| Rosa | `#FF6B9D` | Problemas, doctor feature |
| Dorado | `#FFC107` | Alertas, estrellas |
| Texto principal | `#FFFFFF` | Títulos |
| Texto secundario | `rgba(255,255,255,0.6-0.85)` | Descripciones |

## Cómo Crear una Nueva Escena

1. Crear archivo en `compositions/mi-escena.html`
2. Seguir la estructura de template (ver arriba)
3. Agregar referencia en `index.html`:
   ```html
   <div data-composition-src="compositions/mi-escena.html"
        data-start="X" data-duration="Y" data-track-index="1"></div>
   ```
4. Ajustar `data-duration` del root en `index.html` si la duración total cambia
5. Ejecutar `npx hyperframes lint` para validar
6. Previsualizar con `npx hyperframes preview`

## Cómo Modificar Tiempos

Para hacer el video más corto o largo:

1. Ajustar `data-duration` en cada composición (`.html` individual)
2. Ajustar `data-start` y `data-duration` de cada referencia en `index.html`
3. Ajustar `data-duration` del root element en `index.html` (duración total)
4. Las animaciones GSAP que excedan la duración simplemente se cortan

## Tips para Animaciones GSAP

```javascript
// Fade in desde abajo
tl.fromTo("#elem", { y: 40, opacity: 0 }, { y: 0, opacity: 1, duration: 0.8, ease: "power3.out" }, 0.5);

// Scale con bounce
tl.fromTo("#logo", { scale: 0 }, { scale: 1, duration: 0.8, ease: "back.out(1.7)" }, 0);

// Stagger (elementos en secuencia)
tl.fromTo(".card", { y: 30, opacity: 0 }, { y: 0, opacity: 1, duration: 0.6, stagger: 0.2 }, 1);

// Fade out al final
tl.to("#elem", { opacity: 0, duration: 0.5, ease: "power2.in" }, 10);
```

## Render en la Nube (opcional)

Si no quieres renderizar localmente:

```bash
# Autenticarse con HeyGen
npx hyperframes auth login --api-key

# Render en la nube de HeyGen
npx hyperframes cloud render --output ../babyhealth-demo.mp4
```

## Troubleshooting

| Problema | Solución |
|----------|----------|
| `npx hyperframes` no encontrado | Ejecutar desde `assets/video/videoworkshop/` |
| Chrome no detectado | `npx hyperframes doctor` y seguir instrucciones |
| Video negro | Verificar que las timelines están registradas en `window.__timelines` |
| Animaciones no se ven | Confirmar que el timeline es `{ paused: true }` |
| Lint falla con errores | Revisar `data-composition-id` y `data-duration` en cada archivo |
