"""
Configuración centralizada de la aplicación BabyHealth.

Lee variables de entorno con valores por defecto para desarrollo local.
Usa un patrón singleton (instancia a nivel de módulo) para fácil importación.
"""

from functools import lru_cache
from typing import Optional

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Variables de configuración de la aplicación."""

    # AWS Resources
    S3_BUCKET: str = "babyhealth-images"
    BEDROCK_MODEL_ID: str = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
    DYNAMODB_TABLE: str = "babyhealth-results"
    AWS_REGION: str = "us-east-1"

    # Google Gemini (loaded from Secrets Manager)
    GEMINI_MODEL_ID: str = "gemini-2.5-flash"
    _gemini_api_key: Optional[str] = None

    # App
    APP_VERSION: str = "1.0.0"
    ALLOWED_ORIGINS: list[str] = ["*"]

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": True,
    }

    @property
    def GEMINI_API_KEY(self) -> str:
        """Fetch Gemini API key from Secrets Manager (cached)."""
        if self._gemini_api_key is None:
            from app.utils.secrets import get_gemini_api_key
            self._gemini_api_key = get_gemini_api_key()
        return self._gemini_api_key


@lru_cache
def get_settings() -> Settings:
    """Retorna instancia cacheada de Settings (singleton funcional)."""
    return Settings()


# Instancia a nivel de módulo para importación directa:
#   from app.config import settings
settings = get_settings()
