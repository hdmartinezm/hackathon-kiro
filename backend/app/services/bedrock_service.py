"""Servicio de Amazon Bedrock para análisis de imágenes con Claude."""
import json
import base64
import logging
import boto3
from botocore.exceptions import ClientError
from app.config import settings

logger = logging.getLogger(__name__)

bedrock_client = boto3.client("bedrock-runtime", region_name=settings.AWS_REGION)

VISUAL_ANALYSIS_PROMPT = """Eres un asistente de orientación en salud infantil. Analiza la imagen proporcionada y determina:

1. **¿Hay un bebé en la imagen?** - Responde true o false.
2. Si HAY un bebé:
   - **Estado general**: Evalúa si parece estar "normal", "requiere_atencion" o "urgente".
   - **Observaciones**: Describe lo que observas (color de piel, expresión, postura, etc.)
   - **Recomendaciones**: Proporciona recomendaciones generales.
3. Si NO hay bebé:
   - status debe ser "requiere_atencion"
   - Describe qué hay en la imagen en observaciones
   - Indica que se necesita una imagen de bebé en recomendaciones

IMPORTANTE: Esta es solo una herramienta orientativa. NO es un diagnóstico médico.

Responde EXCLUSIVAMENTE en formato JSON con esta estructura:
{
    "baby_detected": true | false,
    "status": "normal" | "requiere_atencion" | "urgente",
    "observations": "descripción detallada de observaciones",
    "recommendations": "recomendaciones para los padres",
    "confidence": 0.0 a 1.0
}"""

CRY_ANALYSIS_PROMPT = """Eres un asistente especializado en análisis de llanto infantil. Analiza el espectrograma de audio proporcionado y clasifica el tipo de llanto del bebé.

PRIMERO determina si hay llanto de bebé en el espectrograma. Si no detectas patrones de llanto infantil (solo ruido ambiente, silencio, música, voces adultas, etc.), usa la categoría "sin_llanto".

Categorías posibles:
- "sin_llanto": No se detecta llanto de bebé en el audio (ruido ambiente, silencio, etc.)
- "hambre": Llanto rítmico, repetitivo, intensidad creciente
- "dolor": Llanto agudo, súbito, alta intensidad
- "sueno": Llanto irregular, con pausas, baja intensidad
- "incomodidad": Llanto moderado, constante
- "colico": Llanto prolongado, alta intensidad, difícil de calmar
- "desconocido": Hay llanto pero no se puede clasificar con certeza

Responde EXCLUSIVAMENTE en formato JSON:
{
    "cry_detected": true | false,
    "cry_category": "categoria",
    "cry_label": "etiqueta descriptiva en español",
    "cry_confidence": 0.0 a 1.0,
    "cry_recommendation": "recomendación específica"
}"""


def analyze_image(image_bytes: bytes, media_type: str = "image/jpeg", prompt: str = None) -> dict:
    """Analiza una imagen usando Claude via Bedrock Converse API.

    Args:
        image_bytes: Bytes de la imagen a analizar.
        media_type: MIME type de la imagen.
        prompt: Prompt personalizado (usa VISUAL_ANALYSIS_PROMPT por defecto).

    Returns:
        Dict con el resultado del análisis.
    """
    if prompt is None:
        prompt = VISUAL_ANALYSIS_PROMPT

    try:
        response = bedrock_client.converse(
            modelId=settings.BEDROCK_MODEL_ID,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "image": {
                                "format": media_type.split("/")[-1] if "/" in media_type else "jpeg",
                                "source": {"bytes": image_bytes},
                            }
                        },
                        {"text": prompt},
                    ],
                }
            ],
            inferenceConfig={"maxTokens": 1024, "temperature": 0.1},
        )

        # Extraer texto de la respuesta
        output_message = response["output"]["message"]
        result_text = ""
        for block in output_message["content"]:
            if "text" in block:
                result_text += block["text"]

        # Parsear JSON de la respuesta
        # Intentar extraer JSON del texto
        result_text = result_text.strip()
        if result_text.startswith("```"):
            # Eliminar code fences
            lines = result_text.split("\n")
            result_text = "\n".join(lines[1:-1])

        result = json.loads(result_text)

        # Normalizar status a valores válidos
        valid_statuses = {"normal", "requiere_atencion", "urgente"}
        raw_status = result.get("status", "").lower()
        if raw_status not in valid_statuses:
            # Si el modelo no puede analizar (ej: no hay bebé), marcar como requiere_atencion
            logger.warning(f"Status inválido '{raw_status}' normalizado a 'requiere_atencion'")
            result["status"] = "requiere_atencion"
            if not result.get("error"):
                result["error"] = f"El modelo retornó status no válido: {raw_status}"

        logger.info(f"Análisis Bedrock completado: status={result.get('status', 'N/A')}")
        return result

    except json.JSONDecodeError as e:
        logger.error(f"Error parseando respuesta de Bedrock: {e}. Texto: {result_text[:200]}")
        return {
            "status": "normal",
            "observations": "No se pudo interpretar la respuesta del modelo.",
            "recommendations": "Intente nuevamente o consulte a su pediatra.",
            "confidence": 0.0,
            "error": f"Parse error: {str(e)}",
        }
    except ClientError as e:
        logger.error(f"Error en Bedrock API: {e}")
        raise
    except Exception as e:
        logger.error(f"Error inesperado en análisis Bedrock: {e}")
        raise


def analyze_cry_spectrogram(spectrogram_bytes: bytes, media_type: str = "image/png") -> dict:
    """Analiza un espectrograma de llanto usando Claude via Bedrock.

    Args:
        spectrogram_bytes: Bytes de la imagen del espectrograma.
        media_type: MIME type de la imagen.

    Returns:
        Dict con clasificación del llanto.
    """
    return analyze_image(spectrogram_bytes, media_type=media_type, prompt=CRY_ANALYSIS_PROMPT)
