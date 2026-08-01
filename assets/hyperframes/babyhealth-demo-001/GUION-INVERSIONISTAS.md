# Guion de Presentación — BabyHealth Pitch Inversionistas

**Tipo:** Pitch para inversionistas  
**Audiencia:** No técnica — enfoque en caso de negocio  
**Duración:** 90 segundos  
**Resolución:** 1920×1080 @ 30 FPS  
**Paleta:** Teal (#4B9B9B), Coral (#DF7B5E), Gold (#F5A623), Dark (#1A1A2E), White (#FFFFFF)  
**Tipografía:** Inter (sans), Playfair Display (serif para títulos)  
**Composición:** `compositions/pitch-inversionistas.html`

---

## Timeline de Escenas

### Escena 1 — Hook Emocional (0s – 18s)

**Visual:**
- Fondo oscuro con gradiente sutil
- Título emocional grande: "Cada noche, millones de padres no saben si correr a urgencias."
- Subtítulo en coral: "La ansiedad de un padre primerizo no tiene horario."
- Fila de 3 estadísticas impactantes:
  - 60% — Visitas a urgencias pediátricas innecesarias
  - $1,500 — Costo promedio por visita de emergencia
  - 3 AM — Hora pico de ansiedad de padres

**Narración (texto):**
> El dolor es real. El costo es masivo. Y la solución no existe... hasta ahora.

---

### Escena 2 — Problema de Mercado (18s – 36s)

**Visual:**
- Título: "Un mercado enorme, desatendido"
- 3 métricas grandes con cards:
  - 140M — Bebés nacen cada año en el mundo
  - $48B — Mercado global de salud digital pediátrica
  - 76% — Padres buscan en Google antes de llamar al doctor
- Insight: "No existe una herramienta confiable que combine IA visual + análisis de audio para dar orientación inmediata."

**Narración (texto):**
> 140 millones de nacimientos al año. Un mercado de $48B sin una solución inteligente que reduzca la ansiedad en el momento crítico.

---

### Escena 3 — La Solución (36s – 54s)

**Visual:**
- Título: "BabyHealth: Orientación Instantánea"
- 3 pasos numerados simples:
  1. Graba 10 segundos de video del bebé
  2. Nuestra IA analiza imagen y llanto
  3. Resultado inmediato: 🟢 Normal · 🟡 Atención · 🔴 Urgente
- Badges: "⚡ 15 segundos", "🌐 Bilingüe", "📄 Reporte al pediatra"

**Narración (texto):**
> Simple como grabar un video. En 15 segundos, nuestra IA te dice si es urgente o puedes esperar. Sin jerga médica. Sin ansiedad.

---

### Escena 4 — Modelo de Negocio + Métricas (54s – 74s)

**Visual:**
- Título: "Modelo de Negocio"
- Grid 2×2:
  - 💰 Freemium + Suscripción — 3 gratis/mes, Premium $9.99/mes
  - 🏥 B2B: Aseguradoras & Clínicas — White-label
  - 📈 Unit Economics — Costo/análisis: $0.03, Margen: 92%
  - 🎯 Tracción — MVP en producción, <15s latencia, usuarios reales
- Barra TAM/SAM/SOM:
  - TAM: $48B
  - SAM: $8.2B
  - SOM: $420M (LATAM + US Hispanic, Año 3)

**Narración (texto):**
> Freemium para adquisición, premium para retención. B2B con aseguradoras que ahorran miles por cada visita evitada. Costo por análisis: 3 centavos. Margen de 92%.

---

### Escena 5 — Cierre + CTA (74s – 90s)

**Visual:**
- Logo BabyHealth grande
- Tagline: "Orientación inteligente. Tranquilidad instantánea."
- CTA destacado: "Buscamos $500K — Ronda Pre-Seed"
- URL: babyhealth.hmartinez.info
- Equipo completo
- Badge: "Hackathon Kiro 2026 · MVP en Producción"

**Narración (texto):**
> BabyHealth. La tranquilidad de un padre no debería costar una visita a urgencias. Estamos buscando $500K para escalar a toda LATAM.

---

## Especificaciones de Audio

| Pista | Archivo | Entrada | Salida | Volumen | Fade In | Fade Out | Loop |
|-------|---------|---------|--------|---------|---------|----------|------|
| Música de fondo | `../../../sounds/drifting-home-dan-phillipson.mp3` | 0s | 90s | 0.18 | 3s | 5s | No |

---

## Notas de Producción

- **Tono:** Emocional al inicio, datos contundentes en el centro, cierre con confianza y call-to-action claro
- **Sin jerga técnica:** No mencionar stack, APIs, ni frameworks — solo resultados
- **Métricas de negocio:** TAM/SAM/SOM, unit economics, pricing, margen
- **Música:** "Drifting Home" — tono cálido, inspirador, no intrusivo
- **Diferencia vs pitch técnico:** Este pitch vende el negocio, no la arquitectura
- **Paleta extendida:** Se añade Gold (#F5A623) para métricas financieras y de negocio

## Comando de Render

```bash
npx hyperframes render . --composition babyhealth-pitch-investors --output ../../video/BabyHealth-pitch-inversionistas.mp4 --fps 30 --quality standard
```
