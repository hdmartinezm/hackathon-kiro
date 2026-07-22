"""Servicio S3 para BabyHealth - upload y download de videos/imágenes."""
import logging
import uuid
from datetime import datetime, timezone, timedelta
import boto3
from botocore.exceptions import ClientError
from app.config import settings

logger = logging.getLogger(__name__)

s3_client = boto3.client("s3", region_name=settings.AWS_REGION)


def generate_presigned_url_for_video(
    content_type: str = "video/mp4",
    expiration: int = 300,
) -> dict:
    """Genera una URL prefirmada para subir video a S3.

    Args:
        content_type: MIME type del archivo (video/mp4 o video/webm).
        expiration: Tiempo de expiración en segundos.

    Returns:
        Dict con upload_url, video_key, expires_at y content_type.
    """
    extension = "mp4" if "mp4" in content_type else "webm"
    video_key = f"videos/{uuid.uuid4()}.{extension}"

    try:
        upload_url = s3_client.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": settings.S3_BUCKET,
                "Key": video_key,
                "ContentType": content_type,
            },
            ExpiresIn=expiration,
        )
        expires_at = (datetime.now(timezone.utc) + timedelta(seconds=expiration)).isoformat()

        logger.info(f"Presigned URL generada para {video_key}")
        return {
            "upload_url": upload_url,
            "video_key": video_key,
            "expires_at": expires_at,
            "content_type": content_type,
        }
    except ClientError as e:
        logger.error(f"Error generando presigned URL: {e}")
        raise


def generate_presigned_url_for_image(
    content_type: str = "image/jpeg",
    expiration: int = 300,
) -> dict:
    """Genera una URL prefirmada para subir imagen a S3."""
    extension = "jpg" if "jpeg" in content_type else "png"
    image_key = f"images/{uuid.uuid4()}.{extension}"

    try:
        upload_url = s3_client.generate_presigned_url(
            "put_object",
            Params={
                "Bucket": settings.S3_BUCKET,
                "Key": image_key,
                "ContentType": content_type,
            },
            ExpiresIn=expiration,
        )
        expires_at = (datetime.now(timezone.utc) + timedelta(seconds=expiration)).isoformat()

        return {
            "upload_url": upload_url,
            "image_key": image_key,
            "expires_at": expires_at,
            "content_type": content_type,
        }
    except ClientError as e:
        logger.error(f"Error generando presigned URL para imagen: {e}")
        raise


def download_object(key: str) -> tuple[bytes, str]:
    """Descarga un objeto de S3 y retorna sus bytes y content_type.

    Args:
        key: La key del objeto en S3.

    Returns:
        Tupla (bytes, content_type) del archivo descargado.
    """
    try:
        response = s3_client.get_object(Bucket=settings.S3_BUCKET, Key=key)
        data = response["Body"].read()
        content_type = response.get("ContentType", "application/octet-stream")
        logger.info(f"Descargado {key} ({len(data)} bytes, {content_type}) de S3")
        return data, content_type
    except ClientError as e:
        logger.error(f"Error descargando {key} de S3: {e}")
        raise
