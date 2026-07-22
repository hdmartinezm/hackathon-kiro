"""Servicio DynamoDB para persistir resultados de análisis."""
import logging
import uuid
from datetime import datetime, timezone
from typing import Optional
import boto3
from botocore.exceptions import ClientError
from app.config import settings

logger = logging.getLogger(__name__)

dynamodb = boto3.resource("dynamodb", region_name=settings.AWS_REGION)
table = dynamodb.Table(settings.DYNAMODB_TABLE)


def save_result(session_id: str, analysis_result: dict, analysis_type: str = "visual") -> str:
    """Guarda un resultado de análisis en DynamoDB.

    Args:
        session_id: ID de la sesión.
        analysis_result: Resultado del análisis como dict.
        analysis_type: Tipo de análisis ('visual', 'audio', 'multimodal').

    Returns:
        ID del resultado guardado.
    """
    result_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    item = {
        "session_id": session_id,
        "result_id": result_id,
        "timestamp": timestamp,
        "analysis_type": analysis_type,
        **analysis_result,
    }

    try:
        table.put_item(Item=item)
        logger.info(f"Resultado guardado: session={session_id}, result={result_id}")
        return result_id
    except ClientError as e:
        logger.error(f"Error guardando resultado en DynamoDB: {e}")
        raise


def get_results_by_session(session_id: str, limit: int = 10) -> list[dict]:
    """Obtiene los resultados de análisis por session_id.

    Args:
        session_id: ID de la sesión a buscar.
        limit: Número máximo de resultados.

    Returns:
        Lista de resultados ordenados por timestamp descendente.
    """
    try:
        response = table.query(
            KeyConditionExpression=boto3.dynamodb.conditions.Key("session_id").eq(session_id),
            ScanIndexForward=False,
            Limit=limit,
        )
        items = response.get("Items", [])
        logger.info(f"Obtenidos {len(items)} resultados para session={session_id}")
        return items
    except ClientError as e:
        logger.error(f"Error consultando DynamoDB: {e}")
        raise
