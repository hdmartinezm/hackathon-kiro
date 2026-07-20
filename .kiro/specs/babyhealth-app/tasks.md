# Implementation Plan: BabyHealth App

## Overview

Implementación de BabyHealth, una aplicación móvil Flutter con backend serverless en AWS que combina análisis visual (cloud con Bedrock/Claude) y análisis de audio (on-device con CoreML/TFLite) para orientar a padres primerizos sobre el estado de salud de su bebé. El plan cubre backend API (FastAPI + Lambda), servicios AWS (S3, DynamoDB, Bedrock), app Flutter (iOS/Android), infraestructura CDK y tests.

## Tasks

- [ ] 1. Configuración del Backend y Estructura Base
  - [ ] 1.1 Actualizar requirements.txt con dependencias: boto3, mangum, pydantic>=2.0, python-dateutil
    - _Requirements: 1.1, 3.1, 4.1_
  - [ ] 1.2 Crear backend/app/config.py con variables de entorno (S3_BUCKET, BEDROCK_MODEL_ID, DYNAMODB_TABLE, AWS_REGION)
    - _Requirements: 3.1, 12.5_
  - [ ] 1.3 Crear backend/app/models/requests.py con UploadUrlRequest, AnalyzeRequest, AnalyzeAudioRequest usando Pydantic
    - _Requirements: 1.1, 1.2, 14.1_
  - [ ] 1.4 Crear backend/app/models/responses.py con UploadUrlResponse, AnalyzeResponse, AudioAnalysisResponse usando Pydantic
    - _Requirements: 1.4, 3.2, 14.2_
  - [ ] 1.5 Crear backend/lambda_handler.py con Mangum handler para despliegue en Lambda
    - _Requirements: 4.2_
  - [ ] 1.6 Actualizar backend/app/main.py para registrar routers y configurar CORS con orígenes permitidos
    - _Requirements: 15.1_

- [ ] 2. Servicio S3 y Endpoint de Upload
  - [ ] 2.1 Crear backend/app/services/s3_service.py con función generate_presigned_url que genera URLs con expiración de 300s
    - _Requirements: 1.1, 1.4_
  - [ ] 2.2 Crear backend/app/routers/upload.py con endpoint POST /upload-url que valida file_type (image/jpeg, image/png) y retorna URL pre-firmada
    - _Requirements: 1.2, 1.3, 1.4_
  - [ ] 2.3 Implementar validación que retorna error 400 si file_type no es image/jpeg ni image/png
    - _Requirements: 1.3_
  - [ ] 2.4 Generar s3_key con formato sessions/{session_id}/{uuid}.{extension}
    - _Requirements: 1.5_

- [ ] 3. Servicio Bedrock y Análisis Visual
  - [ ] 3.1 Crear backend/app/services/bedrock_service.py con función analyze_image que invoca Claude Sonnet 4.5
    - _Requirements: 3.1, 3.2_
  - [ ] 3.2 Implementar el prompt del sistema para análisis visual (coloración, expresión facial, estado general)
    - _Requirements: 3.1, 3.5_
  - [ ] 3.3 Implementar parsing de respuesta JSON de Bedrock con validación de campos obligatorios
    - _Requirements: 3.2, 3.3, 3.4_
  - [ ] 3.4 Implementar detección de calidad de imagen (retornar error amigable si imagen no es adecuada)
    - _Requirements: 2.1, 2.2, 2.3_
  - [ ] 3.5 Crear backend/app/utils/retry.py con lógica de reintento (3 intentos, backoff exponencial 1s, 2s, timeout 10s)
    - _Requirements: 12.1, 12.2_
  - [ ] 3.6 Crear backend/app/routers/analyze.py con endpoint POST /analyze que orquesta: descargar imagen S3, analizar con Bedrock, almacenar resultado
    - _Requirements: 3.1, 3.7, 16.1_

- [ ] 4. Servicio DynamoDB y Almacenamiento
  - [ ] 4.1 Crear backend/app/services/dynamo_service.py con funciones save_result y get_results_by_session
    - _Requirements: 16.1, 16.2, 16.3_
  - [ ] 4.2 Implementar save_result que almacena session_id, timestamp, analysis_type y result como Map
    - _Requirements: 16.2_
  - [ ] 4.3 Implementar get_results_by_session que retorna resultados ordenados por timestamp descendente
    - _Requirements: 16.3_
  - [ ] 4.4 Agregar logging a CloudWatch en todas las operaciones de DynamoDB
    - _Requirements: 12.5_

