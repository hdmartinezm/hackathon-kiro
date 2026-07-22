# BabyHealth Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir un MVP funcional de BabyHealth para el hackathon AWS (20-27 julio 2026)

**Architecture:** App Flutter que captura imagen de bebé, sube a S3, llama a Lambda/FastAPI que invoca Bedrock Vision, y muestra resultado al usuario.

**Tech Stack:** Flutter/Dart, Python/FastAPI, AWS (Lambda, API Gateway, S3, DynamoDB, Bedrock)

## Global Constraints

- Región AWS: `us-east-1` (todos los servicios)
- Python: 3.11+
- Flutter: 3.x estable
- Bedrock model (imagen): `us.anthropic.claude-sonnet-4-5-20250929-v1:0`
- Bedrock model (video): `amazon.nova-pro-v1:0` (opcional)
- Todas las respuestas incluyen disclaimer médico
- Pre-signed URLs con expiración de 15 minutos
- Audio es stretch goal, no bloquea MVP

---

## File Structure

### Backend (`/backend`)
```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # FastAPI app + mangum handler
│   ├── config.py            # Environment variables
│   ├── routes/
│   │   ├── __init__.py
│   │   ├── analyze.py       # POST /analyze endpoint
│   │   └── health.py        # GET /health endpoint
│   ├── services/
│   │   ├── __init__.py
│   │   ├── s3.py            # S3 operations (pre-signed URLs, get object)
│   │   ├── bedrock.py       # Bedrock Vision invocation
│   │   └── dynamodb.py      # DynamoDB operations
│   └── models/
│       ├── __init__.py
│       └── schemas.py       # Pydantic models
├── requirements.txt
├── Dockerfile               # Para desarrollo local
└── template.yaml            # SAM template (opcional)
```

### Frontend (`/flutter_app`)
```
flutter_app/
├── lib/
│   ├── main.dart
│   ├── config/
│   │   └── constants.dart    # API URL, configuración
│   ├── screens/
│   │   ├── home_screen.dart  # Pantalla principal
│   │   ├── camera_screen.dart # Captura de imagen
│   │   └── result_screen.dart # Mostrar resultado
│   ├── services/
│   │   ├── api_service.dart  # Llamadas al backend
│   │   └── s3_service.dart   # Upload pre-signed
│   ├── models/
│   │   └── analysis_result.dart
│   └── widgets/
│       └── disclaimer_widget.dart
├── pubspec.yaml
└── assets/
    └── images/
```

### Infrastructure (`/infra`)
```
infra/
├── app.py                   # CDK app entry point
├── cdk.json
├── requirements.txt
└── stacks/
    ├── __init__.py
    └── babyhealth_stack.py  # All resources
```

---

## Día 1: Setup + Infraestructura

### Task 1.1: Setup del repositorio

**Files:**
- Create: `README.md`
- Create: `.gitignore`
- Create: `backend/`, `flutter_app/`, `infra/`

- [ ] **Step 1: Crear repositorio y estructura**

```bash
mkdir babyhealth && cd babyhealth
git init
```

- [ ] **Step 2: Crear .gitignore**

```gitignore
# Python
__pycache__/
*.py[cod]
.env
venv/

# Flutter
flutter_app/.dart_tool/
flutter_app/build/
flutter_app/.packages

# AWS
.aws-sam/
cdk.out/

# IDE
.idea/
.vscode/
*.iml
```

- [ ] **Step 3: Crear estructura de directorios**

```bash
mkdir -p backend/app/{routes,services,models}
mkdir -p flutter_app/lib/{config,screens,services,models,widgets}
mkdir -p infra/stacks
```

- [ ] **Step 4: Commit inicial**

```bash
git add .
git commit -m "chore: initial project structure"
```

---

### Task 1.2: Solicitar acceso a Bedrock (CRÍTICO)

**Files:** Ninguno (consola AWS)

- [ ] **Step 1: Ir a Bedrock en consola AWS**

```
https://us-east-1.console.aws.amazon.com/bedrock/home?region=us-east-1#/modelaccess
```

- [ ] **Step 2: Solicitar acceso a Claude 3.5 Sonnet**

