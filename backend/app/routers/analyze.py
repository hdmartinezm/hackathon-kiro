"""Router de análisis multimodal - video (frame + espectrograma de audio)."""
import io
import logging
import uuid
import tempfile
from fastapi import APIRouter, HTTPException
from app.models.requests import AnalyzeRequest
from app.models.responses import AnalysisResult
from app.services.s3_service import download_object
from app.services.bedrock_service import analyze_image, analyze_cry_spectrogram
from app.services.dynamo_service import save_result

logger = logging.getLogger(__name__)
router = APIRouter(tags=["analyze"])


def extract_frame_from_video(video_bytes: bytes) -> bytes:
    """Extrae un frame representativo del video usando ffmpeg + pillow.

    Args:
        video_bytes: Bytes del video.

    Returns:
        bytes de la imagen (JPEG) del frame extraído.
    """
    import subprocess
    import os
    from PIL import Image

    try:
        # Guardar video temporalmente
        with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as tmp_video:
            tmp_video.write(video_bytes)
            tmp_video_path = tmp_video.name

        # Archivo de salida para el frame
        with tempfile.NamedTemporaryFile(suffix=".jpg", delete=False) as tmp_frame:
            tmp_frame_path = tmp_frame.name

        try:
            # Extraer frame del medio del video usando ffmpeg
            # -ss 00:00:01 busca el frame en el segundo 1 (o cerca del inicio)
            # -frames:v 1 extrae solo un frame
            # En Lambda, ffmpeg está en /opt/bin (desde el layer)
            ffmpeg_path = "/opt/bin/ffmpeg" if os.path.exists("/opt/bin/ffmpeg") else "ffmpeg"
            subprocess.run(
                [
                    ffmpeg_path, "-i", tmp_video_path,
                    "-ss", "00:00:01",
                    "-frames:v", "1",
                    "-q:v", "2",  # Alta calidad JPEG
                    "-y", tmp_frame_path,
                ],
                capture_output=True,
                timeout=30,
                check=True,
            )

            # Leer el frame extraído
            with open(tmp_frame_path, "rb") as f:
                frame_bytes = f.read()

            if len(frame_bytes) == 0:
                raise ValueError("Frame extraído está vacío")

            return frame_bytes

        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            logger.warning(f"ffmpeg no disponible o error: {e}. Generando imagen placeholder.")
            # Generar imagen placeholder si ffmpeg no está disponible
            return _generate_placeholder_image()

        finally:
            # Cleanup
            if os.path.exists(tmp_video_path):
                os.unlink(tmp_video_path)
            if os.path.exists(tmp_frame_path):
                os.unlink(tmp_frame_path)

    except Exception as e:
        logger.error(f"Error extrayendo frame del video: {e}")
        raise


def _generate_placeholder_image() -> bytes:
    """Genera una imagen placeholder cuando no se puede extraer frame."""
    from PIL import Image, ImageDraw

    # Crear imagen gris con texto
    img = Image.new("RGB", (640, 480), color=(128, 128, 128))
    draw = ImageDraw.Draw(img)
    draw.text((220, 230), "No video frame", fill=(255, 255, 255))

    buffer = io.BytesIO()
    img.save(buffer, format="JPEG", quality=85)
    buffer.seek(0)
    return buffer.read()


def extract_audio_spectrogram(video_bytes: bytes) -> bytes:
    """Genera un espectrograma del audio del video.

    Args:
        video_bytes: Bytes del video.

    Returns:
        bytes de la imagen PNG del espectrograma.
    """
    import subprocess
    import os

    try:
        # Guardar video temporalmente para extraer audio con ffmpeg vía imageio
        with tempfile.NamedTemporaryFile(suffix=".mp4", delete=False) as tmp_video:
            tmp_video.write(video_bytes)
            tmp_video_path = tmp_video.name

        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_audio:
            tmp_audio_path = tmp_audio.name

        # Extraer audio usando ffmpeg
        # En Lambda, ffmpeg está en /opt/bin (desde el layer)
        ffmpeg_path = "/opt/bin/ffmpeg" if os.path.exists("/opt/bin/ffmpeg") else "ffmpeg"
        try:
            subprocess.run(
                [
                    ffmpeg_path, "-i", tmp_video_path,
                    "-vn", "-acodec", "pcm_s16le",
                    "-ar", "16000", "-ac", "1",
                    "-y", tmp_audio_path,
                ],
                capture_output=True,
                timeout=30,
                check=True,
            )
        except (subprocess.CalledProcessError, FileNotFoundError) as e:
            logger.warning(f"ffmpeg no disponible o error: {e}. Generando espectrograma sintético.")
            os.unlink(tmp_video_path)
            if os.path.exists(tmp_audio_path):
                os.unlink(tmp_audio_path)
            return _generate_synthetic_spectrogram()

        # Leer audio y generar espectrograma
        import wave
        import numpy as np

        with wave.open(tmp_audio_path, "rb") as wf:
            n_frames = wf.getnframes()
            audio_data = np.frombuffer(wf.readframes(n_frames), dtype=np.int16)

        # Cleanup temp files
        os.unlink(tmp_video_path)
        os.unlink(tmp_audio_path)

        if len(audio_data) == 0:
            logger.warning("Audio vacío, generando espectrograma sintético")
            return _generate_synthetic_spectrogram()

        # Generar espectrograma con matplotlib
        return _generate_spectrogram_image(audio_data, sample_rate=16000)

    except Exception as e:
        logger.error(f"Error generando espectrograma: {e}")
        return _generate_synthetic_spectrogram()


