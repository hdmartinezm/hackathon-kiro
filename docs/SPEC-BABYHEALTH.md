# BabyHealth - Especificacion del Proyecto

## Vision del Producto

**BabyHealth** es una aplicacion movil que permite a padres primerizos obtener orientacion inmediata sobre el estado de salud de su bebe mediante analisis de inteligencia artificial multimodal, combinando vision por computadora y analisis de audio.

---

## Problema

Los padres primerizos enfrentan:
- **Incertidumbre constante** sobre el estado de salud de su bebe
- **Acceso limitado** a orientacion medica fuera de horarios de consulta
- **Dificultad para interpretar** senales como coloracion de piel o tipos de llanto
- **Ansiedad** por no saber si una condicion requiere atencion urgente

**Datos relevantes:**
- Ictericia neonatal afecta al 60% de recien nacidos
- Solo el 50% de los casos son detectados a tiempo por los padres
- El llanto del bebe tiene patrones distintivos segun la necesidad

---

## Solucion

App movil con dos capacidades principales:

### 1. Analisis Visual (Cloud)
- Captura foto del bebe
- IA analiza coloracion de piel (ictericia), expresion facial, estado general
- Retorna evaluacion con nivel de urgencia y recomendaciones

### 2. Analisis de Audio (On-Device)
- Graba 7 segundos de llanto
- IA clasifica el tipo de llanto en tiempo real
- Retorna categoria (hambre, dolor, cansancio, etc.) con recomendacion

**Disclaimer:** Herramienta de orientacion, no sustituye consulta medica profesional.

---

## Impacto Tecnologico (30%)

### Necesidad Real
| Problema | Solucion BabyHealth |
|----------|---------------------|
| Padres no reconocen ictericia temprana | Deteccion visual con IA entrenada |
| No entienden por que llora el bebe | Clasificacion de llanto en 9 categorias |
| Acceso limitado a pediatra 24/7 | Orientacion inmediata en el telefono |
| Ansiedad por no saber si es grave | Indicador claro: normal/atencion/urgente |

### Valor Agregado
- **Educativo:** Ensena a padres a reconocer patrones
- **Preventivo:** Deteccion temprana de condiciones
- **Accesible:** Funciona offline (audio), bajo costo
- **Escalable:** Potencial para clinicas, hospitales, seguros

### Publico Objetivo
- Padres primerizos (principal)
- Cuidadores y familiares
- Clinicas pediatricas (futuro B2B)

---

## Innovacion (30%)

### Comparativa con Soluciones Existentes

| Solucion | Imagen | Audio | Offline | IA Avanzada | Costo |
|----------|--------|-------|---------|-------------|-------|
| Google/WebMD | ❌ | ❌ | ❌ | ❌ | Gratis |
| Apps de llanto | ❌ | ✅ | ❌ | Basica | $5-10 |
| Telemedicina | ✅ | ✅ | ❌ | Humano | $50+ |
| **BabyHealth** | ✅ | ✅ | ✅ | Claude Vision + DeepInfant | Gratis |

### Ventajas Tecnicas

1. **Multimodal:** Unica app que combina imagen + audio con IA avanzada
2. **Hibrido Cloud/Edge:** Audio procesado on-device (privacidad, velocidad)
3. **Claude Vision:** Modelo de ultima generacion para analisis visual
4. **Escalabilidad:** Arquitectura serverless, escala automaticamente
5. **Costo eficiente:** Lambda escala a cero, paga por uso

### Innovaciones Especificas

| Area | Innovacion |
|------|------------|
| **Vision** | Uso de Claude Sonnet 4.5 para deteccion de ictericia sin hardware especial |
| **Audio** | DeepInfant V2 con 89% precision en clasificacion de llanto |
| **Arquitectura** | Procesamiento hibrido: on-device (audio) + cloud (imagen) |
| **Privacidad** | Audio nunca sale del dispositivo (iOS) |

---

## Funcionalidades

### F1: Analisis de Imagen
**Descripcion:** Usuario toma foto del bebe, la app analiza y muestra resultado.

**Flujo:**
```
Camara → Captura → S3 → Lambda → Bedrock Vision → Resultado
```

**Input:** Imagen JPG/PNG del rostro del bebe
**Output:**
```json
{
  "estado": "normal | requiere_atencion | urgente",
  "observaciones": [
    "Coloracion de piel dentro de parametros normales",
    "Expresion facial tranquila"
  ],
  "recomendaciones": [
    "Continuar monitoreo regular",
    "Si nota cambios, consulte a su pediatra"
  ],
  "confianza": 0.87
}
```

**Prompt de Bedrock:**
```
Eres un asistente de orientacion para padres. Analiza esta imagen de un bebe.

Evalua:
- Coloracion de piel (busca tonos amarillentos que podrian indicar ictericia)
- Expresion facial (signos de malestar o tranquilidad)
- Estado general visible

Responde en JSON con: estado_general, observaciones, recomendaciones.
Siempre incluye disclaimer de consultar pediatra.
```

### F2: Analisis de Audio
**Descripcion:** Usuario graba llanto, la app clasifica el tipo y sugiere accion.

