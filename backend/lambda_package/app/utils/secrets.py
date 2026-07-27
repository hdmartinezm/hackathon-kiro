"""
Utility for fetching secrets from AWS Secrets Manager.
"""

import json
import logging
from functools import lru_cache

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)


@lru_cache(maxsize=10)
def get_secret(secret_name: str, region_name: str = "us-east-1") -> str:
    """
    Fetch a secret value from AWS Secrets Manager.

    Args:
        secret_name: Name or ARN of the secret
        region_name: AWS region where the secret is stored

    Returns:
        The secret string value

    Raises:
        ClientError: If the secret cannot be retrieved
    """
    client = boto3.client("secretsmanager", region_name=region_name)

    try:
        response = client.get_secret_value(SecretId=secret_name)

        if "SecretString" in response:
            return response["SecretString"]
        else:
            # Binary secret - decode it
            import base64
            return base64.b64decode(response["SecretBinary"]).decode("utf-8")

    except ClientError as e:
        logger.error(f"Failed to retrieve secret {secret_name}: {e}")
        raise


def get_gemini_api_key() -> str:
    """
    Get the Gemini API key from Secrets Manager.

    Falls back to GEMINI_API_KEY environment variable if secret fetch fails.
    """
    import os

    try:
        return get_secret("babyhealth/gemini-api-key")
    except Exception as e:
        logger.warning(f"Could not fetch Gemini API key from Secrets Manager: {e}")
        # Fallback to environment variable
        key = os.environ.get("GEMINI_API_KEY", "")
        if key:
            logger.info("Using GEMINI_API_KEY from environment variable (fallback)")
        return key
