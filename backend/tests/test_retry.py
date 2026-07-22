"""Tests para utilidad de retry con exponential backoff."""
import pytest
import asyncio
from unittest.mock import patch
from app.utils.retry import retry_with_backoff


class TestRetrySync:
    def test_success_first_attempt(self):
        call_count = 0

        @retry_with_backoff(max_attempts=3, base_delay=0.01)
        def always_succeeds():
            nonlocal call_count
            call_count += 1
            return "success"

        result = always_succeeds()
        assert result == "success"
        assert call_count == 1

    def test_success_after_retries(self):
        call_count = 0

        @retry_with_backoff(max_attempts=3, base_delay=0.01)
        def fails_twice():
            nonlocal call_count
            call_count += 1
            if call_count < 3:
                raise ValueError("Not yet")
            return "success"

        result = fails_twice()
        assert result == "success"
        assert call_count == 3

    def test_max_attempts_exceeded(self):
        call_count = 0

        @retry_with_backoff(max_attempts=3, base_delay=0.01)
        def always_fails():
            nonlocal call_count
            call_count += 1
            raise RuntimeError("Always fails")

        with pytest.raises(RuntimeError, match="Always fails"):
            always_fails()
        assert call_count == 3

    def test_specific_exceptions(self):
        call_count = 0

        @retry_with_backoff(max_attempts=3, base_delay=0.01, exceptions=(ValueError,))
        def raises_type_error():
            nonlocal call_count
            call_count += 1
            raise TypeError("Wrong type")

        with pytest.raises(TypeError):
            raises_type_error()
        assert call_count == 1  # No retry for TypeError


class TestRetryAsync:
    @pytest.mark.asyncio
    async def test_async_success_first_attempt(self):
        call_count = 0

        @retry_with_backoff(max_attempts=3, base_delay=0.01)
        async def async_succeeds():
            nonlocal call_count
            call_count += 1
            return "async_success"

        result = await async_succeeds()
        assert result == "async_success"
        assert call_count == 1

    @pytest.mark.asyncio
    async def test_async_success_after_retries(self):
        call_count = 0

        @retry_with_backoff(max_attempts=3, base_delay=0.01)
        async def async_fails_once():
            nonlocal call_count
            call_count += 1
            if call_count < 2:
                raise ConnectionError("Network error")
            return "recovered"

        result = await async_fails_once()
        assert result == "recovered"
        assert call_count == 2

    @pytest.mark.asyncio
    async def test_async_max_attempts_exceeded(self):
        call_count = 0

        @retry_with_backoff(max_attempts=3, base_delay=0.01)
        async def async_always_fails():
            nonlocal call_count
            call_count += 1
            raise IOError("IO failure")

        with pytest.raises(IOError):
            await async_always_fails()
        assert call_count == 3