**Flujo iOS:**
```
Microfono → 7 segundos → DeepInfant CoreML → Resultado inmediato
```

**Flujo Android:**
```
Microfono → 7 segundos → YAMNet TFLite → Detecta llanto → Bedrock → Resultado
```

**Categorias de Llanto:**
| Categoria | Patron Acustico | Recomendacion |
|-----------|-----------------|---------------|
| Hambre | Ritmico, repetitivo, intensidad creciente | Ofrecer alimentacion |
| Dolor | Agudo, intenso, sostenido | Revisar, consultar si persiste |
| Cansancio | Grunidos, bostezos, intensidad variable | Ambiente tranquilo, dormir |
| Incomodidad | Intermitente, quejumbroso | Revisar panal, posicion, ropa |
| Eructo | Corto, entrecortado | Sostener vertical, palmaditas |
| Temperatura | Continuo, quejumbroso | Verificar si tiene frio/calor |
| Miedo | Agudo, repentino, sobresalto | Contacto, voz suave, mecer |
| Soledad | Baja intensidad, pausado | Contacto fisico, presencia |

### F3: Pantalla de Resultado
**Descripcion:** Muestra resultado del analisis con indicador visual claro.

**Componentes:**
- Indicador de estado (semaforo: verde/amarillo/rojo)
- Titulo del estado
- Lista de observaciones
- Lista de recomendaciones
- Confianza del analisis (%)
- Disclaimer medico (siempre visible)
- Boton "Nuevo Analisis"
- Boton "Contactar Pediatra"

### F4: Disclaimer Medico
**Descripcion:** Aviso legal obligatorio en toda la app.

**Texto:**
> "BabyHealth es una herramienta de orientacion. Los resultados son informativos y NO sustituyen la consulta con un profesional de la salud. Ante cualquier duda o emergencia, consulte a su pediatra o acuda a urgencias."

**Ubicacion:**
- Splash screen al abrir
- Footer en pantalla principal
- Incluido en cada resultado

---

## Arquitectura AWS (10%)

### Servicios Utilizados

| Servicio | Uso | Justificacion |
|----------|-----|---------------|
| **Amazon Bedrock** | Analisis de imagen con Claude Vision | IA generativa de ultima generacion |
| **AWS Lambda** | Backend serverless (FastAPI + Mangum) | Escala automatico, costo por uso |
| **Amazon S3** | Almacenamiento de imagenes | Pre-signed URLs, seguro, economico |
| **Amazon API Gateway** | Endpoint HTTPS publico | Manejo de requests, throttling |
| **Amazon DynamoDB** | Almacenamiento de resultados | NoSQL, baja latencia, serverless |
| **Amazon CloudWatch** | Logs y monitoreo | Observabilidad, debugging |

### Diagrama de Arquitectura

```
                    ┌─────────────────────────────────┐
                    │         Flutter App             │
                    │        (iOS/Android)            │
                    └───────────────┬─────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
            ┌───────────┐   ┌───────────┐   ┌───────────┐
            │  Camara   │   │ Microfono │   │ Historial │
            └─────┬─────┘   └─────┬─────┘   └─────┬─────┘
                  │               │               │
                  ▼               ▼               │
            ┌───────────┐   ┌───────────┐         │
            │    S3     │   │  On-Device│         │
            │  (imagen) │   │ DeepInfant│         │
            └─────┬─────┘   │  /YAMNet  │         │
                  │         └───────────┘         │
                  ▼                               │
            ┌───────────┐                         │
            │    API    │◄────────────────────────┘
            │  Gateway  │
            └─────┬─────┘
                  │
                  ▼
            ┌───────────┐
            │  Lambda   │
            │ (FastAPI) │
            └─────┬─────┘
                  │
         ┌────────┴────────┐
         ▼                 ▼
   ┌───────────┐     ┌───────────┐
   │  Bedrock  │     │ DynamoDB  │
   │  (Claude) │     │(resultados)│
   └───────────┘     └───────────┘
```

### Configuracion de Bedrock

**Modelo:** `us.anthropic.claude-sonnet-4-5-20250929-v1:0`
**Region:** us-east-1
**Alternativa rapida:** `us.anthropic.claude-haiku-4-5-20251001-v1:0`

---

## Entregables (30%)

### 1. Repositorio GitHub
- **URL:** https://github.com/hdmartinezm/hackathon-kiro
- **Estructura:**
```
hackathon-kiro/
├── flutter_app/          # App Flutter
├── backend/              # Lambda FastAPI
├── infra/                # AWS CDK
├── docs/                 # Documentacion
└── README.md             # Instrucciones
```

### 2. Demo en Linea
- **App:** Distribuida via TestFlight (iOS) / APK (Android)
- **Backend:** API Gateway URL publica
- **Video demo:** YouTube/Vimeo (5 min max)

### 3. Video de Presentacion (5 min)

