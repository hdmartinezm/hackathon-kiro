"""
Servicio de interacción con Google Gemini para análisis multimodal de BabyHealth.

Utiliza Gemini 2.5 Flash para analizar videos de bebés (visual + audio nativo)
y detectar posibles condiciones de salud, así como clasificar el tipo de llanto.
"""

import base64
import json
import logging
import time
from typing import Any

from google import genai
from google.genai import types

from app.config import settings

logger = logging.getLogger(__name__)

# System prompt para análisis multimodal de video
VIDEO_ANALYSIS_PROMPT = """Eres un asistente de orientación para padres. Analiza este video de un bebé.

Realiza un análisis multimodal completo:

1. ANÁLISIS VISUAL:
- Coloración de piel (busca tonos amarillentos que podrían indicar ictericia)
- Expresión facial (signos de malestar o tranquilidad)
- Movimientos y postura
- Estado general visible

2. ANÁLISIS DE AUDIO:
- Si hay llanto, clasifica el tipo: hambre, dolor, sueño, gases, incomodidad, miedo, soledad
- Evalúa la intensidad y patrón del llanto
- Si no hay llanto audible, indica null para cry_category

Responde SOLO en JSON válido con este formato exacto:
{
  "status": "normal",
  "observations": "Descripción detallada de lo observado en el video, tanto visual como auditivo.",
  "recommendations": "Recomendaciones específicas para el cuidador basadas en el análisis.",
  "confidence": 0.87,
  "cry_category": "hambre",
  "cry_label": "Hambre",
  "cry_confidence": 0.82,
  "cry_recommendation": "Ofrecer alimentación al bebé",
  "error": null
}

Valores posibles de status: "normal", "requiere_atencion", "urgente"
Valores posibles de cry_category: "hambre", "dolor", "sueño", "gases", "incomodidad", "miedo", "soledad", "desconocido", null

Reglas importantes:
- Si la calidad del video es insuficiente, retorna status "requiere_atencion" con error describiendo el problema
- Si no detectas llanto, cry_category, cry_label, cry_confidence y cry_recommendation deben ser null
- Si detectas posible ictericia u otra condición preocupante, status debe ser "requiere_atencion" o "urgente"
- observations y recommendations deben ser textos descriptivos en español
- El valor de confidence refleja tu certeza general del análisis visual (0.0-1.0)
- cry_confidence refleja tu certeza sobre la clasificación del llanto (0.0-1.0)
"""

# System prompt para análisis de audio (llanto)
AUDIO_ANALYSIS_PROMPT = """Eres un experto en análisis de llanto infantil. Analiza este audio de un bebé.

Clasifica el tipo de llanto en una de estas categorías:
- "hambre": Llanto rítmico, repetitivo, intensidad media que aumenta gradualmente
- "dolor": Llanto agudo, intenso, repentino, a veces con pausas para respirar
- "sueño": Llanto suave, quejumbroso, intermitente, con bostezos
- "gases": Llanto intenso con pausas, el bebé puede encogerse
- "incomodidad": Llanto moderado, irregular (pañal mojado, ropa incómoda)
- "miedo": Llanto súbito, con sobresaltos
- "soledad": Llanto suave que se intensifica gradualmente si no hay respuesta
- "desconocido": Si no puedes determinar la causa con certeza

Responde SOLO en JSON válido:
{
  "category": "hambre",
  "label": "Hambre",
  "confidence": 0.82,
  "recommendation": "Ofrecer alimentación al bebé",
  "observations": "Descripción del patrón de llanto detectado"
}

Si no detectas llanto de bebé en el audio:
{
  "category": "sin_llanto",
  "label": "No se detecta llanto",
  "confidence": 0.0,
  "recommendation": "No se detectó llanto de bebé en el audio",
  "observations": "El audio no contiene llanto de bebé audible"
}
"""


def _get_client() -> genai.Client:
    """Crea y retorna un cliente de Gemini."""
    if not settings.GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY no está configurada")
    return genai.Client(api_key=settings.GEMINI_API_KEY)


