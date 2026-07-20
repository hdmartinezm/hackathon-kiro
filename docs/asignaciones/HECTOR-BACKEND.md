# 🔧 Asignación: Hector (Backend Lead)

**Rol:** Backend + Infraestructura AWS
**GitHub:** hdmartinezm
**Rama base:** `dev`
**Convención de ramas:** `feat/backend-*` o `feat/infra-*`

---

## Resumen de Responsabilidades

Eres responsable de todo el backend serverless (FastAPI + Lambda), la integración con AWS (S3, Bedrock, DynamoDB), el despliegue con CDK y la preparación de la demo técnica.

---

## Distribución por Día

| Día | Entregable | Estado |
|-----|-----------|--------|
| **D1** | CDK deploy + Bedrock access | ⬜ |
| **D2** | Backend endpoints completos | ⬜ |
| **D3** | Pipeline Bedrock (análisis visual + audio) | ⬜ |
| **D4** | Debug/soporte al equipo | ⬜ |
| **D5** | Video demo técnica | ⬜ |
| **D6** | Práctica pitch | ⬜ |
| **D7** | Presentar | ⬜ |

---

## Día 1: CDK Deploy + Bedrock Access

### Objetivos
- Infraestructura base desplegada y funcional
- Bedrock accesible desde Lambda
- URL de API Gateway disponible para el equipo

### Tareas Específicas (del spec)

**Task 13: Infraestructura AWS CDK**
- [ ] 13.1 Crear `infra/stacks/babyhealth_stack.py` con S3 bucket (lifecycle 24h, bloqueo público)
- [ ] 13.2 Agregar DynamoDB table con partition key `session_id` y sort key `timestamp`
- [ ] 13.3 Agregar Lambda function con handler Mangum, runtime Python 3.11, timeout 30s
- [ ] 13.4 Agregar API Gateway con throttling y CORS
- [ ] 13.5 Configurar IAM roles con permisos mínimos (S3, Bedrock invoke, DynamoDB)
- [ ] 13.6 Agregar CloudWatch log group con retención 14 días

**Task 1: Configuración Backend Base**
- [ ] 1.1 Actualizar `requirements.txt`: boto3, mangum, pydantic>=2.0, python-dateutil
- [ ] 1.2 Crear `backend/app/config.py` con variables de entorno
- [ ] 1.5 Crear `backend/lambda_handler.py` con Mangum handler

### Entregables del Día
```
✅ CDK stack desplegado exitosamente
✅ API Gateway URL compartida en Discord (#anuncios)
✅ Verificar: aws bedrock list-foundation-models funciona
✅ Lambda responde a /health (aunque sea placeholder)
```

### Comandos Útiles
```bash
# Deploy CDK
cd infra
cdk deploy --profile Sandbox-Hackathon

# Verificar Bedrock
aws bedrock list-foundation-models --region us-east-1 --profile Sandbox-Hackathon

# Test Lambda local
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

---

## Día 2: Backend Endpoints

### Objetivos
- Todos los endpoints funcionales y testeables
- Modelos Pydantic definidos
- CORS configurado para la app Flutter

### Tareas Específicas

**Task 1 (continuación): Modelos y estructura**
- [ ] 1.3 Crear `backend/app/models/requests.py` (UploadUrlRequest, AnalyzeRequest, AnalyzeAudioRequest)
- [ ] 1.4 Crear `backend/app/models/responses.py` (UploadUrlResponse, AnalyzeResponse, AudioAnalysisResponse)
- [ ] 1.6 Actualizar `backend/app/main.py` para registrar routers y CORS

**Task 2: Servicio S3 y Upload**
- [ ] 2.1 Crear `backend/app/services/s3_service.py` — generate_presigned_url (expiración 300s)
- [ ] 2.2 Crear `backend/app/routers/upload.py` — POST /upload-url
- [ ] 2.3 Validación: error 400 si file_type no es image/jpeg ni image/png
- [ ] 2.4 s3_key formato: `sessions/{session_id}/{uuid}.{extension}`

**Task 7: Health y Errores**
- [ ] 7.1 Crear `backend/app/routers/health.py` — GET /health
- [ ] 7.2 Middleware de manejo de errores global
- [ ] 7.3 Logging estructurado a CloudWatch
- [ ] 7.4 Validación de entrada para todos los endpoints

**Task 4: DynamoDB**
- [ ] 4.1 Crear `backend/app/services/dynamo_service.py`
- [ ] 4.2 Implementar `save_result`
- [ ] 4.3 Implementar `get_results_by_session`
- [ ] 4.4 Logging en operaciones DynamoDB

### Entregables del Día
```
✅ POST /upload-url genera URL pre-firmada correctamente
✅ GET /health retorna {"status": "ok", "version": "1.0.0"}
✅ Modelos Pydantic validados
✅ Compartir URL base con Francisco y William
```

### Modelos de Referencia

**Request: Upload URL**
```python
class UploadUrlRequest(BaseModel):
    file_type: Literal["image/jpeg", "image/png"]
    session_id: UUID