- [ ] 5. Checkpoint - Verificar backend core
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Endpoint de Análisis de Audio (Android)
  - [ ] 6.1 Crear backend/app/routers/audio.py con endpoint POST /analyze-audio
    - _Requirements: 14.1_
  - [ ] 6.2 Implementar descarga de espectrograma desde S3 usando s3_key
    - _Requirements: 14.1_
  - [ ] 6.3 Implementar clasificación de llanto con Bedrock (prompt específico para espectrograma)
    - _Requirements: 14.2, 6.4_
  - [ ] 6.4 Implementar validación de s3_key existente (404 si no existe) y formato válido (400 si no es espectrograma)
    - _Requirements: 14.3, 14.4_
  - [ ] 6.5 Retornar response con category, label, confidence y recommendation
    - _Requirements: 14.2_

- [ ] 7. Endpoint Health y Manejo de Errores Global
  - [ ] 7.1 Crear backend/app/routers/health.py con endpoint GET /health que retorna status y version
    - _Requirements: 13.1, 13.2_
  - [ ] 7.2 Implementar middleware de manejo de errores global que captura excepciones y retorna mensajes amigables
    - _Requirements: 12.2, 12.5_
  - [ ] 7.3 Configurar logging estructurado a CloudWatch con contexto (session_id, endpoint, duración)
    - _Requirements: 12.5_
  - [ ] 7.4 Implementar validación de entrada para todos los endpoints con mensajes de error descriptivos
    - _Requirements: 15.4_

- [ ] 8. Flutter App - Estructura Base y Navegación
  - [ ] 8.1 Crear flutter_app/lib/config/app_config.dart con URL base de API y constantes
    - _Requirements: 1.1_
  - [ ] 8.2 Crear flutter_app/lib/models/analysis_result.dart con modelo de resultado visual (fromJson/toJson)
    - _Requirements: 3.2, 10.2_
  - [ ] 8.3 Crear flutter_app/lib/models/audio_result.dart con modelo de resultado de audio (fromJson/toJson)
    - _Requirements: 5.4, 6.5_
  - [ ] 8.4 Crear flutter_app/lib/screens/splash_screen.dart con disclaimer médico completo y animación
    - _Requirements: 9.1, 9.5_
  - [ ] 8.5 Crear flutter_app/lib/screens/home_screen.dart con opciones de análisis (foto/audio) y footer con disclaimer
    - _Requirements: 9.2_
  - [ ] 8.6 Configurar navegación entre pantallas (splash → home → cámara/audio → resultado)
    - _Requirements: 10.3, 10.4_

- [ ] 9. Flutter App - Módulo de Cámara y Upload
  - [ ] 9.1 Crear flutter_app/lib/services/camera_service.dart con captura de imagen y validación local básica
    - _Requirements: 1.1, 2.4_
  - [ ] 9.2 Crear flutter_app/lib/services/api_service.dart con métodos para upload-url, analyze, y analyze-audio
    - _Requirements: 1.1, 3.1, 14.1_
  - [ ] 9.3 Crear flutter_app/lib/screens/camera_screen.dart con preview de cámara y botón de captura
    - _Requirements: 1.1_
  - [ ] 9.4 Implementar flujo completo: captura → solicitar URL pre-firmada → upload a S3 → llamar /analyze
    - _Requirements: 1.1, 1.4, 3.1_
  - [ ] 9.5 Implementar manejo de error de conexión con opción de reintento
    - _Requirements: 12.3_
  - [ ] 9.6 Implementar renovación automática de URL pre-firmada si expira
    - _Requirements: 12.4_

- [ ] 10. Checkpoint - Verificar flujo visual end-to-end
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 11. Flutter App - Módulo de Audio
  - [ ] 11.1 Crear flutter_app/lib/services/audio_service.dart con grabación de 7 segundos
    - _Requirements: 5.1, 6.1_
  - [ ] 11.2 Implementar integración con DeepInfant CoreML para iOS (clasificación on-device)
    - _Requirements: 5.2, 5.3, 5.5, 8.1_
  - [ ] 11.3 Implementar integración con YAMNet TFLite para Android (detección de llanto)
    - _Requirements: 6.2, 6.3_
  - [ ] 11.4 Crear flutter_app/lib/screens/audio_screen.dart con indicador de grabación y countdown de 7s
    - _Requirements: 5.1, 6.1_
  - [ ] 11.5 Implementar lógica de umbral de confianza: si confidence < 0.5 → categoría "desconocido"
    - _Requirements: 7.1, 7.2, 7.3_
  - [ ] 11.6 Implementar eliminación del buffer de audio inmediatamente después de clasificación (iOS)
    - _Requirements: 8.2, 8.3_
  - [ ] 11.7 Implementar flujo Android: YAMNet detecta → si llanto → upload espectrograma → /analyze-audio
    - _Requirements: 6.4, 6.5_

