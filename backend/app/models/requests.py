"""Modelos Pydantic de request para BabyHealth API."""
from pydantic import BaseModel
from typing import Optional


class AnalyzeRequest(BaseModel):
    video_key: str
    session_id: Optional[str] = None
    # Idioma para el texto generado por la IA: "es" (default) o "en".
    language: str = "es"
