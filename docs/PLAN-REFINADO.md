# BabyHealth - Plan Refinado

> Asistente de cuidado neonatal con IA multimodal

**Hackathon AWS:** 20-27 julio 2026
**Equipo:** 4 personas

---

## Resumen del Proyecto

App móvil (Flutter) que permite a padres primerizos obtener orientación sobre el estado de salud de su bebé mediante análisis de imagen usando Claude Vision en Amazon Bedrock.

**Flujo:**
1. Usuario toma foto del bebé
2. App sube imagen a S3
3. Lambda invoca Bedrock Vision para análisis
4. Usuario recibe observaciones y recomendaciones

---

## Arquitectura AWS

```
┌─────────────────┐
│   Flutter App   │
│  (iOS/Android)  │
└────────┬────────┘
         │ 1. Captura imagen
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
┌───────┐ ┌────────┐
│  S3   │ │Bedrock │
│(media)│ │(Vision)│
└───────┘ └────────┘
         │
         ▼
┌─────────────────┐
│   DynamoDB      │
│  (resultados)   │
└─────────────────┘
```

### Servicios AWS

| Servicio | Uso |
|----------|-----|
| **Bedrock** | Análisis multimodal (ver modelos abajo) |
| **Lambda** | Backend FastAPI con mangum |
| **API Gateway** | Endpoint HTTPS público |
| **S3** | Almacenamiento de imágenes/videos (pre-signed URLs) |
| **DynamoDB** | Sesiones y resultados |
| **CloudWatch** | Logs y monitoreo |

### Modelos de Bedrock Disponibles

| Modelo | ID | Capacidades | Uso recomendado |
|--------|-----|-------------|-----------------|
| **Claude Sonnet 4.5** | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` | Texto, Imagen | Análisis detallado de fotos |
| **Claude Haiku 4.5** | `us.anthropic.claude-haiku-4-5-20251001-v1:0` | Texto, Imagen | Análisis rápido (menor costo) |
| **Amazon Nova Pro** | `amazon.nova-pro-v1:0` | Texto, Imagen, **Video** | Análisis de video del bebé |

#### Capacidades por modalidad

| Modalidad | Modelo recomendado | Estado |
|-----------|-------------------|--------|
| **Imagen** | Claude Sonnet 4.5 | ✅ Verificado y funcionando |
| **Video** | Amazon Nova Pro | ✅ Disponible |
| **Audio** | N/A | ⚠️ No hay soporte directo |

#### Solución para Audio (stretch goal)

El audio del llanto se puede analizar de dos formas:
1. **Espectrograma:** Convertir audio a imagen con `librosa` → Analizar con Vision
2. **Omitir en MVP:** Enfocarse en análisis de imagen (recomendado)

```python
# Ejemplo: Convertir audio a espectrograma
import librosa
import librosa.display
import matplotlib.pyplot as plt

