# BabyHealth - Prompt para Spec-Driven Development

> Usar este prompt como input para generar especificaciones, requerimientos, diseño y plan de tareas

---

## CONTEXTO DEL PROYECTO

### Informacion General
- **Nombre:** BabyHealth
- **Tipo:** App movil (Flutter) con backend serverless (AWS)
- **Hackathon:** AWS Hackathon
- **Duracion:** 7 dias (20-27 julio 2026)
- **Equipo:** 4 personas
- **Criterio principal de evaluacion:** Innovacion / Originalidad

### Problema que Resuelve
Los padres primerizos frecuentemente tienen dudas sobre el estado de salud de su bebe, con acceso limitado a orientacion medica fuera de horarios de consulta. Senales tempranas de condiciones como ictericia o malestar pueden pasar desapercibidas.

### Solucion Propuesta
App movil que permite a padres obtener orientacion sobre el estado de salud de su bebe mediante analisis multimodal:
1. **Analisis de imagen** - Detecta coloracion de piel (ictericia), expresion facial, estado general
2. **Analisis de audio** - Clasifica tipo de llanto del bebe (hambre, dolor, cansancio, etc.)

**Disclaimer obligatorio:** La app es un asistente informativo, NO reemplaza consulta medica profesional.

---

## ARQUITECTURA TECNICA

### Stack Tecnologico

| Capa | Tecnologia |
|------|------------|
| **Frontend** | Flutter (Dart) - iOS y Android |
| **Backend** | Python + FastAPI + Mangum (Lambda) |
| **Infraestructura** | AWS CDK (TypeScript o Python) |
| **Base de datos** | DynamoDB |
| **Almacenamiento** | S3 (imagenes, audio) |
| **API** | API Gateway (REST) |
| **IA Imagen** | Amazon Bedrock - Claude Sonnet 4.5 Vision |
| **IA Audio iOS** | DeepInfant V2 (CoreML) - On-device |
| **IA Audio Android** | YAMNet (TFLite) + Bedrock - Hibrido |

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        Flutter App (iOS/Android)                         │
├─────────────────────────┬───────────────────────────────────────────────┤
│     IMAGEN (Cloud)      │              AUDIO (On-Device)                │
│                         │                                               │
│  Foto del bebe          │    ┌─────────────┐      ┌─────────────┐       │
│       │                 │    │    iOS      │      │   Android   │       │
│       ▼                 │    │ DeepInfant  │      │   YAMNet    │       │
│  S3 (pre-signed URL)    │    │ CoreML V2   │      │   TFLite    │       │
│       │                 │    │ 9 clases    │      │ 521 clases  │       │
│       ▼                 │    │ 89% acc     │      │ 93% det     │       │
│  API Gateway            │    │     │       │      │     │       │       │
│       │                 │    │     ▼       │      │     ▼       │       │
│       ▼                 │    │ Resultado   │      │ Si llanto → │       │
│  Lambda (FastAPI)       │    │ inmediato   │      │ Bedrock     │       │
│       │                 │    └─────────────┘      └─────────────┘       │
│       ▼                 │                                               │
│  Bedrock Vision         │                                               │
│  (Claude Sonnet 4.5)    │                                               │
│       │                 │                                               │
│       ▼                 │                                               │
│  DynamoDB (resultados)  │                                               │
└─────────────────────────┴───────────────────────────────────────────────┘
```

### Modelos de IA Disponibles

| Modelo | ID/Formato | Capacidad | Precision |
|--------|------------|-----------|-----------|
| Claude Sonnet 4.5 | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` | Imagen, Texto | Alta |
| Claude Haiku 4.5 | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Imagen, Texto | Media (rapido) |
| Amazon Nova Pro | `amazon.nova-pro-v1:0` | Video, Imagen, Texto | Alta |
| DeepInfant V2 | CoreML (.mlmodel) 5.3MB | Audio (llanto) | 89% |
| YAMNet | TFLite (.tflite) 4.3MB | Audio (521 clases) | 93% deteccion |

