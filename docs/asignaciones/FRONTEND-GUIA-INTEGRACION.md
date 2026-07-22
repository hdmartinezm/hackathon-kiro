# Guía de Integración - Frontend BabyHealth

## Resumen
Esta guía describe cómo integrar la app Flutter con el backend de BabyHealth.

## URL Base del API
```
https://192.168.0.97:8000
```

## Endpoints Disponibles

### 1. Health Check
```
GET /health
Response: { "status": "ok", "version": "1.0.0" }
```

### 2. Upload URL (Video)
```
GET /upload-url?content_type=video/mp4
Response: {
  "upload_url": "https://s3.amazonaws.com/...",
  "video_key": "videos/uuid.mp4",
  "expires_at": "2024-...",
  "content_type": "video/mp4"
}
```

### 3. Análisis Multimodal (Video)
```
POST /analyze
Body: { "video_key": "videos/uuid.mp4", "session_id": "optional" }
Response: AnalysisResult (ver modelo)
```

### 4. Análisis de Imagen (Directo)
```
POST /analyze-image
Body: multipart/form-data con campo "file" (image/jpeg, image/png)
Response: AnalysisResult
```

## Flujo de Análisis Visual

1. Capturar foto con la cámara
2. Enviar como multipart a `POST /analyze-image`
3. Recibir resultado y navegar a pantalla de resultados

## Flujo de Análisis de Video

1. Seleccionar video de galería
2. `GET /upload-url?content_type=video/mp4` → obtener presigned URL
3. `PUT {upload_url}` con los bytes del video
4. `POST /analyze` con el `video_key` recibido
5. Mostrar resultado

## Flujo de Análisis de Audio

1. Grabar 7 segundos de audio
2. Enviar audio como imagen del espectrograma al backend
3. El backend genera espectrograma y clasifica

## Modelo de Respuesta: AnalysisResult

```json
{
  "status": "normal | requiere_atencion | urgente",
  "observations": "Descripción de observaciones",
  "recommendations": "Recomendaciones para los padres",
  "confidence": 0.85,
  "cry_category": "hambre | dolor | sueno | incomodidad | colico",
  "cry_label": "Etiqueta descriptiva",
  "cry_confidence": 0.78,
  "cry_recommendation": "Recomendación específica",
  "session_id": "uuid",
  "disclaimer": "Esta herramienta es solo orientativa..."
}
```

## Manejo de Errores

- **400**: Datos inválidos (tipo de archivo no soportado, archivo vacío)
- **422**: Error de validación de campos
- **500**: Error interno del servidor

Siempre mostrar diálogo de retry en errores de red.

## Notas Importantes

- NO hay autenticación (simplificado para hackathon)
- El disclaimer SIEMPRE debe mostrarse en pantalla de resultados
- Máximo 10MB para imágenes, 50MB para videos
- Tipos de video soportados: video/mp4, video/webm
- Tipos de imagen soportados: image/jpeg, image/png, image/webp
