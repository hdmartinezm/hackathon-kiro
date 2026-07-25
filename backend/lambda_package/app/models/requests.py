"""Modelos Pydantic de request para BabyHealth API."""
from pydantic import BaseModel
from typing import Optional, Dict, Any


class AnalyzeRequest(BaseModel):
    video_key: str
    session_id: Optional[str] = None
    # Idioma para el texto generado por la IA: "es" (default) o "en".
    language: str = "es"
    # Contexto del perfil del bebé (edad, peso, etc.) para enriquecer el análisis.
    profile_context: Optional[Dict[str, Any]] = None