### Categorias de Analisis

**Imagen (Bedrock Vision):**
- Coloracion de piel (deteccion de ictericia)
- Expresion facial (malestar, tranquilidad)
- Estado general visible
- Nivel de urgencia: normal / requiere_atencion / urgente

**Audio - Llanto (DeepInfant):**
| Codigo | Categoria | Patron | Recomendacion |
|--------|-----------|--------|---------------|
| hu | Hambre | Ritmico, repetitivo | Ofrecer alimentacion |
| bu | Eructo | Corto, entrecortado | Ayudar a eructar |
| bp | Dolor abdominal | Agudo, intenso | Masaje suave |
| dc | Incomodidad | Intermitente | Revisar panal |
| ch | Temperatura | Quejumbroso | Verificar ropa |
| ti | Cansancio | Grunidos | Ambiente tranquilo |
| sc | Miedo | Agudo, repentino | Contacto, consuelo |
| lo | Soledad | Baja intensidad | Contacto fisico |
| uk | Desconocido | Variable | Observar signos |

---

## EQUIPO Y ROLES

| Nombre | Rol | Responsabilidades | GitHub |
|--------|-----|-------------------|--------|
| **Hector** | Coordinador + Backend | Infra AWS, CDK, Lambda, Bedrock, API, Pitch | @hdmartinezm |
| **Alvaro** | Diseno + Frontend | UI/UX, Wireframes, Mockups, Assets, Tema | @ajha63 |
| **William** | Fullstack | Integracion Frontend-Backend, Servicios, Testing | @izquierdowaws |
| **Francisco** | Frontend Lead | Flutter, Pantallas, Camara, Audio, UI | @FranciscoJTHG |

---

## FLUJOS DE USUARIO

### Flujo 1: Analisis de Imagen
```
1. Usuario abre app → Ve disclaimer medico
2. Presiona "Analizar Foto"
3. App activa camara → Usuario toma foto del bebe
4. App sube foto a S3 (pre-signed URL)
5. App llama POST /analyze con referencia S3
6. Lambda descarga imagen → Llama Bedrock Vision
7. Bedrock analiza y retorna JSON
8. Lambda guarda en DynamoDB → Retorna resultado
9. App muestra resultado con:
   - Estado general (normal/atencion/urgente)
   - Observaciones
   - Recomendaciones
   - Disclaimer
```

### Flujo 2: Analisis de Audio (iOS)
```
1. Usuario presiona "Analizar Llanto"
2. App solicita permiso de microfono
3. Usuario graba 7 segundos de llanto
4. App procesa audio con DeepInfant CoreML (local)
5. Modelo clasifica en 1 de 9 categorias
6. App muestra resultado inmediato:
   - Tipo de llanto
   - Confianza (%)
   - Recomendacion
```

### Flujo 3: Analisis de Audio (Android)
```
1. Usuario presiona "Analizar Llanto"
2. App solicita permiso de microfono
3. Usuario graba 7 segundos de llanto
4. App procesa con YAMNet TFLite (local)
5. YAMNet detecta si es llanto de bebe (clase 20)
6. Si es llanto:
   a. Genera espectrograma
   b. Sube a S3
   c. Llama Bedrock Vision para clasificar
7. App muestra resultado con categoria y recomendacion
```

---

## ENDPOINTS API

### POST /health
- **Descripcion:** Health check del servicio
- **Response:** `{"status": "ok", "version": "1.0.0"}`

### POST /upload-url
- **Descripcion:** Genera pre-signed URL para subir a S3
- **Request:** `{"file_type": "image/jpeg", "session_id": "uuid"}`
- **Response:** `{"upload_url": "https://...", "s3_key": "sessions/uuid/image.jpg"}`

