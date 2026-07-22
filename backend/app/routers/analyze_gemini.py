"""
Router de análisis multimodal con Google Gemini para BabyHealth.

POST /analyze-gemini recibe un video_key, descarga el video de S3,
y ejecuta análisis multimodal nativo (visual + audio) usando Gemini.
"""

import logging
from uuid import uuid4

from fastapi import APIRouter, HTTPException

from app.models.requests import AnalyzeRequest
from app.models.responses import AnalysisResult
from app.services import gemini_service
from app.services.s3_service import download_object
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/analyze-gemini", response_model=AnalysisResult)
def analyze_video_with_gemini(request: AnalyzeRequest):
    """Analiza un video de bebé usando Gemini (multimodal nativo).

    A diferencia del endpoint /analyze que usa Bedrock y extrae frames/audio,
    este endpoint envía el video completo a Gemini que procesa visual y audio
    de forma nativa sin necesidad de preprocesamiento.

    Args:
        request: AnalyzeRequest con video_key (ubicación en S3) y session_id opcional.

    Returns:
        AnalysisResult con análisis visual y de audio combinado.

    Raises:
        HTTPException 404: Si el video_key no existe en S3.
        HTTPException 500: Error interno del servidor.
        HTTPException 503: Servicio de Gemini no disponible.
    """
    session_id = request.session_id or str(uuid4())

    logger.info(
        "Gemini analyze request received",
        extra={
            "session_id": session_id,
            "video_key": request.video_key,
            "model": settings.GEMINI_MODEL_ID,
        },
    )

    # Verificar que Gemini está configurado
    if not settings.GEMINI_API_KEY:
        logger.error("GEMINI_API_KEY not configured")
        raise HTTPException(
            status_code=503,
            detail="Servicio de Gemini no configurado. Configure GEMINI_API_KEY.",
        )

    # 1. Descargar video de S3
    try:
        video_bytes, content_type = download_object(request.video_key)
    except FileNotFoundError:
        raise HTTPException(
            status_code=404,
            detail=f"video_key no encontrado: {request.video_key}",
        )
    except Exception as e:
        logger.error(f"S3 download failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error interno del servidor")

    logger.info(
        "Video downloaded from S3",
        extra={
            "session_id": session_id,
            "video_size_bytes": len(video_bytes),
            "content_type": content_type,
        },
    )

    # 2. Analizar con Gemini (multimodal nativo)
    try:
        result = gemini_service.analyze_video(video_bytes, content_type, session_id)
    except ValueError as e:
        logger.error(f"Gemini analysis error: {e}", exc_info=True)
        raise HTTPException(
            status_code=503,
            detail=f"Error en análisis de Gemini: {str(e)}",
        )
    except Exception as e:
        logger.error(f"Gemini service failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=503,
            detail="Servicio de análisis Gemini no disponible",
        )

    # 3. Construir respuesta
    response = AnalysisResult(
        status=result.get("status", "requiere_atencion"),
        observations=result.get("observations", ""),
        recommendations=result.get("recommendations", ""),
        confidence=result.get("confidence"),
        cry_category=result.get("cry_category"),
        cry_label=result.get("cry_label"),
        cry_confidence=result.get("cry_confidence"),
        cry_recommendation=result.get("cry_recommendation"),
        error=result.get("error"),
        session_id=session_id,
    )

    logger.info(
        "Gemini analyze completed",
        extra={
            "session_id": session_id,
            "status": response.status,
            "confidence": response.confidence,
            "cry_category": response.cry_category,
        },
    )

    return response


@router.post("/analyze-audio-gemini")
def analyze_audio_with_gemini(request: AnalyzeRequest):
    """Analiza audio de llanto de bebé usando Gemini.

    Similar a /analyze-audio pero usando Gemini en lugar de Bedrock.
    Útil para comparar resultados entre modelos.

    Args:
        request: AnalyzeRequest con video_key (o audio_key) y session_id opcional.

    Returns:
        Dict con category, label, confidence, recommendation, observations.
    """
    session_id = request.session_id or str(uuid4())

    logger.info(
        "Gemini audio analyze request received",
        extra={
            "session_id": session_id,
            "s3_key": request.video_key,
        },
    )

    if not settings.GEMINI_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="Servicio de Gemini no configurado.",
        )

    # Descargar audio de S3
    try:
        audio_bytes, content_type = download_object(request.video_key)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Audio no encontrado")
    except Exception as e:
        logger.error(f"S3 download failed: {e}", exc_info=True)
        raise HTTPException(status_code=500, detail="Error interno")

    # Analizar con Gemini
    try:
        result = gemini_service.analyze_audio(audio_bytes, content_type, session_id)
    except Exception as e:
        logger.error(f"Gemini audio analysis failed: {e}", exc_info=True)
        raise HTTPException(status_code=503, detail="Servicio no disponible")

    return {
        "category": result.get("category"),
        "label": result.get("label"),
        "confidence": result.get("confidence"),
        "recommendation": result.get("recommendation"),
        "observations": result.get("observations"),
        "session_id": session_id,
    }
