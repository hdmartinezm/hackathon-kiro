"""Utilidad de retry con exponential backoff."""
import asyncio
import logging
from functools import wraps
from typing import Type

logger = logging.getLogger(__name__)


def retry_with_backoff(
    max_attempts: int = 3,
    base_delay: float = 1.0,
    exceptions: tuple[Type[Exception], ...] = (Exception,),
):
    """Decorador de retry con exponential backoff.

    Args:
        max_attempts: Número máximo de intentos (default 3).
        base_delay: Delay base en segundos (default 1.0). Se duplica en cada intento.
        exceptions: Tuple de excepciones a capturar para reintentar.
    """

    def decorator(func):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            last_exception = None
            for attempt in range(1, max_attempts + 1):
                try:
                    return await func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    if attempt == max_attempts:
                        logger.error(
                            f"[Retry] {func.__name__} falló después de {max_attempts} intentos: {e}"
                        )
                        raise
                    delay = base_delay * (2 ** (attempt - 1))
                    logger.warning(
                        f"[Retry] {func.__name__} intento {attempt}/{max_attempts} falló: {e}. "
                        f"Reintentando en {delay}s..."
                    )
                    await asyncio.sleep(delay)
            raise last_exception

        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            import time

            last_exception = None
            for attempt in range(1, max_attempts + 1):
                try:
                    return func(*args, **kwargs)
                except exceptions as e:
                    last_exception = e
                    if attempt == max_attempts:
                        logger.error(
                            f"[Retry] {func.__name__} falló después de {max_attempts} intentos: {e}"
                        )
                        raise
                    delay = base_delay * (2 ** (attempt - 1))
                    logger.warning(
                        f"[Retry] {func.__name__} intento {attempt}/{max_attempts} falló: {e}. "
                        f"Reintentando en {delay}s..."
                    )
                    time.sleep(delay)
            raise last_exception

        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        return sync_wrapper

    return decorator