1. Click "Manage model access"
2. Seleccionar "Anthropic" → "Claude 3.5 Sonnet"
3. Click "Request model access"
4. Completar formulario (uso: "Hackathon project")

- [ ] **Step 3: Verificar estado**

```bash
aws bedrock list-foundation-models --region us-east-1 \
  --query "modelSummaries[?contains(modelId, 'claude-3-5-sonnet')]"
```

Expected: Lista con el modelo (si ya está aprobado)

> **NOTA:** Si no está aprobado, seguir con las demás tareas. Revisar cada mañana.

---

### Task 1.3: Configurar CDK e infraestructura base

**Files:**
- Create: `infra/app.py`
- Create: `infra/stacks/babyhealth_stack.py`
- Create: `infra/requirements.txt`
- Create: `infra/cdk.json`

- [ ] **Step 1: Crear requirements.txt para CDK**

```txt
aws-cdk-lib==2.150.0
constructs>=10.0.0
```

- [ ] **Step 2: Crear cdk.json**

```json
{
  "app": "python3 app.py",
  "context": {
    "@aws-cdk/aws-lambda:recognizeVersionProps": true
  }
}
```

- [ ] **Step 3: Crear app.py**

```python
#!/usr/bin/env python3
import aws_cdk as cdk
from stacks.babyhealth_stack import BabyHealthStack

app = cdk.App()
BabyHealthStack(app, "BabyHealthStack", env=cdk.Environment(region="us-east-1"))
app.synth()
```

- [ ] **Step 4: Crear babyhealth_stack.py**

```python
from aws_cdk import (
    Stack,
    Duration,
    RemovalPolicy,
    aws_s3 as s3,
    aws_dynamodb as dynamodb,
    aws_lambda as lambda_,
    aws_apigateway as apigw,
    aws_iam as iam,
    CfnOutput,
)
from constructs import Construct


class BabyHealthStack(Stack):
    def __init__(self, scope: Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        # S3 Bucket for media
        media_bucket = s3.Bucket(
            self,
            "MediaBucket",
            bucket_name=f"babyhealth-media-{self.account}",
            cors=[
                s3.CorsRule(
                    allowed_methods=[s3.HttpMethods.GET, s3.HttpMethods.PUT],
                    allowed_origins=["*"],
                    allowed_headers=["*"],
                )
            ],
            removal_policy=RemovalPolicy.DESTROY,
            auto_delete_objects=True,
        )

        # DynamoDB table
        sessions_table = dynamodb.Table(
            self,
            "SessionsTable",
            table_name="babyhealth-sessions",
            partition_key=dynamodb.Attribute(
                name="session_id", type=dynamodb.AttributeType.STRING
            ),
            removal_policy=RemovalPolicy.DESTROY,
            billing_mode=dynamodb.BillingMode.PAY_PER_REQUEST,
        )

        # Lambda function
        api_lambda = lambda_.Function(
            self,
            "ApiFunction",
            runtime=lambda_.Runtime.PYTHON_3_11,
            handler="app.main.handler",
            code=lambda_.Code.from_asset(
                "../backend",
                bundling={
                    "image": lambda_.Runtime.PYTHON_3_11.bundling_image,
                    "command": [
                        "bash",
                        "-c",
                        "pip install -r requirements.txt -t /asset-output && cp -r . /asset-output",
                    ],
                },
            ),
            timeout=Duration.seconds(60),
            memory_size=512,
            environment={
                "BUCKET_NAME": media_bucket.bucket_name,
                "TABLE_NAME": sessions_table.table_name,
                "BEDROCK_MODEL_ID": "us.anthropic.claude-sonnet-4-5-20250929-v1:0",
            },
        )

        # Permissions
        media_bucket.grant_read_write(api_lambda)
        sessions_table.grant_read_write_data(api_lambda)

        api_lambda.add_to_role_policy(
            iam.PolicyStatement(
                actions=["bedrock:InvokeModel"],
                resources=["*"],
            )
        )

        # API Gateway
        api = apigw.RestApi(
            self,
            "BabyHealthApi",
            rest_api_name="BabyHealth API",
            default_cors_preflight_options=apigw.CorsOptions(
                allow_origins=apigw.Cors.ALL_ORIGINS,
                allow_methods=apigw.Cors.ALL_METHODS,
            ),
        )

        integration = apigw.LambdaIntegration(api_lambda)

        # Routes
        api.root.add_method("GET", integration)  # Health check

        analyze = api.root.add_resource("analyze")
        analyze.add_method("POST", integration)

        upload = api.root.add_resource("upload-url")
        upload.add_method("GET", integration)

        # Outputs
        CfnOutput(self, "ApiUrl", value=api.url)
        CfnOutput(self, "BucketName", value=media_bucket.bucket_name)
```

