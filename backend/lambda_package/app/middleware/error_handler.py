"""Global error handler middleware para BabyHealth API."""
import logging
import traceback
from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.middleware.base import BaseHTTPMiddleware

logger = logging.getLogger(__name__)


class ErrorHandlerMiddleware(BaseHTTPMiddleware):
    """Middleware que captura excepciones no manejadas y retorna respuestas JSON estructuradas."""

    async def dispatch(self, request: Request, call_next):
        try:
            response = await call_next(request)
            return response
        except Exception as exc:
            logger.error(
                f"Unhandled exception: {type(exc).__name__}: {str(exc)}",
                extra={
                    "path": request.url.path,
                    "method": request.method,
                    "traceback": traceback.format_exc(),
                },
            )
            return JSONResponse(
                status_code=500,
                content={
                    "detail": "Error interno del servidor",
                    "code": "INTERNAL_ERROR",
                },
            )


async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handler para errores de validación de Pydantic/FastAPI."""
    logger.warning(f"Validation error on {request.url.path}: {exc.errors()}")
    return JSONResponse(
        status_code=422,
        content={
            "detail": "Error de validación en los datos enviados",
            "code": "VALIDATION_ERROR",
            "errors": exc.errors(),
        },
    )


async def value_error_handler(request: Request, exc: ValueError):
    """Handler para ValueErrors lanzados en la lógica de negocio."""
    logger.warning(f"Value error on {request.url.path}: {str(exc)}")
    return JSONResponse(
        status_code=400,
        content={
            "detail": str(exc),
            "code": "BAD_REQUEST",
        },
    )