### POST /analyze
- **Descripcion:** Analiza imagen con Bedrock Vision
- **Request:** `{"s3_key": "sessions/uuid/image.jpg", "session_id": "uuid"}`
- **Response:**
```json
{
  "session_id": "uuid",
  "estado_general": "normal|requiere_atencion|urgente",
  "observaciones": ["Coloracion de piel normal", "Expresion tranquila"],
  "recomendaciones": ["Continuar monitoreo regular"],
  "confianza": 0.87,
  "disclaimer": "Esta informacion es orientativa. Consulte a su pediatra.",
  "timestamp": "2026-07-21T10:30:00Z"
}
```

### POST /analyze-audio (Android)
- **Descripcion:** Analiza espectrograma de audio con Bedrock
- **Request:** `{"s3_key": "sessions/uuid/spectrogram.png"}`
- **Response:**
```json
{
  "category": "hungry",
  "label": "Hambre",
  "confidence": 0.82,
  "recommendation": "Ofrecer alimentacion"
}
```

### GET /sessions/{session_id}
- **Descripcion:** Obtiene historial de analisis de una sesion
- **Response:** Lista de analisis previos

---

## PANTALLAS DE LA APP

### 1. HomeScreen
- Logo BabyHealth
- Disclaimer medico (obligatorio)
- Boton "Analizar Foto" (principal)
- Boton "Analizar Llanto" (secundario)
- Link a historial

### 2. CameraScreen
- Preview de camara
- Guia visual para centrar rostro del bebe
- Boton de captura
- Indicador de calidad de luz

### 3. AudioScreen
- Boton grande de grabar
- Indicador de tiempo (0-7 segundos)
- Visualizacion de ondas de audio
- Boton detener/cancelar

### 4. ResultScreen
- Indicador de estado (color: verde/amarillo/rojo)
- Estado general prominente
- Lista de observaciones
- Lista de recomendaciones
- Disclaimer siempre visible
- Boton "Nuevo Analisis"
- Boton "Consultar Pediatra" (link externo)

### 5. HistoryScreen (opcional)
- Lista de analisis previos
- Filtro por fecha
- Ver detalle de cada analisis

---

## CRONOGRAMA (7 DIAS)

### Dia 1 - Setup
| Responsable | Tarea |
|-------------|-------|
| Hector | CDK deploy (S3, DynamoDB, Lambda, API Gateway) |
| Hector | Verificar acceso Bedrock |
| Francisco | Setup proyecto Flutter + estructura |
| Alvaro | Wireframes de 3 pantallas principales |
| William | Revisar plan, preparar servicios |

### Dia 2 - Backend + UI Base
| Responsable | Tarea |
|-------------|-------|
| Hector | Endpoints: /health, /upload-url, /analyze |
| Hector | Integracion Bedrock Vision |
| Francisco | HomeScreen + DisclaimerWidget |
| Alvaro | Mockups alta fidelidad |
| William | api_service.dart, s3_service.dart |

### Dia 3 - Flutter Core
| Responsable | Tarea |
|-------------|-------|
| Hector | Probar pipeline completo, ajustar prompts |
| Francisco | CameraScreen con captura |
| Alvaro | Definir tema (colores, tipografia) |
| William | Integrar servicios con pantallas |

### Dia 4 - Integracion
| Responsable | Tarea |
|-------------|-------|
| Hector | Soporte backend, debug |
| Francisco | ResultScreen con estados |
| Alvaro | Exportar assets finales |
| William | Conectar flujo completo end-to-end |

### Dia 5 - Polish + Audio
| Responsable | Tarea |
|-------------|-------|
| Hector | Integrar DeepInfant (iOS), endpoint /analyze-audio |
| Francisco | AudioScreen UI |
| Alvaro | Pulir UI |
| William | Integrar YAMNet (Android), testing |

### Dia 6 - Buffer
| Responsable | Tarea |
|-------------|-------|
| Hector | Practica de pitch |
| Francisco | Bugs menores |
| Alvaro | Slides de arquitectura |
| William | Testing final |

