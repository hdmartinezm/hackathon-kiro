"""BabyHealth API - Aplicación principal FastAPI."""
from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings
from app.middleware.error_handler import (
    ErrorHandlerMiddleware,
    validation_exception_handler,
    value_error_handler,
)
from app.middleware.logging_middleware import (
    StructuredLoggingMiddleware,
    configure_structured_logging,
)
from app.routers import health, upload, analyze
from app.routers import analyze_image

configure_structured_logging()

app = FastAPI(
    title="BabyHealth API",
    description="API de orientación de salud infantil con IA multimodal",
    version=settings.APP_VERSION,
)

app.add_middleware(ErrorHandlerMiddleware)
app.add_middleware(StructuredLoggingMiddleware)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_exception_handler(RequestValidationError, validation_exception_handler)
app.add_exception_handler(ValueError, value_error_handler)

app.include_router(health.router)
app.include_router(upload.router)
app.include_router(analyze.router)
app.include_router(analyze_image.router)
