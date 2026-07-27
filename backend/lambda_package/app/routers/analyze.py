"""Router de análisis multimodal - video (frame extraction + Bedrock analysis).

Simplified version that doesn't require PIL/numpy/matplotlib.
Uses ffmpeg for frame extraction and skips spectrogram analysis.
"""
import base64
import io
import logging
import os
import subprocess
import tempfile
import uuid
from fastapi import APIRouter, HTTPException
from app.models.requests import AnalyzeRequest
from app.models.responses import AnalysisResult
from app.services.s3_service import download_object
from app.services.bedrock_service import analyze_image
from app.services.dynamo_service import save_result

logger = logging.getLogger(__name__)
router = APIRouter(tags=["analyze"])

# Minimal 1x1 gray JPEG as placeholder (no PIL needed) - base64 encoded
PLACEHOLDER_JPEG = base64.b64decode(
    "/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRof"
    "Hh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwh"
    "MjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAAR"
    "CAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAn/xAAUEAEAAAAAAAAAAAAAAAAA"
    "AAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMB"
    "AAIRAxEAPwCwAB//2Q=="
)


def extract_frame_from_video(video_bytes: bytes) -> bytes:
    """Extrae un frame representativo del video usando ffmpeg.

    Args:
        video_bytes: Bytes del video.

    Returns:
        bytes de la imagen (JPEG) del frame extraído.
    """
    tmp_video_path = None
    tmp_frame_path = None

    try:
        # Guardar video temporalmente
        with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as tmp_video:
            tmp_video.write(video_bytes)
            tmp_video_path = tmp_video.name

        # Archivo de salida para el frame
        with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp_frame:
            tmp_frame_path = tmp_frame.name

        # Extraer frame usando ffmpeg
        # En Lambda, ffmpeg está en /opt/bin (desde el layer)
        ffmpeg_path = "/opt/bin/ffmpeg" if os.path.exists("/opt/bin/ffmpeg") else "ffmpeg"

        result = subprocess.run(
            [
                ffmpeg_path, "-i", tmp_video_path,
                "-ss", "00:00:01",
                "-frames:v", "1",
                "-q:v", "2",
                "-y", tmp_frame_path,
            ],
            capture_output=True,
            timeout=30,
        )

        if result.returncode != 0:
            logger.warning(f"ffmpeg error: {result.stderr.decode()}")
            return PLACEHOLDER_JPEG

        # Leer el frame extraído
        with open(tmp_frame_path, "rb") as f:
            frame_bytes = f.read()

        if len(frame_bytes) == 0:
            logger.warning("Frame extraído está vacío, usando placeholder")
            return PLACEHOLDER_JPEG

        return frame_bytes

    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        logger.warning(f"ffmpeg no disponible o timeout: {e}")
        return PLACEHOLDER_JPEG

    except Exception as e:
        logger.error(f"Error extrayendo frame del video: {e}")
        return PLACEHOLDER_JPEG

    finally:
        # Cleanup
        if tmp_video_path and os.path.exists(tmp_video_path):
            os.unlink(tmp_video_path)
        if tmp_frame_path and os.path.exists(tmp_frame_path):
            os.unlink(tmp_frame_path)


@router.post("/analyze", response_model=AnalysisResult)
def analyze_video(request: AnalyzeRequest):
    """Analiza un video: extrae frame y envía a Bedrock.

    1. Descarga video de S3
    2. Extrae un frame representativo con ffmpeg
    3. Analiza frame con Bedrock (visual)
    4. Retorna resultado (sin análisis de audio/llanto)
    """
    session_id = request.session_id or str(uuid.uuid4())

    try:
        # 1. Descargar video de S3
        logger.info(f"Descargando video: {request.video_key}")
        video_bytes, _ = download_object(request.video_key)

        # 2. Extraer frame
        logger.info("Extrayendo frame del video...")
        frame_bytes = extract_frame_from_video(video_bytes)

        # 3. Analizar frame (visual) con Bedrock
        logger.info("Analizando frame con Bedrock...")
        visual_result = analyze_image(
            frame_bytes, media_type="image/jpeg", language=request.language
        )

        # 4. Construir resultado (sin análisis de llanto por ahora)
        combined_result = AnalysisResult(
            status=visual_result.get("status", "normal"),
            observations=visual_result.get("observations", "No se pudieron generar observaciones"),
            recommendations=visual_result.get("recommendations", "Consulte a su pediatra"),
            confidence=visual_result.get("confidence"),
            cry_category=None,
            cry_label="Análisis de audio no disponible",
            cry_confidence=None,
            cry_recommendation="Use Gemini para análisis completo de audio y video.",
            session_id=session_id,
        )

        # Persistir resultado
        try:
            save_result(session_id, combined_result.model_dump(), analysis_type="bedrock-visual")
        except Exception as e:
            logger.warning(f"No se pudo guardar resultado en DynamoDB: {e}")

        return combined_result

    except Exception as e:
        logger.error(f"Error en análisis de video: {e}")
        raise HTTPException(status_code=500, detail=f"Error procesando video: {str(e)}")