```

**Response: Analyze**
```python
class AnalyzeResponse(BaseModel):
    session_id: UUID
    estado_general: Literal["normal", "requiere_atencion", "urgente"]
    observaciones: list[str]
    recomendaciones: list[str]
    confianza: float  # 0.0 - 1.0
    disclaimer: str = "Consulte a su pediatra"
    timestamp: datetime
```

---

## Día 3: Pipeline Bedrock

### Objetivos
- Análisis de imagen funcional end-to-end
- Endpoint /analyze-audio para Android operativo
- Lógica de reintentos implementada

### Tareas Específicas

**Task 3: Servicio Bedrock y Análisis Visual**
- [ ] 3.1 Crear `backend/app/services/bedrock_service.py` — función `analyze_image`
- [ ] 3.2 Implementar prompt del sistema (ver abajo)
- [ ] 3.3 Parsing de respuesta JSON con validación de campos
- [ ] 3.4 Detección de calidad de imagen (error amigable si imagen no es adecuada)
- [ ] 3.5 Crear `backend/app/utils/retry.py` — 3 intentos, backoff 1s, 2s, timeout 10s
- [ ] 3.6 Crear `backend/app/routers/analyze.py` — POST /analyze

**Task 6: Endpoint Audio (Android)**
- [ ] 6.1 Crear `backend/app/routers/audio.py` — POST /analyze-audio
- [ ] 6.2 Descarga de espectrograma desde S3
- [ ] 6.3 Clasificación de llanto con Bedrock (prompt específico)
- [ ] 6.4 Validación: 404 si s3_key no existe, 400 si no es espectrograma
- [ ] 6.5 Response con category, label, confidence, recommendation

### Prompt de Bedrock (Análisis Visual)
```
Eres un asistente de orientación para padres. Analiza esta imagen de un bebé.

Evalúa:
- Coloración de piel (busca tonos amarillentos que podrían indicar ictericia)
- Expresión facial (signos de malestar o tranquilidad)
- Estado general visible

Responde SOLO en JSON válido con este formato exacto:
{
  "estado_general": "normal | requiere_atencion | urgente",
  "observaciones": ["observación 1", "observación 2"],
  "recomendaciones": ["recomendación 1", "recomendación 2"],
  "confianza": 0.87
}

Reglas:
- Si la imagen no es clara o no muestra un bebé, indica error de calidad
- Siempre incluye al menos una recomendación
- El valor de confianza refleja tu certeza (0.0-1.0)
- Si detectas posible ictericia, estado_general debe ser "requiere_atencion" o "urgente"
```

### Modelo Bedrock
```
Modelo: us.anthropic.claude-sonnet-4-5-20250929-v1:0
Región: us-east-1
Alternativa rápida: us.anthropic.claude-haiku-4-5-20251001-v1:0
```

### Entregables del Día
```
✅ POST /analyze procesa imagen y retorna JSON válido
✅ POST /analyze-audio clasifica espectrograma
✅ Reintentos funcionan correctamente
✅ Latencia < 5 segundos verificada
```

---

## Día 4: Debug / Soporte

### Objetivos
- Resolver bugs reportados por el equipo
- Optimizar latencia si es necesario
- Asegurar que los endpoints están estables para integración

### Actividades
- [ ] Revisar logs en CloudWatch
- [ ] Resolver issues de CORS si existen
- [ ] Optimizar cold starts si son > 3s
- [ ] Soporte a William para conexión E2E
- [ ] Soporte a Francisco si hay errores de API

---

## Día 5: Video Demo

### Objetivos
- Grabar demo técnica del backend funcionando
- Mostrar flujo completo: upload → análisis → resultado

### Actividades
- [ ] Preparar datos de prueba (imagen de bebé, espectrograma)
- [ ] Grabar con Postman/curl el flujo completo
- [ ] Documentar métricas de latencia reales
- [ ] Colaborar con el equipo en el video final

---

## Día 6-7: Pitch y Presentación

- [ ] Practicar la sección de arquitectura del pitch (30s-1min)
- [ ] Tener backup de video pregrabado por si la demo falla en vivo
- [ ] Estar disponible para soporte técnico durante la presentación

---

## Referencia Rápida: Estructura de Archivos

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── config.py
│   ├── models/
│   │   ├── requests.py
│   │   └── responses.py
│   ├── routers/
│   │   ├── health.py
│   │   ├── upload.py
│   │   ├── analyze.py
│   │   └── audio.py
│   ├── services/
│   │   ├── s3_service.py
│   │   ├── bedrock_service.py
│   │   └── dynamo_service.py
│   └── utils/
│       ├── retry.py
│       └── validators.py
├── tests/
├── requirements.txt
└── lambda_handler.py
```

---

## Criterios de Rendimiento

| Métrica | Objetivo |
|---------|----------|
| Latencia imagen | < 5 segundos |
| Cold start Lambda | < 3 segundos |
| Uptime API | 99.9% |
| Respuesta /health | < 500ms |

---

## Contactos para Coordinación

| Necesito de... | Para... |
|----------------|---------|
| William | Probar integración E2E, servicios Flutter |
| Francisco | Confirmar formato de responses para las pantallas |
| Alvaro | Assets para la demo, diseño del pitch deck |
