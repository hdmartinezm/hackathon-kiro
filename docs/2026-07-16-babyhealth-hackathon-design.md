# BabyHealth - Diseño de Hackathon AWS

> Asistente de cuidado neonatal con LLM multimodal

**Fecha:** 16 julio 2026
**Hackathon:** AWS (20-27 julio 2026)
**Equipo:** 4 personas
**Criterio principal:** Innovación / originalidad

---

## Resumen Ejecutivo

BabyHealth es una app móvil que permite a padres primerizos obtener orientación sobre el estado de salud de su bebé mediante análisis no-invasivo de imagen y audio, utilizando Claude Vision en Amazon Bedrock.

**Diferenciador clave:** Análisis multimodal (visual + auditivo) usando IA generativa para detectar señales tempranas que requieran atención médica.

**Disclaimer obligatorio:** La app es un asistente informativo, no reemplaza consulta médica profesional.

---

## Problema

- Padres primerizos frecuentemente tienen dudas sobre el estado de salud de su bebé
- Acceso limitado a orientación médica fuera de horarios de consulta
- Señales tempranas de condiciones (ictericia, malestar) pueden pasar desapercibidas

## Solución

App móvil que:
1. Captura imagen y audio del bebé (3 segundos)
2. Analiza visualmente (coloración de piel, expresión facial)
3. Analiza audio (patrones de llanto)
4. Proporciona orientación y recomendaciones

---

## Stack Técnico (Optimizado)

### Decisiones clave

| Decisión | Original | Optimizado | Razón |
|----------|----------|------------|-------|
| Compute | ECS Fargate | **Lambda + API Gateway** | Setup en horas, no días |
| Audio | Obligatorio MVP | **Degradable** | Imagen primero, audio si hay tiempo |
| IaC | CDK completo | **CDK mínimo** | Solo lo necesario para funcionar |

### Backend
- **Python + FastAPI** con mangum (adapter para Lambda)
- **Lambda** para ejecución serverless
- **API Gateway** para endpoint HTTPS

### Frontend
- **Flutter (Dart)** — app nativa iOS/Android
- Plugins: `camera`, `record`, `google_mlkit_face_detection`
- Estado con Provider o Riverpod

### AWS Services
| Servicio | Uso |
|----------|-----|
| **Bedrock** | Claude 3.5 Sonnet Vision — análisis multimodal |
| **Lambda** | Ejecución del backend FastAPI |
| **API Gateway** | Endpoint HTTPS público |
| **S3** | Almacenamiento de fotos/audios (pre-signed URLs) |
| **DynamoDB** | Sesiones y resultados |
| **CloudWatch** | Logs y monitoreo |

### Servicios omitidos en MVP
- Cognito (auth) — se protege con API Key + rate limiting
- ECS/EKS — reemplazado por Lambda
- ALB — reemplazado por API Gateway

---

## Arquitectura

```
┌─────────────────┐
│   Flutter App   │
│  (iOS/Android)  │
└────────┬────────┘
         │ 1. Captura imagen + audio
         │ 2. Upload a S3 (pre-signed URL)
         │ 3. POST /analyze
         ▼
┌─────────────────┐
│  API Gateway    │
│   (HTTPS)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│     Lambda      │
│ (FastAPI+mangum)│
└────────┬────────┘
         │
    ┌────┴────┐
    ▼         ▼
┌───────┐ ┌───────┐
│  S3   │ │Bedrock│
│(media)│ │(Vision)│
└───────┘ └───────┘
         │
         ▼
┌─────────────────┐
│   DynamoDB      │
│  (resultados)   │
└─────────────────┘
```

---

## Pipeline de Análisis

### Flujo principal

1. **Flutter:** Detecta rostro con ML Kit (on-device) → graba 3s video+audio
2. **Upload:** Sube imagen y audio a S3 via pre-signed URL
3. **Request:** POST `/analyze` con referencias a S3
4. **Lambda:**
   - Lee imagen de S3
   - (Si hay tiempo) Convierte audio → espectrograma con librosa
   - Llama a Bedrock Vision con imagen (+ espectrograma)
5. **Respuesta:** Guarda en DynamoDB → responde JSON a la app

### Prompt para Bedrock Vision

```
Eres un asistente de orientación para padres. Analiza esta imagen de un bebé.

Evalúa:
- Coloración de piel (busca tonos amarillentos que podrían indicar ictericia)
- Expresión facial (signos de malestar o tranquilidad)
- Estado general visible

Responde en JSON:
{
  "estado_general": "normal|requiere_atencion|urgente",
  "observaciones": ["..."],
  "recomendaciones": ["..."],
  "disclaimer": "Esta información es orientativa. Consulte a su pediatra."
}
```

