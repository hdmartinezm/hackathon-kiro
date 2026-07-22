"""Router para generación de URLs de upload presigned."""
import logging
from fastapi import APIRouter, Query, HTTPException
from app.services.s3_service import generate_presigned_url_for_video, generate_presigned_url_for_image
from app.models.responses import UploadUrlResponse

logger = logging.getLogger(__name__)
router = APIRouter(tags=["upload"])

ALLOWED_VIDEO_TYPES = ["video/mp4", "video/webm"]
ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png"]


@router.get("/upload-url", response_model=UploadUrlResponse)
def get_upload_url(content_type: str = Query(default="video/mp4", description="MIME type del archivo")):
    """Genera una URL prefirmada para subir video a S3."""
    if content_type not in ALLOWED_VIDEO_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Tipo de contenido no permitido. Tipos válidos: {ALLOWED_VIDEO_TYPES}",
        )

    try:
        result = generate_presigned_url_for_video(content_type=content_type)
        return UploadUrlResponse(**result)
    except Exception as e:
        logger.error(f"Error generando URL de upload: {e}")
        raise HTTPException(status_code=500, detail="Error generando URL de upload")


@router.get("/upload-image-url")
def get_image_upload_url(content_type: str = Query(default="image/jpeg")):
    """Genera una URL prefirmada para subir imagen a S3."""
    if content_type not in ALLOWED_IMAGE_TYPES:
        raise HTTPException(
            status_code=400,
            detail=f"Tipo de contenido no permitido. Tipos válidos: {ALLOWED_IMAGE_TYPES}",
        )

    try:
        result = generate_presigned_url_for_image(content_type=content_type)
        return result
    except Exception as e:
        logger.error(f"Error generando URL de upload para imagen: {e}")
        raise HTTPException(status_code=500, detail="Error generando URL de upload")
