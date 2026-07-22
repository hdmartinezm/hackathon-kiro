"""
Configuración centralizada de la aplicación BabyHealth.

Lee variables de entorno con valores por defecto para desarrollo local.
Usa un patrón singleton (instancia a nivel de módulo) para fácil importación.
"""

from functools import lru_cache

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Variables de configuración de la aplicación."""

    # AWS Resources
    S3_BUCKET: str = "babyhealth-images"
    BEDROCK_MODEL_ID: str = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
    DYNAMODB_TABLE: str = "babyhealth-results"
    AWS_REGION: str = "us-east-1"

    # Google Gemini
    GEMINI_API_KEY: str = ""
    GEMINI_MODEL_ID: str = "gemini-2.5-flash"

    # App
    APP_VERSION: str = "1.0.0"
    ALLOWED_ORIGINS: list[str] = ["*"]

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": True,
    }


@lru_cache
def get_settings() -> Settings:
    """Retorna instancia cacheada de Settings (singleton funcional)."""
    return Settings()


# Instancia a nivel de módulo para importación directa:
#   from app.config import settings
settings = get_settings()
