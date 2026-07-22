"""Configuración centralizada de la aplicación BabyHealth."""
from functools import lru_cache
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    S3_BUCKET: str = "babyhealth-images-hackathon"
    BEDROCK_MODEL_ID: str = "us.anthropic.claude-sonnet-4-5-20250929-v1:0"
    DYNAMODB_TABLE: str = "babyhealth-results"
    AWS_REGION: str = "us-east-1"
    APP_VERSION: str = "1.0.0"
    ALLOWED_ORIGINS: list[str] = ["*"]

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "case_sensitive": True,
    }


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