- [ ] 12. Flutter App - Pantallas de Resultado
  - [ ] 12.1 Crear flutter_app/lib/widgets/traffic_light_widget.dart con indicador semáforo (verde/amarillo/rojo)
    - _Requirements: 10.1_
  - [ ] 12.2 Crear flutter_app/lib/widgets/disclaimer_widget.dart reutilizable con texto completo
    - _Requirements: 9.3, 9.5_
  - [ ] 12.3 Crear flutter_app/lib/widgets/confidence_bar.dart con barra de porcentaje de confianza
    - _Requirements: 10.2, 11.3_
  - [ ] 12.4 Crear flutter_app/lib/screens/result_screen.dart con semáforo, observaciones, recomendaciones, disclaimer, botones
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_
  - [ ] 12.5 Crear flutter_app/lib/screens/audio_result_screen.dart con categoría, confianza, recomendación, disclaimer
    - _Requirements: 11.1, 11.2, 11.3, 11.4_
  - [ ] 12.6 Implementar resaltado visual de recomendaciones cuando estado es "urgente"
    - _Requirements: 10.5_
  - [ ] 12.7 Implementar botones "Nuevo Análisis" y "Contactar Pediatra"
    - _Requirements: 10.3, 10.4_

- [ ] 13. Infraestructura AWS CDK
  - [ ] 13.1 Crear infra/stacks/babyhealth_stack.py con definición de S3 bucket (lifecycle 24h, bloqueo público)
    - _Requirements: 15.3, 15.5_
  - [ ] 13.2 Agregar DynamoDB table con partition key session_id y sort key timestamp
    - _Requirements: 16.2_
  - [ ] 13.3 Agregar Lambda function con handler de Mangum, runtime Python 3.11, timeout 30s
    - _Requirements: 4.1, 4.2_
  - [ ] 13.4 Agregar API Gateway con throttling configurado y CORS
    - _Requirements: 15.1, 15.2_
  - [ ] 13.5 Configurar IAM roles con permisos mínimos (S3 read/write, Bedrock invoke, DynamoDB read/write)
    - _Requirements: 15.1_
  - [ ] 13.6 Agregar CloudWatch log group con retención de 14 días
    - _Requirements: 12.5_

- [ ] 14. Checkpoint - Verificar infraestructura y despliegue
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 15. Tests del Backend
  - [ ]* 15.1 Crear backend/tests/test_health.py con tests del endpoint /health
    - _Requirements: 13.1, 13.2_
  - [ ]* 15.2 Crear backend/tests/test_upload.py con tests de generación de URL pre-firmada y validación de file_type
    - _Requirements: 1.1, 1.2, 1.3_
  - [ ]* 15.3 Crear backend/tests/test_analyze.py con tests de análisis visual (mock Bedrock y S3)
    - _Requirements: 3.1, 3.2, 3.3_
  - [ ]* 15.4 Crear backend/tests/test_audio.py con tests de análisis de audio (mock Bedrock y S3)
    - _Requirements: 14.1, 14.2, 14.3, 14.4_
  - [ ]* 15.5 Crear backend/tests/test_models.py con tests de serialización/deserialización de modelos Pydantic (round-trip)
    - **Property 7: Round-trip de modelos de datos**
    - **Validates: Requirements 3.2, 14.2**
  - [ ]* 15.6 Crear backend/tests/test_retry.py con tests de la lógica de reintentos (éxito al 2do intento, fallo total)
    - _Requirements: 12.1, 12.2_

- [ ] 16. Final checkpoint - Verificar integración completa
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Backend uses Python 3.11 with FastAPI; Flutter app uses Dart
- Audio processing is hybrid: CoreML on-device (iOS), YAMNet + Bedrock cloud (Android)
- All images are temporary (24h TTL in S3) for privacy compliance

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4", "1.5", "1.6"] },
    { "id": 1, "tasks": ["2.1", "2.2", "2.3", "2.4", "4.1", "4.2", "4.3", "4.4", "7.1", "7.2", "7.3", "7.4"] },
    { "id": 2, "tasks": ["3.1", "3.2", "3.3", "3.4", "3.5", "3.6"] },
    { "id": 3, "tasks": ["6.1", "6.2", "6.3", "6.4", "6.5"] },
    { "id": 4, "tasks": ["8.1", "8.2", "8.3", "8.4", "8.5", "8.6", "13.1", "13.2", "13.3", "13.4", "13.5", "13.6"] },
    { "id": 5, "tasks": ["9.1", "9.2", "9.3", "9.4", "9.5", "9.6"] },
    { "id": 6, "tasks": ["11.1", "11.2", "11.3", "11.4", "11.5", "11.6", "11.7"] },
    { "id": 7, "tasks": ["12.1", "12.2", "12.3", "12.4", "12.5", "12.6", "12.7"] },
    { "id": 8, "tasks": ["15.1", "15.2", "15.3", "15.4", "15.5", "15.6"] }
  ]
}
```
