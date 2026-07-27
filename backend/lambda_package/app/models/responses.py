"""Modelos Pydantic de respuesta para BabyHealth API."""
from typing import Optional, Literal
from pydantic import BaseModel


class UploadUrlResponse(BaseModel):
    upload_url: str
    expires_at: str
    video_key: str
    content_type: str


class AnalysisResult(BaseModel):
    status: Literal["normal", "requiere_atencion", "urgente"]
    observations: str
    recommendations: str
    confidence: Optional[float] = None
    cry_category: Optional[str] = None
    cry_label: Optional[str] = None
    cry_confidence: Optional[float] = None
    cry_recommendation: Optional[str] = None
    error: Optional[str] = None
    session_id: str
    disclaimer: str = (
        "Esta herramienta es solo orientativa. No reemplaza la evaluación médica profesional. "
        "Consulte a su pediatra ante cualquier preocupación."
    )


class ErrorResponse(BaseModel):
    detail: str
    code: Optional[str] = None
