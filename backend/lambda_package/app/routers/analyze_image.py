"""Router para análisis directo de imágenes (upload multipart)."""
import logging
import uuid
from fastapi import APIRouter, UploadFile, File, HTTPException
from app.services.bedrock_service import analyze_image
from app.services.dynamo_service import save_result
from app.models.responses import AnalysisResult

logger = logging.getLogger(__name__)
router = APIRouter(tags=["analyze-image"])

ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/jpg", "image/webp"]
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10MB


@router.post("/analyze-image", response_model=AnalysisResult)
async def analyze_image_endpoint(file: UploadFile = File(...)):
    """Analiza una imagen subida directamente.

    Acepta multipart file upload (image), envía directamente
    a Bedrock para análisis, retorna resultado estructurado.
    """
    # Validar tipo de contenido
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Tipo de archivo no soportado: {file.content_type}. "
            f"Tipos válidos: {ALLOWED_IMAGE_TYPES}",
        )

    # Leer imagen
    image_bytes = await file.read()

    # Validar tamaño
    if len(image_bytes) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"Archivo demasiado grande. Máximo: {MAX_FILE_SIZE // (1024*1024)}MB",
        )

    if len(image_bytes) == 0:
        raise HTTPException(status_code=400, detail="Archivo vacío")

    session_id = str(uuid.uuid4())

    try:
        # Determinar media type para Bedrock
        media_type = file.content_type or "image/jpeg"

        # Analizar con Bedrock
        logger.info(f"Analizando imagen ({len(image_bytes)} bytes, tipo={media_type})")
        result = analyze_image(image_bytes, media_type=media_type)

        # Construir respuesta
        analysis_result = AnalysisResult(
            status=result.get("status", "normal"),
            observations=result.get("observations", "No se pudieron generar observaciones"),
            recommendations=result.get("recommendations", "Consulte a su pediatra"),
            confidence=result.get("confidence"),
            session_id=session_id,
        )

        # Persistir en DynamoDB
        try:
            save_result(session_id, analysis_result.model_dump(), analysis_type="visual")
        except Exception as e:
            logger.warning(f"No se pudo guardar resultado en DynamoDB: {e}")

        return analysis_result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error en análisis de imagen: {e}")
        raise HTTPException(status_code=500, detail=f"Error analizando imagen: {str(e)}")