def _parse_json_response(response_text: str) -> dict[str, Any]:
    """Parsea la respuesta JSON de Gemini, extrayendo JSON si está embebido en texto."""
    # Intentar parsear directamente
    try:
        return json.loads(response_text.strip())
    except json.JSONDecodeError:
        pass

    # Buscar JSON en la respuesta
    json_start = response_text.find("{")
    json_end = response_text.rfind("}") + 1

    if json_start == -1 or json_end == 0:
        raise ValueError(f"No valid JSON found in response: {response_text[:200]}")

    try:
        json_str = response_text[json_start:json_end]
        return json.loads(json_str)
    except json.JSONDecodeError as e:
        raise ValueError(f"Failed to parse JSON: {e}") from e


def _validate_video_response(data: dict[str, Any]) -> dict[str, Any]:
    """Valida y normaliza la respuesta de análisis de video."""
    valid_statuses = {"normal", "requiere_atencion", "urgente"}

    # Validar status
    if "status" not in data or data["status"] not in valid_statuses:
        data["status"] = "requiere_atencion"
        data["error"] = data.get("error") or "No se pudo determinar el estado con certeza."

    # Asegurar que observations y recommendations sean strings
    if "observations" not in data or not isinstance(data["observations"], str):
        data["observations"] = "No fue posible analizar el video correctamente."

    if "recommendations" not in data or not isinstance(data["recommendations"], str):
        data["recommendations"] = "Grabe un nuevo video con mejor iluminación y en un ambiente silencioso."

    # Validar confidence
    if "confidence" in data and data["confidence"] is not None:
        try:
            conf = float(data["confidence"])
            data["confidence"] = max(0.0, min(1.0, conf))
        except (TypeError, ValueError):
            data["confidence"] = None
    else:
        data["confidence"] = None

    # Validar cry_confidence
    if "cry_confidence" in data and data["cry_confidence"] is not None:
        try:
            conf = float(data["cry_confidence"])
            data["cry_confidence"] = max(0.0, min(1.0, conf))
        except (TypeError, ValueError):
            data["cry_confidence"] = None

    # Asegurar campos nullable
    for field in ["cry_category", "cry_label", "cry_recommendation", "error"]:
        if field not in data:
            data[field] = None

    return data


def analyze_video(video_bytes: bytes, content_type: str, session_id: str) -> dict[str, Any]:
    """Analiza un video de bebé usando Gemini (multimodal nativo).

    Gemini procesa el video completo incluyendo visual y audio de forma nativa,
    sin necesidad de extraer frames o convertir audio.

    Args:
        video_bytes: Bytes del video.
        content_type: MIME type del video (video/mp4, video/webm, etc.).
        session_id: ID de sesión para logging.

    Returns:
        Dict con: status, observations, recommendations, confidence,
                  cry_category, cry_label, cry_confidence, cry_recommendation, error
    """
    logger.info(
        "Starting Gemini video analysis",
        extra={
            "session_id": session_id,
            "content_type": content_type,
            "video_size_bytes": len(video_bytes),
            "model": settings.GEMINI_MODEL_ID,
        },
    )

    client = _get_client()

    # Para videos pequeños (<20MB), usar inline data
    # Para videos grandes, usar Files API
    video_size_mb = len(video_bytes) / (1024 * 1024)

    if video_size_mb > 20:
        # Usar Files API para videos grandes
        result = _analyze_video_with_upload(client, video_bytes, content_type, session_id)
    else:
        # Usar inline data para videos pequeños
        result = _analyze_video_inline(client, video_bytes, content_type, session_id)

    validated = _validate_video_response(result)

    logger.info(
        "Gemini video analysis completed",
        extra={
            "session_id": session_id,
            "status": validated.get("status"),
            "confidence": validated.get("confidence"),
            "cry_category": validated.get("cry_category"),
        },
    )

    return validated


