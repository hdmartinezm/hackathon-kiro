# Guion de Presentación — BabyHealth Demo para Jurado Hackathon

**Duración total:** 3 minutos 50 segundos (230s)
**Tipo:** Demo técnica para jurado de hackathon
**Tono:** Directo, técnico pero accesible, orientado a demostrar funcionalidad real
**Audio:** Música de fondo con 2 pistas

---

## Pistas de Audio

| Pista | Archivo | Entrada | Salida | Volumen | Fade In | Fade Out | Propósito |
|-------|---------|---------|--------|---------|---------|----------|-----------|
| Track 1 | `Small_Steps_Forward.mp3` | 0:00 | 2:00 | 25% | 2s | 3s | Fondo emocional (problema + solución) |
| Track 2 | `Steady_Hands.mp3` | 1:58 | 3:50 | 25% | 2s | 4s | Fondo técnico (arquitectura + cierre) |

Las pistas hacen crossfade en el segundo 118-120 para transición suave.

---

## Escena 1: Título (0:00 – 0:15)

**Narración:**
"BabyHealth — Orientación de salud infantil con inteligencia artificial multimodal. Construido durante el Hackathon Kiro 2026."

**Visuales:**
- Logo "BabyHealth" en verde accent grande
- Subtítulo descriptivo
- Badge "Hackathon Kiro 2026 — Construido con Kiro IDE"

**Audio:** Track 1 inicia con fade in de 2 segundos

---

## Escena 2: El Problema (0:15 – 0:45)

**Narración:**
"El 70% de las consultas pediátricas de urgencia son por síntomas que no requieren atención inmediata. Los padres primerizos no tienen herramientas para distinguir lo normal de lo urgente. Esto genera ansiedad constante, urgencias saturadas, y señales reales que pasan desapercibidas."

**Visuales:**
- Estadística "70%" animada en rojo
- Tres tarjetas de problema con íconos:
  - Ansiedad 24/7
  - Urgencias saturadas
  - Señales perdidas

---

## Escena 3: La Solución (0:45 – 1:20)

**Narración:**
"BabyHealth resuelve esto con un flujo de 4 pasos: el padre graba 15 segundos de video, nuestra IA analiza señales visuales y auditivas, entrega un resultado tipo semáforo en segundos, y genera un reporte PDF para compartir con el pediatra. Verde: todo normal. Amarillo: observar. Rojo: consultar pediatra."

**Visuales:**
- Flujo de 4 pasos: Grabar → IA analiza → Resultado → Comparte
- Semáforo con 3 luces (verde/amarillo/rojo) con etiquetas

---

## Escena 4: Arquitectura Técnica (1:20 – 2:00)

**Narración:**
"La arquitectura es 100% serverless en AWS. Frontend en Flutter Web desplegado en CloudFront. Backend en Python con FastAPI corriendo en Lambda vía Mangum. Doble motor de IA: AWS Bedrock con Claude Sonnet como primario, Google Gemini como respaldo. Almacenamiento en S3 con TTL de 24 horas. Autenticación social via Cognito."

**Visuales:**
- Diagrama de arquitectura construido progresivamente
- Cajas conectadas: Flutter → CloudFront/API Gateway → Lambda → Bedrock/Gemini/S3/Cognito
- Cajas de IA destacadas en purple

**Audio:** Crossfade Track 1 → Track 2 en segundo 118

---

## Escena 5: Demo en Vivo (2:00 – 2:40)

**Narración:**
"Veamos la app en acción. El usuario entra, configura el perfil de su bebé, graba un video de 15 segundos, selecciona el modelo de IA — puede elegir entre Bedrock o Gemini — y en menos de 30 segundos recibe el resultado. En este caso: semáforo verde, llanto por hambre. El padre genera un PDF y lo comparte directamente con su pediatra por WhatsApp."

**Visuales:**
- 5 mockups de pantalla tipo phone frames: Landing → Perfil → Captura → Selector IA → Resultado
- Frame activo (resultado) con borde verde
- Card de resultado: "Normal — Llanto por hambre"
- Mención de PDF + WhatsApp

---

## Escena 6: Funcionalidades (2:40 – 3:10)

**Narración:**
"Funcionalidades implementadas: doble motor de IA con retry automático, sistema de semáforo con recomendaciones, generación de reportes PDF compartibles, soporte bilingüe completo español-inglés, modo oscuro y claro, y autenticación social con Google y Facebook."

**Visuales:**
- Grid 3x2 de feature cards con íconos:
  - Doble Motor IA
  - Sistema Semáforo
  - Reportes PDF
  - Bilingüe
  - Dark/Light Mode
  - Auth Social

---

## Escena 7: Construido con Kiro (3:10 – 3:30)

**Narración:**
"Todo construido en 48 horas por un equipo de 4 personas usando Kiro como IDE con IA de copiloto. Specs, tasks, steering files y HyperFrames para esta misma presentación. Tres capas completas: frontend, backend e infraestructura."

**Visuales:**
- Tres estadísticas: 48h, 4 personas, 3 capas
- Fila de badges de herramientas: Kiro IDE, Specs & Tasks, Steering, HyperFrames, AWS CDK

---

## Escena 8: Equipo + Cierre (3:30 – 3:50)

**Narración:**
"Equipo BabyHealth: Hector en backend y AWS, Alvaro en diseño y frontend, William fullstack, Francisco en frontend lead. Pruébala en vivo: babyhealth.hmartinez.info. Gracias jurado."

**Visuales:**
- Logo BabyHealth
- Grid 4 miembros con avatar, nombre y rol
- URL del proyecto
- Badge "Hackathon Kiro 2026"

**Audio:** Track 2 fade out en los últimos 4 segundos

---

## Especificaciones Técnicas

- **Resolución:** 1920x1080 (Full HD)
- **FPS:** 30
- **Duración:** 230 segundos (3:50)
- **Paleta de colores:**
  - Accent: #00E676 (verde neón)
  - Primary: #4CAF50 (verde)
  - Secondary: #FF9800 (naranja)
  - Alert: #F44336 (rojo)
  - Kiro Purple: #7C4DFF
  - Background: #0F1923 (azul oscuro)
  - Cards: #1A2736
- **Tipografía:**
  - Títulos: Space Grotesk Bold
  - Body: Inter Regular
  - Datos/Code: DM Mono
- **Transiciones:** Fade 0.8s entre escenas
- **Audio:** 2 pistas MP3 con crossfade, volumen 25%
