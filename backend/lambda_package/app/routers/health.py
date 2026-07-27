"""Router de health check."""
import logging
from fastapi import APIRouter
from app.config import settings

logger = logging.getLogger(__name__)
router = APIRouter(tags=["health"])


@router.get("/health")
def health_check():
    return {"status": "ok", "version": settings.APP_VERSION}