def _analyze_video_inline(
    client: genai.Client,
    video_bytes: bytes,
    content_type: str,
    session_id: str
) -> dict[str, Any]:
    """Analiza video usando datos inline (para videos < 20MB)."""
    video_b64 = base64.b64encode(video_bytes).decode("utf-8")

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL_ID,
        contents=[
            types.Content(
                parts=[
                    types.Part(
                        inline_data=types.Blob(
                            mime_type=content_type,
                            data=video_b64,
                        )
                    ),
                    types.Part(text=VIDEO_ANALYSIS_PROMPT),
                ]
            )
        ],
        config=types.GenerateContentConfig(
            temperature=0.1,
            max_output_tokens=2048,
        ),
    )

    response_text = response.text
    if not response_text:
        raise ValueError("Gemini returned empty response")

    return _parse_json_response(response_text)


def _analyze_video_with_upload(
    client: genai.Client,
    video_bytes: bytes,
    content_type: str,
    session_id: str
) -> dict[str, Any]:
    """Analiza video usando Files API (para videos > 20MB)."""
    import tempfile
    import os

    # Determinar extensión
    ext_map = {
        "video/mp4": ".mp4",
        "video/webm": ".webm",
        "video/quicktime": ".mov",
    }
    ext = ext_map.get(content_type, ".mp4")

    # Guardar temporalmente
    with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as tmp:
        tmp.write(video_bytes)
        tmp_path = tmp.name

    try:
        # Subir a Gemini
        uploaded_file = client.files.upload(file=tmp_path)

        # Esperar procesamiento
        while uploaded_file.state.name != "ACTIVE":
            logger.info(f"Video processing... state={uploaded_file.state.name}")
            time.sleep(2)
            uploaded_file = client.files.get(name=uploaded_file.name)

        # Analizar
        response = client.models.generate_content(
            model=settings.GEMINI_MODEL_ID,
            contents=[
                types.Content(
                    parts=[
                        types.Part(
                            file_data=types.FileData(
                                file_uri=uploaded_file.uri,
                                mime_type=uploaded_file.mime_type,
                            )
                        ),
                        types.Part(text=VIDEO_ANALYSIS_PROMPT),
                    ]
                )
            ],
            config=types.GenerateContentConfig(
                temperature=0.1,
                max_output_tokens=2048,
            ),
        )

        response_text = response.text
        if not response_text:
            raise ValueError("Gemini returned empty response")

        return _parse_json_response(response_text)

    finally:
        # Limpiar archivo temporal
        os.unlink(tmp_path)


def analyze_audio(audio_bytes: bytes, content_type: str, session_id: str) -> dict[str, Any]:
    """Analiza audio de llanto de bebé usando Gemini.

    Args:
        audio_bytes: Bytes del audio (WAV, MP3, etc.).
        content_type: MIME type del audio.
        session_id: ID de sesión para logging.

    Returns:
        Dict con: category, label, confidence, recommendation, observations
    """
    logger.info(
        "Starting Gemini audio analysis",
        extra={
            "session_id": session_id,
            "content_type": content_type,
            "audio_size_bytes": len(audio_bytes),
        },
    )

    client = _get_client()
    audio_b64 = base64.b64encode(audio_bytes).decode("utf-8")

    response = client.models.generate_content(
        model=settings.GEMINI_MODEL_ID,
        contents=[
            types.Content(
                parts=[
                    types.Part(
                        inline_data=types.Blob(
                            mime_type=content_type,
                            data=audio_b64,
                        )
                    ),
                    types.Part(text=AUDIO_ANALYSIS_PROMPT),
                ]
            )
        ],
        config=types.GenerateContentConfig(
            temperature=0.1,
            max_output_tokens=1024,
        ),
    )

    response_text = response.text
    if not response_text:
        raise ValueError("Gemini returned empty response for audio")

    result = _parse_json_response(response_text)

    # Validar campos básicos
    if "category" not in result:
        result["category"] = "desconocido"
    if "label" not in result:
        result["label"] = "Desconocido"
    if "confidence" not in result:
        result["confidence"] = 0.0
    if "recommendation" not in result:
        result["recommendation"] = "No se pudo clasificar el llanto"

    logger.info(
        "Gemini audio analysis completed",
        extra={
            "session_id": session_id,
            "category": result.get("category"),
            "confidence": result.get("confidence"),
        },
    )

    return result