---

## Estrategia de Demo

### Estructura del Pitch (4 minutos)

| Tiempo | Sección | Contenido |
|--------|---------|-----------|
| 0:00-0:30 | **Hook** | Problema real de padres primerizos |
| 0:30-1:15 | **Demo en vivo** | Flujo completo: app → escanear → resultado |
| 1:15-2:15 | **Arquitectura** | Diagrama con iconos AWS |
| 2:15-3:00 | **Innovación** | Por qué multimodal, por qué Bedrock |
| 3:00-3:30 | **Impacto** | Escalabilidad, mercado potencial |
| 3:30-4:00 | **Cierre** | Futuro, disclaimer elegante |

### Plan de contingencia

```
Demo en vivo funciona     → Plan A (ideal)
         ↓ falla
Video pregrabado          → Plan B (grabar día 5)
         ↓ falla
Slides con screenshots    → Plan C (siempre listo)
```

### Tips técnicos para demo

- **Precalentar Lambda** 5 min antes (evitar cold start)
- **Hotspot móvil** como backup de internet
- **Video de prueba** de ~3s listo (stock o simulado)
- **CloudWatch** abierto para mostrar logs en tiempo real

### Wow moments para jueces AWS

- Diagrama con iconos oficiales de AWS
- Mencionar decisiones de arquitectura serverless
- Mostrar métricas de CloudWatch en vivo
- "Lambda escala a cero = costo mínimo"

---

## Cronograma (20-27 julio)

| Día | Foco | Entregable |
|-----|------|------------|
| **D1** | Setup + Infra | CDK desplegado, Lambda funcionando, **Bedrock model access solicitado** |
| **D2** | Pipeline imagen | Upload S3 + llamada Bedrock funcionando |
| **D3** | Flutter básico | App captura imagen y llama al endpoint |
| **D4** | Integración | Flujo completo imagen end-to-end |
| **D5** | Polish + Audio* | UI pulida, grabar video backup, (audio si hay tiempo) |
| **D6** | Buffer | Bugs, edge cases, práctica de pitch |
| **D7** | Preparación | Ensayo final, checklist, entrega |

*Audio es stretch goal, no bloquea el MVP.

---

## Puntos Críticos

### Día 1 - Obligatorio

- [ ] Solicitar Bedrock model access (Claude 3.5 Sonnet) — puede demorar aprobación
- [ ] Verificar región (us-east-1 recomendado para todo)
- [ ] Crear bucket S3 y tabla DynamoDB

### IAM Mínimo

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::babyhealth-media/sessions/*"
    },
    {
      "Effect": "Allow",
      "Action": ["dynamodb:PutItem", "dynamodb:GetItem"],
      "Resource": "arn:aws:dynamodb:*:*:table/babyhealth-sessions"
    },
    {
      "Effect": "Allow",
      "Action": ["bedrock:InvokeModel"],
      "Resource": "*"
    }
  ]
}
```

### Limitaciones conocidas

| Limitación | Mitigación |
|------------|------------|
| Temperatura no medible con cámara | No incluir en análisis, ser transparente |
| Ictericia por cámara es aproximación | Disclaimer claro, recomendar consulta |
| Cold start Lambda (~3-5s) | Precalentar antes de demo |
| Bedrock model access demora | Solicitar día 1, tener plan B con mock |

---

## Checklist Día de Presentación

### 30 minutos antes
- [ ] Hacer request de prueba para calentar Lambda
- [ ] Verificar video de respaldo cargado y funcionando
- [ ] Activar hotspot móvil como backup
- [ ] Tener diagrama de arquitectura listo

### Durante la presentación
- [ ] Comenzar con historia/problema, no con tecnología
- [ ] Mostrar demo antes de explicar arquitectura
- [ ] Mencionar servicios AWS usados naturalmente
- [ ] Incluir disclaimer médico de forma elegante
- [ ] Cerrar con visión de impacto

---

## Distribución de Trabajo Sugerida (4 personas)

| Persona | Responsabilidad |
|---------|-----------------|
| **Dev 1** | Infra AWS (CDK, Lambda, S3, DynamoDB) |
| **Dev 2** | Backend Python (FastAPI, Bedrock integration) |
| **Dev 3** | Flutter app (UI, cámara, upload) |
| **Dev 4** | Integración, testing, demo, presentación |

---

## Siguiente Paso

Con este diseño aprobado, el siguiente paso es crear un **plan de implementación detallado** con tareas específicas por día y por persona.
