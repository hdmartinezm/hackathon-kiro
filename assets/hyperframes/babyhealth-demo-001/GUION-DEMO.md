# Guion de Presentación — BabyHealth Demo 001

**Tipo:** Pitch técnico  
**Audiencia:** Jueces de hackathon (perfil técnico)  
**Duración:** 90 segundos  
**Resolución:** 1920×1080 @ 30 FPS  
**Paleta:** Teal (#4B9B9B), Coral (#DF7B5E), Dark (#1A1A2E), White (#FFFFFF)  
**Tipografía:** Inter (sans), Playfair Display (serif para títulos)

---

## Timeline de Escenas

### Escena 1 — Hook / Problema (0s – 15s)

**Visual:**
- Fondo oscuro (#1A1A2E) con gradiente sutil
- Texto grande: "Son las 3 AM. Tu bebé llora."
- Fade in de subtítulo: "¿Urgencia... o solo hambre?"
- Estadística animada: "60% de visitas a urgencias pediátricas son innecesarias"
- Logo BabyHealth aparece discreto

**Narración (texto):**
> Cada noche, miles de padres enfrentan la misma pregunta. Sin herramientas, la ansiedad gana.

**Transición:** Fade a blanco → escena 2

---

### Escena 2 — Solución (15s – 30s)

**Visual:**
- Fondo limpio con gradiente teal suave
- Título: "BabyHealth: IA Multimodal para Padres"
- Tres íconos aparecen secuencialmente:
  1. 📹 "Graba 10 segundos de video"
  2. 🧠 "IA analiza imagen + audio"
  3. 🚦 "Semáforo: Verde | Amarillo | Rojo"
- Badge: "Respuesta en < 15 segundos"

**Narración (texto):**
> Un video de 10 segundos. Análisis visual del bebé + clasificación del llanto. Resultado inmediato.

**Transición:** Slide left → escena 3

---

### Escena 3 — Arquitectura Técnica (30s – 55s)

**Visual:**
- Diagrama de flujo animado (aparecen bloques progresivamente):
  - Flutter Web → CloudFront → API Gateway → Lambda (FastAPI)
  - Lambda → S3 (video) → FFmpeg (frame + spectrogram)
  - Frame → Bedrock Claude Sonnet (análisis visual)
  - Spectrogram → Bedrock Claude Sonnet (clasificación llanto)
  - Resultado → DynamoDB + Response
- Badges laterales: "Claude Sonnet", "Gemini fallback", "Cognito OAuth"

**Narración (texto):**
> Pipeline serverless. Video sube a S3, Lambda extrae frame + espectrograma con FFmpeg, Claude analiza ambos en paralelo. DynamoDB persiste el historial. Gemini como fallback. Todo en CDK.

**Transición:** Scale down → escena 4

---

### Escena 4 — Diferenciadores (55s – 75s)

**Visual:**
- Grid 2×2 de cards con íconos:
  - 🔊 "Análisis de Llanto" — Clasifica: hambre, dolor, sueño, cólico
  - 📄 "Reporte PDF + WhatsApp" — Contacto directo con pediatra
  - 🌐 "Bilingüe ES/EN" — Detección automática de idioma
  - 🛡️ "Multi-modelo" — Bedrock + Gemini, degradación graceful
- Cada card hace fade-in con delay escalonado

**Narración (texto):**
> No solo visual: analiza el llanto. Genera reportes PDF que envía al pediatra por WhatsApp. Bilingüe. Multi-modelo con fallback automático.

**Transición:** Fade → escena 5

---

### Escena 5 — Cierre + CTA (75s – 90s)

**Visual:**
- Fondo oscuro elegante
- Logo BabyHealth grande centrado
- URL: babyhealth.hmartinez.info
- Equipo: Hector · Álvaro · William · Francisco
- Tagline: "Orientación inteligente. Tranquilidad instantánea."
- Badge: "Hackathon Kiro 2026"

**Narración (texto):**
> BabyHealth. Porque la tranquilidad de un padre no debería depender de Google a las 3 AM.

---

## Especificaciones de Audio

| Pista | Archivo | Entrada | Salida | Volumen | Fade In | Fade Out | Loop |
|-------|---------|---------|--------|---------|---------|----------|------|
| Música de fondo | `media/sound/surfacing-shane-mckenna.mp3` | 0s | 90s | 0.20 | 3s | 4s | No (272s > 90s) |

---

## Notas de Producción

- La música (272s) es más larga que el video (90s), no requiere loop
- Fade-in de 3s para entrada suave, fade-out de 4s para cierre elegante
- Volumen bajo (0.20) para no competir con texto visual
- El tono de la presentación es profesional pero accesible — mostrar dominio técnico sin ser denso
- Los diagramas de arquitectura deben ser legibles a 1080p
- Las transiciones entre escenas son suaves (1-2s de overlap)