y, sr = librosa.load('llanto.wav')
S = librosa.feature.melspectrogram(y=y, sr=sr)
librosa.display.specshow(librosa.power_to_db(S, ref=np.max))
plt.savefig('espectrograma.png')
# Luego analizar espectrograma.png con Vision
```

---

## Distribución por Roles

### Hector (Coordinador + Backend)
**Responsabilidades:**
- Coordinar equipo y Trello
- Infraestructura AWS (CDK)
- Backend Python/FastAPI
- Integración con Bedrock
- Lambda y API Gateway
- Preparar demo/pitch

**Tareas principales:**
- [ ] Día 1: Setup CDK + deploy infra base
- [ ] Día 1: Solicitar acceso a Bedrock (CRÍTICO)
- [ ] Día 2: Implementar endpoint /analyze
- [ ] Día 2: Integración Bedrock Vision
- [ ] Día 4: Conectar con Flutter
- [ ] Día 6-7: Demo y pitch

---

### Alvaro (Diseño + Frontend)
**Responsabilidades:**
- Diseño UI/UX de la app
- Mockups y wireframes
- Estilos y tema de la app
- Assets (iconos, logos)
- Ayudar con componentes Flutter

**Tareas principales:**
- [ ] Día 1: Wireframes de las 3 pantallas
- [ ] Día 2: Mockups de alta fidelidad
- [ ] Día 3: Definir tema/colores/tipografía
- [ ] Día 4: Exportar assets
- [ ] Día 5: Pulir UI con Francisco
- [ ] Día 7: Preparar slides de presentación

---

### William (Fullstack)
**Responsabilidades:**
- Integración Frontend ↔ Backend
- Servicios Flutter (API, S3)
- Ayudar con backend si necesario
- Testing end-to-end
- Resolver bloqueos entre equipos

**Tareas principales:**
- [ ] Día 2: Implementar servicios S3 en Flutter
- [ ] Día 3: Implementar servicio API en Flutter
- [ ] Día 4: Integración completa app ↔ backend
- [ ] Día 5: Testing edge cases
- [ ] Día 6: Bugs y optimizaciones

---

### Francisco (Frontend Lead)
**Responsabilidades:**
- Estructura Flutter
- Pantallas principales (Home, Camera, Result)
- Lógica de UI
- Manejo de cámara
- Responsive design

**Tareas principales:**
- [ ] Día 1: Setup proyecto Flutter
- [ ] Día 2: HomeScreen + navegación
- [ ] Día 3: CameraScreen con captura
- [ ] Día 4: ResultScreen con estados
- [ ] Día 5: Polish y animaciones
- [ ] Día 6: Testing en dispositivos

---

## Cronograma Día a Día

### Día 1 (Domingo) - Setup
| Quién | Tarea |
|-------|-------|
| **Hector** | CDK deploy (S3, DynamoDB, Lambda, API Gateway) |
| **Hector** | Solicitar acceso a Bedrock (URGENTE) |
| **Alvaro** | Wireframes de 3 pantallas |
| **William** | Ayudar con setup Flutter si necesario |
| **Francisco** | Setup proyecto Flutter + estructura |

**Entregables:**
- [ ] Infra AWS desplegada
- [ ] Acceso a Bedrock solicitado
- [ ] Proyecto Flutter creado
- [ ] Wireframes listos

---

### Día 2 (Lunes) - Backend + UI Base
| Quién | Tarea |
|-------|-------|
| **Hector** | Backend: /health, /upload-url, S3 service |
| **Hector** | Backend: Bedrock service + /analyze |
| **Alvaro** | Mockups de alta fidelidad |
| **William** | Flutter: api_service.dart, s3_service.dart |
| **Francisco** | Flutter: HomeScreen, DisclaimerWidget |

**Entregables:**
- [ ] Backend funcional con todos los endpoints
- [ ] Mockups aprobados
- [ ] HomeScreen funcionando

---

### Día 3 (Martes) - Flutter Core
| Quién | Tarea |
|-------|-------|
| **Hector** | Probar pipeline completo en AWS |
| **Hector** | Ajustar prompts de Bedrock |
| **Alvaro** | Definir tema Flutter (colores, tipografía) |
| **William** | Integrar servicios con pantallas |
| **Francisco** | CameraScreen con captura de imagen |

**Entregables:**
- [ ] Pipeline imagen→S3→Bedrock funcionando
- [ ] CameraScreen captura fotos
- [ ] Tema visual definido

---

### Día 4 (Miércoles) - Integración
| Quién | Tarea |
|-------|-------|
| **Hector** | Soporte backend, debug |
| **Alvaro** | Exportar assets finales |
| **William** | Conectar CameraScreen → API → ResultScreen |
| **Francisco** | ResultScreen con estados (loading, error, success) |

**Entregables:**
- [ ] Flujo completo end-to-end funcionando
- [ ] App conectada al backend real

---

### Día 5 (Jueves) - Polish
| Quién | Tarea |
|-------|-------|
| **Hector** | Grabar video de respaldo |
| **Alvaro** | Pulir UI con Francisco |
| **William** | Testing edge cases |
| **Francisco** | Animaciones y transiciones |

**Entregables:**
- [ ] UI pulida
- [ ] Video de demo grabado
- [ ] Casos edge manejados

---

### Día 6 (Viernes) - Buffer
| Quién | Tarea |
|-------|-------|
| **Hector** | Práctica de pitch |
| **Alvaro** | Preparar slides de arquitectura |
| **William** | Testing final |
| **Francisco** | Bugs menores |

**Entregables:**
- [ ] Pitch ensayado
- [ ] Diagrama de arquitectura listo

---

### Día 7 (Sábado) - Presentación
| Quién | Tarea |
|-------|-------|
| **Todos** | Checklist pre-demo |
| **Hector** | Calentar Lambda 5 min antes |
| **Hector** | Presentar pitch |
| **Todos** | Soporte durante Q&A |

---

## Checklist Día 1 (CRÍTICO)

### Hector
- [ ] `cdk bootstrap` (si es primera vez)
- [ ] `cdk deploy` - verificar outputs
- [ ] Ir a Bedrock console → Request model access → Claude 3.5 Sonnet
- [ ] Crear archivo `.env` con configuración

### Francisco
- [ ] `flutter create flutter_app --org com.babyhealth`
- [ ] Agregar dependencias en pubspec.yaml
- [ ] `flutter pub get`
- [ ] Verificar que compila: `flutter analyze`

### Alvaro
- [ ] Crear wireframes en Figma/papel
- [ ] Compartir en Google Drive

### William
- [ ] Revisar plan de integración
- [ ] Preparar estructura de servicios

---

## Estructura del Proyecto

```
hackathon-kiro/
├── flutter_app/           # App Flutter
│   ├── lib/
│   │   ├── config/        # Constantes, configuración
│   │   ├── screens/       # Pantallas (home, camera, result)
│   │   ├── services/      # API, S3
│   │   ├── models/        # Modelos de datos
│   │   └── widgets/       # Componentes reutilizables
│   └── pubspec.yaml
├── backend/               # Python + FastAPI
│   ├── app/
│   │   ├── routes/        # Endpoints
│   │   ├── services/      # S3, Bedrock, DynamoDB
│   │   └── models/        # Schemas Pydantic
│   └── requirements.txt
├── infra/                 # AWS CDK
│   ├── stacks/
│   └── app.py
└── docs/                  # Documentación
```

---

## Comandos Útiles

```bash
# Backend local
cd backend && source venv/bin/activate && uvicorn app.main:app --reload