- [ ] **Step 5: Instalar dependencias y verificar**

```bash
cd infra
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cdk synth
```

Expected: Genera `cdk.out/` sin errores

- [ ] **Step 6: Deploy**

```bash
cdk bootstrap  # Solo la primera vez
cdk deploy --require-approval never
```

Expected: Stack desplegado, outputs muestran API URL y bucket name

- [ ] **Step 7: Guardar outputs**

```bash
# Guardar la API URL para usar después
export API_URL=$(aws cloudformation describe-stacks \
  --stack-name BabyHealthStack \
  --query 'Stacks[0].Outputs[?OutputKey==`ApiUrl`].OutputValue' \
  --output text)
echo $API_URL
```

- [ ] **Step 8: Commit**

```bash
git add infra/
git commit -m "feat: add CDK infrastructure (S3, DynamoDB, Lambda, API Gateway)"
```

---

## Día 2: Backend - Pipeline de Imagen

### Task 2.1: Setup backend FastAPI

**Files:**
- Create: `backend/requirements.txt`
- Create: `backend/app/__init__.py`
- Create: `backend/app/config.py`
- Create: `backend/app/main.py`

- [ ] **Step 1: Crear requirements.txt**

```txt
fastapi==0.111.0
mangum==0.17.0
boto3==1.34.0
pydantic==2.7.0
python-multipart==0.0.9
uvicorn==0.30.0
```

- [ ] **Step 2: Crear config.py**

```python
import os


class Settings:
    BUCKET_NAME: str = os.environ.get("BUCKET_NAME", "babyhealth-media-local")
    TABLE_NAME: str = os.environ.get("TABLE_NAME", "babyhealth-sessions")
    BEDROCK_MODEL_ID: str = os.environ.get(
        "BEDROCK_MODEL_ID", "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
    )
    AWS_REGION: str = os.environ.get("AWS_REGION", "us-east-1")


settings = Settings()
```

- [ ] **Step 3: Crear __init__.py vacíos**

```bash
touch backend/app/__init__.py
touch backend/app/routes/__init__.py
touch backend/app/services/__init__.py
touch backend/app/models/__init__.py
```

- [ ] **Step 4: Crear main.py**

```python
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from mangum import Mangum

from app.routes import health, analyze

app = FastAPI(title="BabyHealth API", version="0.1.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(analyze.router)

# Lambda handler
handler = Mangum(app)
```

- [ ] **Step 5: Verificar localmente**

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

Expected: Server running en http://localhost:8000

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat: add FastAPI backend skeleton with mangum"
```

---

### Task 2.2: Implementar servicios S3 y health check

**Files:**
- Create: `backend/app/services/s3.py`
- Create: `backend/app/routes/health.py`

- [ ] **Step 1: Crear s3.py**

```python
import uuid
import boto3
from botocore.config import Config

from app.config import settings

s3_client = boto3.client(
    "s3",
    region_name=settings.AWS_REGION,
    config=Config(signature_version="s3v4"),
)


def generate_upload_url(session_id: str, file_type: str = "image") -> dict:
    """Generate pre-signed URL for upload."""
    extension = "jpg" if file_type == "image" else "wav"
    key = f"sessions/{session_id}/{file_type}.{extension}"

    url = s3_client.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": settings.BUCKET_NAME,
            "Key": key,
            "ContentType": f"{'image/jpeg' if file_type == 'image' else 'audio/wav'}",
        },
        ExpiresIn=900,  # 15 minutes
    )

    return {"upload_url": url, "key": key, "session_id": session_id}