def _generate_spectrogram_image(audio_data, sample_rate: int = 16000) -> bytes:
    """Genera imagen de espectrograma a partir de datos de audio.

    Args:
        audio_data: numpy array con datos de audio
        sample_rate: frecuencia de muestreo (default 16000)
    """
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(1, 1, figsize=(10, 4))
    ax.specgram(audio_data, Fs=sample_rate, cmap="viridis")
    ax.set_xlabel("Tiempo (s)")
    ax.set_ylabel("Frecuencia (Hz)")
    ax.set_title("Espectrograma de Audio")

    buf = io.BytesIO()
    plt.savefig(buf, format="png", dpi=100, bbox_inches="tight")
    plt.close(fig)
    buf.seek(0)
    return buf.read()


def _generate_synthetic_spectrogram() -> bytes:
    """Genera un espectrograma sintético cuando no hay audio disponible."""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import numpy as np

    fig, ax = plt.subplots(1, 1, figsize=(10, 4))
    # Generar datos aleatorios como placeholder
    data = np.random.rand(128, 256)
    ax.imshow(data, aspect="auto", cmap="viridis", origin="lower")
    ax.set_xlabel("Tiempo")
    ax.set_ylabel("Frecuencia")
    ax.set_title("Espectrograma (sin audio detectado)")

    buf = io.BytesIO()
    plt.savefig(buf, format="png", dpi=100, bbox_inches="tight")
    plt.close(fig)
    buf.seek(0)
    return buf.read()


@router.post("/analyze", response_model=AnalysisResult)
def analyze_video(request: AnalyzeRequest):
    """Analiza un video: extrae frame + espectrograma y envía a Bedrock.

    1. Descarga video de S3
    2. Extrae un frame representativo
    3. Extrae audio y genera espectrograma
    4. Analiza frame con Bedrock (visual)
    5. Analiza espectrograma con Bedrock (clasificación de llanto)
    6. Retorna resultado combinado
    """
    session_id = request.session_id or str(uuid.uuid4())

    try:
        # 1. Descargar video de S3
        logger.info(f"Descargando video: {request.video_key}")
        video_bytes, _ = download_object(request.video_key)

        # 2. Extraer frame
        logger.info("Extrayendo frame del video...")
        frame_bytes = extract_frame_from_video(video_bytes)

        # 3. Extraer audio y generar espectrograma
        logger.info("Generando espectrograma de audio...")
        spectrogram_bytes = extract_audio_spectrogram(video_bytes)

        # 4. Analizar frame (visual)
        logger.info("Analizando frame con Bedrock...")
        visual_result = analyze_image(frame_bytes, media_type="image/jpeg")

        # 5. Analizar espectrograma (audio/llanto)
        logger.info("Analizando espectrograma con Bedrock...")
        cry_result = analyze_cry_spectrogram(spectrogram_bytes)

        # 6. Combinar resultados
        combined_result = AnalysisResult(
            status=visual_result.get("status", "normal"),
            observations=visual_result.get("observations", "No se pudieron generar observaciones"),
            recommendations=visual_result.get("recommendations", "Consulte a su pediatra"),
            confidence=visual_result.get("confidence"),
            cry_category=cry_result.get("cry_category"),
            cry_label=cry_result.get("cry_label"),
            cry_confidence=cry_result.get("cry_confidence"),
            cry_recommendation=cry_result.get("cry_recommendation"),
            session_id=session_id,
        )

        # Persistir resultado
        try:
            save_result(session_id, combined_result.model_dump(), analysis_type="multimodal")
        except Exception as e:
            logger.warning(f"No se pudo guardar resultado en DynamoDB: {e}")

        return combined_result

    except Exception as e:
        logger.error(f"Error en análisis de video: {e}")
        raise HTTPException(status_code=500, detail=f"Error procesando video: {str(e)}")
