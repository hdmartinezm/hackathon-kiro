"""Router para generación de URLs de upload presigned."""
import logging
from fastapi import APIRouter, Query, HTTPException
from pydantic import BaseModel
from app.services.s3_service import (
    generate_presigned_url_for_video,
    generate_presigned_url_for_image,
    generate_presigned_url_for_pdf,
    generate_presigned_download_url,
)
from app.models.responses import UploadUrlResponse


class PdfUploadResponse(BaseModel):
    upload_url: str
    pdf_key: str
    expires_at: str
    content_type: str


class PdfDownloadResponse(BaseModel):
    download_url: str
    expires_in_seconds: int

logger = logging.getLogger(__name__)
router = APIRouter(tags=["upload"])

ALLOWED_VIDEO_TYPES = ["video/mp4", "video/webm", "video/quicktime"]
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


@router.get("/upload-pdf-url", response_model=PdfUploadResponse)
def get_pdf_upload_url():
    """Genera una URL prefirmada para subir un PDF de reporte a S3."""
    try:
        result = generate_presigned_url_for_pdf()
        return PdfUploadResponse(**result)
    except Exception as e:
        logger.error(f"Error generando URL de upload para PDF: {e}")
        raise HTTPException(status_code=500, detail="Error generando URL de upload")


@router.get("/pdf-download-url", response_model=PdfDownloadResponse)
def get_pdf_download_url(pdf_key: str = Query(..., description="Key del PDF en S3")):
    """Genera una URL prefirmada para descargar un PDF de S3.

    La URL es válida por 1 hora para compartir con el pediatra.
    """
    if not pdf_key.startswith("reports/") or not pdf_key.endswith(".pdf"):
        raise HTTPException(
            status_code=400,
            detail="Key de PDF inválida",
        )

    try:
        expiration = 3600  # 1 hour
        download_url = generate_presigned_download_url(pdf_key, expiration)
        return PdfDownloadResponse(download_url=download_url, expires_in_seconds=expiration)
    except Exception as e:
        logger.error(f"Error generando URL de descarga para PDF: {e}")
        raise HTTPException(status_code=500, detail="Error generando URL de descarga")