| Tiempo | Seccion | Contenido |
|--------|---------|-----------|
| 0:00-0:30 | Problema | Historia de padres primerizos, estadisticas |
| 0:30-1:30 | Demo | Flujo completo: foto → resultado |
| 1:30-2:30 | Demo Audio | Grabar llanto → clasificacion |
| 2:30-3:30 | Arquitectura | Diagrama AWS, servicios usados |
| 3:30-4:30 | Innovacion | Comparativa, ventajas tecnicas |
| 4:30-5:00 | Cierre | Impacto, futuro, disclaimer |

### 4. Documentacion Adicional
- Diagrama de arquitectura (incluido)
- Casos de uso (este documento)
- Especificacion de API

---

## API Specification

### Base URL
```
https://{api-id}.execute-api.us-east-1.amazonaws.com/prod
```

### Endpoints

#### GET /health
```yaml
summary: Health check
responses:
  200:
    content:
      application/json:
        example:
          status: "ok"
          version: "1.0.0"
```

#### POST /upload-url
```yaml
summary: Genera URL pre-firmada para subir imagen a S3
requestBody:
  content:
    application/json:
      schema:
        type: object
        properties:
          file_type:
            type: string
            example: "image/jpeg"
          session_id:
            type: string
            format: uuid
responses:
  200:
    content:
      application/json:
        example:
          upload_url: "https://bucket.s3.amazonaws.com/..."
          s3_key: "sessions/uuid/image.jpg"
          expires_in: 300
```

#### POST /analyze
```yaml
summary: Analiza imagen con Bedrock Vision
requestBody:
  content:
    application/json:
      schema:
        type: object
        required: [s3_key, session_id]
        properties:
          s3_key:
            type: string
          session_id:
            type: string
            format: uuid
responses:
  200:
    content:
      application/json:
        example:
          session_id: "550e8400-e29b-41d4-a716-446655440000"
          estado_general: "normal"
          observaciones:
            - "Coloracion de piel normal"
            - "Expresion facial tranquila"
          recomendaciones:
            - "Continuar monitoreo regular"
          confianza: 0.87
          disclaimer: "Consulte a su pediatra"
          timestamp: "2026-07-21T10:30:00Z"
```

#### POST /analyze-audio
```yaml
summary: Analiza espectrograma de audio (Android)
requestBody:
  content:
    application/json:
      schema:
        type: object
        properties:
          s3_key:
            type: string
responses:
  200:
    content:
      application/json:
        example:
          category: "hungry"
          label: "Hambre"
          confidence: 0.82
          recommendation: "Ofrecer alimentacion"
```

---

## Casos de Prueba

### CP1: Analisis de Imagen - Caso Normal
- **Entrada:** Foto de bebe con coloracion normal
- **Esperado:** estado="normal", observaciones positivas
- **Validar:** Respuesta < 5 segundos, JSON valido

### CP2: Analisis de Imagen - Posible Ictericia
- **Entrada:** Foto de bebe con tono amarillento
- **Esperado:** estado="requiere_atencion", mencion de ictericia
- **Validar:** Recomendacion de consultar pediatra

### CP3: Analisis de Audio - Llanto de Hambre
- **Entrada:** Audio de 7 segundos con patron ritmico
- **Esperado:** category="hungry", confidence > 0.7
- **Validar:** Respuesta < 2 segundos (iOS)

### CP4: Analisis de Audio - No es Llanto
- **Entrada:** Audio de ruido ambiente
- **Esperado:** Mensaje "No se detecta llanto de bebe"
- **Validar:** No intenta clasificar

### CP5: Sin Conexion (iOS Audio)
- **Entrada:** Dispositivo sin internet, grabar llanto
- **Esperado:** Clasificacion funciona correctamente
- **Validar:** DeepInfant procesa offline

### CP6: Imagen de Baja Calidad
- **Entrada:** Foto borrosa o mal iluminada
- **Esperado:** Mensaje de error amigable
- **Validar:** Solicita tomar nueva foto

---

## Metricas de Exito

| Metrica | Objetivo | Medicion |
|---------|----------|----------|
| Latencia imagen | < 5 segundos | CloudWatch |
| Latencia audio iOS | < 1 segundo | App timer |
| Precision llanto | > 85% | Testing manual |
| Uptime API | 99.9% | CloudWatch |
| Cold start Lambda | < 3 segundos | CloudWatch |

---

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigacion |
|--------|--------------|---------|------------|
| Bedrock no responde | Baja | Alto | Retry + mensaje amigable |
| Cold start lento | Media | Medio | Provisioned concurrency / precalentar |
| Audio no clasifica bien | Media | Medio | Umbral de confianza + "desconocido" |
| Demo falla en vivo | Media | Alto | Video pregrabado como backup |
| Imagen muy oscura | Alta | Bajo | Validacion previa + guia al usuario |

---

## Futuras Mejoras (Post-Hackathon)

1. **Historial de analisis** - Trackear evolucion del bebe
2. **Notificaciones** - Alertas de seguimiento
3. **Integracion con pediatras** - Compartir resultados
4. **Analisis de video** - Usar Amazon Nova Pro
5. **Modelo personalizado** - Fine-tuning con datos reales
6. **B2B** - Version para clinicas y hospitales