### Dia 7 - Presentacion
| Responsable | Tarea |
|-------------|-------|
| Todos | Checklist pre-demo |
| Hector | Calentar Lambda, presentar pitch |
| Todos | Soporte Q&A |

---

## RECURSOS DISPONIBLES

### Repositorios
- **Proyecto:** https://github.com/hdmartinezm/hackathon-kiro
- **DeepInfant:** https://github.com/skytells-research/DeepInfant
- **YAMNet TFLite:** https://github.com/Jaskaran197/YAMNET-Sound-Classification-python
- **Donate-a-Cry:** https://github.com/gveres/donateacry-corpus

### AWS
- **Cuenta:** 539562792848 (Sandbox-Hackathon)
- **Region:** us-east-1
- **Perfil:** Sandbox-Hackathon

### Herramientas
- **Trello:** https://trello.com/b/sSyhs88y/hackathon-kiro
- **Drive:** https://drive.google.com/drive/folders/1DkNVXJSykjKp0vQEu7TzQqcRcU9T9c-9

---

## CRITERIOS DE EXITO

### MVP Minimo (Dias 1-4)
- [ ] Infra AWS desplegada y funcionando
- [ ] Endpoint /analyze funcionando con Bedrock
- [ ] App Flutter captura foto y muestra resultado
- [ ] Flujo completo imagen end-to-end

### MVP Completo (Dias 1-5)
- [ ] Todo lo anterior +
- [ ] Analisis de audio funcionando (iOS con DeepInfant)
- [ ] UI pulida y profesional

### Stretch Goals
- [ ] Analisis de audio en Android (YAMNet)
- [ ] Historial de analisis
- [ ] Analisis de video (Nova Pro)

---

## PROMPT PARA GENERAR SPEC

Usa la siguiente informacion para generar una especificacion completa del proyecto BabyHealth:

**Objetivo:** Crear una app movil (Flutter) que ayude a padres primerizos a evaluar el estado de salud de su bebe mediante analisis de imagen (coloracion de piel, expresion facial) y audio (tipo de llanto), usando IA multimodal.

**Restricciones:**
- Tiempo: 7 dias de hackathon
- Equipo: 4 personas (1 backend, 2 frontend, 1 diseno)
- Stack: Flutter + AWS (Lambda, S3, DynamoDB, Bedrock)
- Modelos: Claude Sonnet 4.5 (imagen), DeepInfant (audio iOS), YAMNet (audio Android)

**Entregables esperados:**
1. **Requerimientos funcionales y no funcionales**
2. **Historias de usuario**
3. **Diagramas de flujo detallados**
4. **Especificacion de API (OpenAPI/Swagger)**
5. **Wireframes/Mockups**
6. **Plan de pruebas**
7. **Backlog priorizado**
8. **Definicion de Done**

**Consideraciones especiales:**
- Disclaimer medico obligatorio en toda la app
- Privacidad: audio procesado on-device cuando sea posible
- Accesibilidad: considerar padres estresados/con poco sueno
- Offline: audio en iOS funciona sin internet
- Demo: tener plan B (video pregrabado) si falla en vivo

---

## OUTPUT ESPERADO

Genera los siguientes documentos:

1. **REQUIREMENTS.md** - Requerimientos funcionales y no funcionales
2. **USER-STORIES.md** - Historias de usuario en formato As a... I want... So that...
3. **API-SPEC.yaml** - Especificacion OpenAPI 3.0
4. **TEST-PLAN.md** - Casos de prueba por pantalla y endpoint
5. **BACKLOG.md** - Tareas priorizadas con estimacion
6. **DEFINITION-OF-DONE.md** - Criterios de aceptacion

Cada documento debe ser:
- Claro y conciso
- Accionable por el equipo
- Alineado con el cronograma de 7 dias
- Enfocado en el MVP primero