# Deploy infra
cd infra && cdk deploy

# Flutter
cd flutter_app && flutter run

# Logs Lambda
aws logs tail /aws/lambda/BabyHealthStack-ApiFunction --follow --profile Sandbox-Hackathon

# Probar Bedrock (imagen)
aws bedrock-runtime invoke-model \
  --model-id us.anthropic.claude-sonnet-4-5-20250929-v1:0 \
  --region us-east-1 \
  --profile Sandbox-Hackathon \
  --content-type application/json \
  --accept application/json \
  --body "$(echo '{"anthropic_version":"bedrock-2023-05-31","max_tokens":100,"messages":[{"role":"user","content":"Hola"}]}' | base64)" \
  /tmp/test.json && cat /tmp/test.json

# Probar Amazon Nova Pro (video)
aws bedrock-runtime invoke-model \
  --model-id amazon.nova-pro-v1:0 \
  --region us-east-1 \
  --profile Sandbox-Hackathon \
  --content-type application/json \
  --accept application/json \
  --body "$(echo '{"messages":[{"role":"user","content":[{"text":"Hola"}]}],"inferenceConfig":{"maxTokens":100}}' | base64)" \
  /tmp/nova-test.json && cat /tmp/nova-test.json
```

---

## Links Importantes

| Recurso | URL |
|---------|-----|
| Bedrock Console | https://us-east-1.console.aws.amazon.com/bedrock |
| CloudWatch | https://us-east-1.console.aws.amazon.com/cloudwatch |
| GitHub | https://github.com/hdmartinezm/hackathon-kiro |
| Trello | https://trello.com/b/sSyhs88y/hackathon-kiro |
| Drive | https://drive.google.com/drive/folders/1DkNVXJSykjKp0vQEu7TzQqcRcU9T9c-9 |