def get_object_bytes(key: str) -> bytes:
    """Download object from S3."""
    response = s3_client.get_object(Bucket=settings.BUCKET_NAME, Key=key)
    return response["Body"].read()


def create_session_id() -> str:
    """Generate unique session ID."""
    return str(uuid.uuid4())
```

- [ ] **Step 2: Crear health.py**

```python
from fastapi import APIRouter

router = APIRouter()


@router.get("/")
def health_check():
    return {"status": "healthy", "service": "babyhealth-api"}


@router.get("/upload-url")
def get_upload_url(file_type: str = "image"):
    from app.services.s3 import generate_upload_url, create_session_id

    session_id = create_session_id()
    return generate_upload_url(session_id, file_type)
```

- [ ] **Step 3: Probar endpoint de upload URL**

```bash
curl http://localhost:8000/upload-url?file_type=image
```

Expected: JSON con `upload_url`, `key`, `session_id`

- [ ] **Step 4: Commit**

```bash
git add backend/
git commit -m "feat: add S3 service and health/upload-url endpoints"
```

---

### Task 2.3: Implementar servicio Bedrock Vision

**Files:**
- Create: `backend/app/services/bedrock.py`
- Create: `backend/app/models/schemas.py`

- [ ] **Step 1: Crear schemas.py**

```python
from pydantic import BaseModel
from typing import List, Optional
from enum import Enum


class EstadoGeneral(str, Enum):
    NORMAL = "normal"
    REQUIERE_ATENCION = "requiere_atencion"
    URGENTE = "urgente"


class AnalysisResult(BaseModel):
    estado_general: EstadoGeneral
    observaciones: List[str]
    recomendaciones: List[str]
    disclaimer: str = "Esta información es orientativa. Consulte a su pediatra para diagnóstico profesional."


class AnalyzeRequest(BaseModel):
    session_id: str
    image_key: str
    audio_key: Optional[str] = None


class AnalyzeResponse(BaseModel):
    session_id: str
    result: AnalysisResult
    timestamp: str
```

- [ ] **Step 2: Crear bedrock.py**

```python
import json
import base64
import boto3
from datetime import datetime

from app.config import settings
from app.models.schemas import AnalysisResult, EstadoGeneral

bedrock_runtime = boto3.client(
    "bedrock-runtime",
    region_name=settings.AWS_REGION,
)

ANALYSIS_PROMPT = """Eres un asistente de orientación para padres primerizos. Analiza esta imagen de un bebé.

Evalúa cuidadosamente:
1. Coloración de piel - busca tonos amarillentos que podrían sugerir ictericia
2. Expresión facial - signos de malestar, llanto, o tranquilidad
3. Estado general visible - postura, ojos, respiración aparente

IMPORTANTE:
- Sé conservador en tus evaluaciones
- Ante cualquier duda, recomienda consultar al pediatra
- No hagas diagnósticos, solo observaciones

Responde ÚNICAMENTE con un JSON válido (sin markdown, sin texto adicional):
{
  "estado_general": "normal" | "requiere_atencion" | "urgente",
  "observaciones": ["observación 1", "observación 2"],
  "recomendaciones": ["recomendación 1", "recomendación 2"]
}"""


def analyze_image(image_bytes: bytes) -> AnalysisResult:
    """Analyze baby image using Bedrock Vision."""

    image_base64 = base64.b64encode(image_bytes).decode("utf-8")

    request_body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 1024,
        "messages": [
            {
                "role": "user",
                "content": [
                    {
                        "type": "image",
                        "source": {
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": image_base64,
                        },
                    },
                    {
                        "type": "text",
                        "text": ANALYSIS_PROMPT,
                    },
                ],
            }
        ],
    }

    response = bedrock_runtime.invoke_model(
        modelId=settings.BEDROCK_MODEL_ID,
        contentType="application/json",
        accept="application/json",
        body=json.dumps(request_body),
    )

    response_body = json.loads(response["body"].read())
    content = response_body["content"][0]["text"]

    # Parse JSON response
    try:
        parsed = json.loads(content)
        return AnalysisResult(
            estado_general=EstadoGeneral(parsed["estado_general"]),
            observaciones=parsed["observaciones"],
            recomendaciones=parsed["recomendaciones"],
        )
    except (json.JSONDecodeError, KeyError, ValueError) as e:
        # Fallback safe response
        return AnalysisResult(
            estado_general=EstadoGeneral.REQUIERE_ATENCION,
            observaciones=["No fue posible analizar la imagen correctamente"],
            recomendaciones=["Por favor, tome otra foto con mejor iluminación", "Consulte a su pediatra"],
        )
```

- [ ] **Step 3: Commit**

```bash
git add backend/
git commit -m "feat: add Bedrock Vision service with analysis prompt"
```

---

### Task 2.4: Implementar endpoint /analyze

**Files:**
- Create: `backend/app/routes/analyze.py`
- Create: `backend/app/services/dynamodb.py`

- [ ] **Step 1: Crear dynamodb.py**

```python
import boto3
from datetime import datetime

from app.config import settings
from app.models.schemas import AnalysisResult

dynamodb = boto3.resource("dynamodb", region_name=settings.AWS_REGION)
table = dynamodb.Table(settings.TABLE_NAME)


def save_result(session_id: str, result: AnalysisResult) -> dict:
    """Save analysis result to DynamoDB."""
    timestamp = datetime.utcnow().isoformat()

    item = {
        "session_id": session_id,
        "timestamp": timestamp,
        "estado_general": result.estado_general.value,
        "observaciones": result.observaciones,
        "recomendaciones": result.recomendaciones,
        "disclaimer": result.disclaimer,
    }

    table.put_item(Item=item)

    return {"session_id": session_id, "timestamp": timestamp}


def get_result(session_id: str) -> dict | None:
    """Get analysis result from DynamoDB."""
    response = table.get_item(Key={"session_id": session_id})
    return response.get("Item")
```

- [ ] **Step 2: Crear analyze.py**

```python
from fastapi import APIRouter, HTTPException
from datetime import datetime

from app.models.schemas import AnalyzeRequest, AnalyzeResponse, AnalysisResult
from app.services.s3 import get_object_bytes
from app.services.bedrock import analyze_image
from app.services.dynamodb import save_result

router = APIRouter()


@router.post("/analyze", response_model=AnalyzeResponse)
def analyze_baby(request: AnalyzeRequest):
    """Analyze baby image and return health observations."""

    try:
        # Get image from S3
        image_bytes = get_object_bytes(request.image_key)
    except Exception as e:
        raise HTTPException(status_code=404, detail=f"Image not found: {request.image_key}")

    try:
        # Analyze with Bedrock Vision
        result = analyze_image(image_bytes)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

    # Save to DynamoDB
    saved = save_result(request.session_id, result)

    return AnalyzeResponse(
        session_id=request.session_id,
        result=result,
        timestamp=saved["timestamp"],
    )
```

- [ ] **Step 3: Verificar imports en routes/__init__.py**

```python
from app.routes import health, analyze
```

- [ ] **Step 4: Re-deploy Lambda**

```bash
cd infra
cdk deploy --require-approval never
```

- [ ] **Step 5: Test endpoint (si Bedrock está aprobado)**

```bash
# Primero subir una imagen de prueba
curl -X PUT "$UPLOAD_URL" \
  -H "Content-Type: image/jpeg" \
  --data-binary @test_image.jpg

# Luego analizar
curl -X POST "$API_URL/analyze" \
  -H "Content-Type: application/json" \
  -d '{"session_id": "test-123", "image_key": "sessions/test-123/image.jpg"}'
```

- [ ] **Step 6: Commit**

```bash
git add backend/
git commit -m "feat: add /analyze endpoint with DynamoDB persistence"
```

---

## Día 3: Flutter App - UI Básica

### Task 3.1: Setup proyecto Flutter

**Files:**
- Create: `flutter_app/pubspec.yaml`
- Create: `flutter_app/lib/main.dart`
- Create: `flutter_app/lib/config/constants.dart`

- [ ] **Step 1: Crear proyecto Flutter**

```bash
cd flutter_app
flutter create . --org com.babyhealth
```

- [ ] **Step 2: Actualizar pubspec.yaml dependencies**

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.5+9
  http: ^1.2.1
  provider: ^6.1.2
  path_provider: ^2.1.3
  permission_handler: ^11.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

- [ ] **Step 3: Crear constants.dart**

```dart
class AppConstants {
  // Reemplazar con tu API URL del CDK output
  static const String apiUrl = 'https://YOUR_API_ID.execute-api.us-east-1.amazonaws.com/prod';

  static const Duration requestTimeout = Duration(seconds: 30);
}
```

- [ ] **Step 4: Crear main.dart básico**

```dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BabyHealthApp());
}

class BabyHealthApp extends StatelessWidget {
  const BabyHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BabyHealth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B9DFC),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
```

- [ ] **Step 5: Verificar que compila**

```bash
flutter pub get
flutter analyze
```

Expected: No errors

- [ ] **Step 6: Commit**

```bash
git add flutter_app/
git commit -m "feat: initialize Flutter project with dependencies"
```

---

### Task 3.2: Crear pantallas principales

**Files:**
- Create: `flutter_app/lib/screens/home_screen.dart`
- Create: `flutter_app/lib/screens/camera_screen.dart`
- Create: `flutter_app/lib/screens/result_screen.dart`
- Create: `flutter_app/lib/widgets/disclaimer_widget.dart`

- [ ] **Step 1: Crear disclaimer_widget.dart**

```dart
import 'package:flutter/material.dart';

class DisclaimerWidget extends StatelessWidget {
  final String text;

  const DisclaimerWidget({
    super.key,
    this.text = 'Esta aplicación es solo orientativa. Consulte siempre a su pediatra.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Crear home_screen.dart**

```dart
import 'package:flutter/material.dart';
import '../widgets/disclaimer_widget.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.child_care,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'BabyHealth',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Asistente de cuidado neonatal',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              const DisclaimerWidget(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CameraScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Iniciar Análisis'),
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Crear camera_screen.dart (placeholder)**

```dart
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) {
      setState(() => _isInitialized = true);
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (_controller == null || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Capturar imagen'),
      ),
      body: _isInitialized
          ? Column(
              children: [
                Expanded(
                  child: CameraPreview(_controller!),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: FloatingActionButton(
                      onPressed: _isCapturing ? null : _captureAndAnalyze,
                      child: _isCapturing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.camera, size: 32),
                    ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
```

- [ ] **Step 4: Crear result_screen.dart (placeholder)**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/disclaimer_widget.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isAnalyzing = true;
  Map<String, dynamic>? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    // TODO: Implement API call in Day 4
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isAnalyzing = false;
      // Mock result for now
      _result = {
        'estado_general': 'normal',
        'observaciones': [
          'Coloración de piel dentro de parámetros normales',
          'Expresión facial tranquila',
        ],
        'recomendaciones': [
          'Continúe con los cuidados habituales',
          'Mantenga las visitas regulares al pediatra',
        ],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
      ),
      body: _isAnalyzing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analizando imagen...'),
                ],
              ),
            )
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(widget.imagePath),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildStatusCard(),
                      const SizedBox(height: 16),
                      _buildSection('Observaciones', _result!['observaciones']),
                      const SizedBox(height: 16),
                      _buildSection('Recomendaciones', _result!['recomendaciones']),
                      const SizedBox(height: 16),
                      const DisclaimerWidget(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.popUntil(
                            context,
                            (route) => route.isFirst,
                          ),
                          child: const Text('Nuevo Análisis'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusCard() {
    final estado = _result!['estado_general'] as String;
    final color = estado == 'normal'
        ? Colors.green
        : estado == 'requiere_atencion'
            ? Colors.orange
            : Colors.red;

    return Card(
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              estado == 'normal' ? Icons.check_circle : Icons.warning,
              color: color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              estado == 'normal'
                  ? 'Estado Normal'
                  : estado == 'requiere_atencion'
                      ? 'Requiere Atención'
                      : 'Atención Urgente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(child: Text(item.toString())),
            ],
          ),
        )),
      ],
    );
  }
}
```

- [ ] **Step 5: Configurar permisos iOS (Info.plist)**

Agregar a `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>BabyHealth necesita acceso a la cámara para analizar imágenes del bebé</string>
<key>NSMicrophoneUsageDescription</key>
<string>BabyHealth puede usar el micrófono para análisis de audio</string>
```

- [ ] **Step 6: Configurar permisos Android**

Agregar a `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

- [ ] **Step 7: Probar en simulador**

```bash
flutter run
```

Expected: App corre, muestra home screen, puede abrir cámara

- [ ] **Step 8: Commit**

```bash
git add flutter_app/
git commit -m "feat: add Flutter UI screens (home, camera, result)"
```

---

## Día 4: Integración End-to-End

### Task 4.1: Implementar servicios de API en Flutter

**Files:**
- Create: `flutter_app/lib/services/api_service.dart`
- Create: `flutter_app/lib/services/s3_service.dart`
- Create: `flutter_app/lib/models/analysis_result.dart`

- [ ] **Step 1: Crear analysis_result.dart**

```dart
class AnalysisResult {
  final String sessionId;
  final String estadoGeneral;
  final List<String> observaciones;
  final List<String> recomendaciones;
  final String disclaimer;
  final String timestamp;

  AnalysisResult({
    required this.sessionId,
    required this.estadoGeneral,
    required this.observaciones,
    required this.recomendaciones,
    required this.disclaimer,
    required this.timestamp,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final result = json['result'] as Map<String, dynamic>;
    return AnalysisResult(
      sessionId: json['session_id'] as String,
      estadoGeneral: result['estado_general'] as String,
      observaciones: List<String>.from(result['observaciones']),
      recomendaciones: List<String>.from(result['recomendaciones']),
      disclaimer: result['disclaimer'] as String,
      timestamp: json['timestamp'] as String,
    );
  }
}
```

- [ ] **Step 2: Crear api_service.dart**

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/analysis_result.dart';

class ApiService {
  static Future<Map<String, String>> getUploadUrl({String fileType = 'image'}) async {
    final response = await http.get(
      Uri.parse('${AppConstants.apiUrl}/upload-url?file_type=$fileType'),
    ).timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'upload_url': data['upload_url'] as String,
        'key': data['key'] as String,
        'session_id': data['session_id'] as String,
      };
    } else {
      throw Exception('Failed to get upload URL: ${response.statusCode}');
    }
  }

  static Future<AnalysisResult> analyzeImage({
    required String sessionId,
    required String imageKey,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.apiUrl}/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'session_id': sessionId,
        'image_key': imageKey,
      }),
    ).timeout(AppConstants.requestTimeout);

    if (response.statusCode == 200) {
      return AnalysisResult.fromJson(json.decode(response.body));
    } else {
      throw Exception('Analysis failed: ${response.statusCode}');
    }
  }
}
```

- [ ] **Step 3: Crear s3_service.dart**

```dart
import 'dart:io';
import 'package:http/http.dart' as http;

class S3Service {
  static Future<void> uploadFile({
    required String uploadUrl,
    required String filePath,
    required String contentType,
  }) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();

    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: bytes,
    );

    if (response.statusCode != 200) {
      throw Exception('Upload failed: ${response.statusCode}');
    }
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add flutter_app/
git commit -m "feat: add API and S3 services for Flutter"
```

---

### Task 4.2: Conectar result_screen con backend real

**Files:**
- Modify: `flutter_app/lib/screens/result_screen.dart`

- [ ] **Step 1: Actualizar result_screen.dart con llamadas reales**

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../widgets/disclaimer_widget.dart';
import '../services/api_service.dart';
import '../services/s3_service.dart';
import '../models/analysis_result.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isAnalyzing = true;
  AnalysisResult? _result;
  String? _error;
  String _statusMessage = 'Preparando análisis...';

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    try {
      // Step 1: Get upload URL
      setState(() => _statusMessage = 'Obteniendo URL de carga...');
      final uploadData = await ApiService.getUploadUrl();

      // Step 2: Upload image to S3
      setState(() => _statusMessage = 'Subiendo imagen...');
      await S3Service.uploadFile(
        uploadUrl: uploadData['upload_url']!,
        filePath: widget.imagePath,
        contentType: 'image/jpeg',
      );

      // Step 3: Call analyze endpoint
      setState(() => _statusMessage = 'Analizando con IA...');
      final result = await ApiService.analyzeImage(
        sessionId: uploadData['session_id']!,
        imageKey: uploadData['key']!,
      );

      setState(() {
        _isAnalyzing = false;
        _result = result;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado'),
      ),
      body: _isAnalyzing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_statusMessage),
                ],
              ),
            )
          : _error != null
              ? _buildErrorView()
              : _buildResultView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Error al analizar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(widget.imagePath),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildSection('Observaciones', _result!.observaciones),
          const SizedBox(height: 16),
          _buildSection('Recomendaciones', _result!.recomendaciones),
          const SizedBox(height: 16),
          DisclaimerWidget(text: _result!.disclaimer),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.popUntil(
                context,
                (route) => route.isFirst,
              ),
              child: const Text('Nuevo Análisis'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final estado = _result!.estadoGeneral;
    final color = estado == 'normal'
        ? Colors.green
        : estado == 'requiere_atencion'
            ? Colors.orange
            : Colors.red;

    return Card(
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              estado == 'normal' ? Icons.check_circle : Icons.warning,
              color: color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              estado == 'normal'
                  ? 'Estado Normal'
                  : estado == 'requiere_atencion'
                      ? 'Requiere Atención'
                      : 'Atención Urgente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontSize: 16)),
              Expanded(child: Text(item)),
            ],
          ),
        )),
      ],
    );
  }
}
```

- [ ] **Step 2: Actualizar constants.dart con API URL real**

Obtener la URL del CDK output y actualizar el archivo.

- [ ] **Step 3: Test end-to-end**

```bash
flutter run
```

1. Abrir app
2. Tomar foto
3. Verificar que sube y analiza correctamente

- [ ] **Step 4: Commit**

```bash
git add flutter_app/
git commit -m "feat: integrate Flutter app with backend API"
```

---

## Día 5: Polish + Demo

### Task 5.1: Mejorar UI y UX

- [ ] Agregar loading states más informativos
- [ ] Agregar animaciones sutiles
- [ ] Verificar colores y tipografía consistentes
- [ ] Probar en múltiples tamaños de pantalla

### Task 5.2: Grabar video de respaldo

- [ ] Grabar flujo completo funcionando (screen recording)
- [ ] Guardar en múltiples lugares (local + cloud)
- [ ] Verificar que el video tiene buena calidad

### Task 5.3: Preparar diagrama de arquitectura

- [ ] Crear diagrama con iconos oficiales de AWS
- [ ] Incluir: Flutter → API Gateway → Lambda → Bedrock/S3/DynamoDB
- [ ] Exportar como imagen de alta resolución

---

## Día 6: Buffer + Testing

### Task 6.1: Testing y edge cases

- [ ] Probar con diferentes tipos de imágenes
- [ ] Probar sin conexión a internet
- [ ] Probar con timeout largo de Bedrock
- [ ] Verificar manejo de errores en UI

### Task 6.2: Práctica de pitch

- [ ] Ensayar pitch 3+ veces con cronómetro (4 min)
- [ ] Practicar transiciones entre secciones
- [ ] Preparar respuestas a preguntas frecuentes

---

## Día 7: Preparación Final

### Task 7.1: Checklist pre-presentación

- [ ] Lambda calentada (hacer request 5 min antes)
- [ ] Video de respaldo verificado y accesible
- [ ] Hotspot móvil cargado y funcionando
- [ ] Diagrama de arquitectura listo
- [ ] App instalada en dispositivo de demo

### Task 7.2: Entrega

- [ ] Subir código a repositorio (si requerido)
- [ ] Preparar enlace de demo (si requerido)
- [ ] Verificar toda la documentación

---

## Quick Reference

### Comandos frecuentes

```bash
# Backend local
cd backend && uvicorn app.main:app --reload

# Deploy infra
cd infra && cdk deploy

# Flutter run
cd flutter_app && flutter run

# Ver logs Lambda
aws logs tail /aws/lambda/BabyHealthStack-ApiFunction --follow
```

### URLs importantes

- API Gateway: (output de CDK)
- Bedrock Console: https://us-east-1.console.aws.amazon.com/bedrock
- CloudWatch Logs: https://us-east-1.console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups
