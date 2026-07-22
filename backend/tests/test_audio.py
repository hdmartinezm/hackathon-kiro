"""Tests para funcionalidad de análisis de audio."""
import pytest
import numpy as np
from unittest.mock import patch, MagicMock


def test_generate_synthetic_spectrogram():
    from app.routers.analyze import _generate_synthetic_spectrogram

    result = _generate_synthetic_spectrogram()
    assert isinstance(result, bytes)
    assert len(result) > 0
    # Verificar que es un PNG válido (magic bytes)
    assert result[:8] == b"\x89PNG\r\n\x1a\n"


def test_generate_spectrogram_image():
    from app.routers.analyze import _generate_spectrogram_image

    # Generar datos de audio sintéticos (1 segundo de ruido)
    sample_rate = 16000
    audio_data = np.random.randint(-32768, 32767, size=sample_rate, dtype=np.int16)

    result = _generate_spectrogram_image(audio_data, sample_rate=sample_rate)
    assert isinstance(result, bytes)
    assert len(result) > 0
    # Verificar que es PNG
    assert result[:8] == b"\x89PNG\r\n\x1a\n"


@patch("app.services.bedrock_service.bedrock_client")
def test_analyze_cry_spectrogram(mock_client):
    from app.services.bedrock_service import analyze_cry_spectrogram

    mock_client.converse.return_value = {
        "output": {
            "message": {
                "content": [
                    {
                        "text": '{"cry_category": "hambre", "cry_label": "Llanto por hambre", "cry_confidence": 0.82, "cry_recommendation": "Alimentar al bebé"}'
                    }
                ]
            }
        }
    }

    # Crear un PNG mínimo como espectrograma
    result = analyze_cry_spectrogram(b"\x89PNG\r\n\x1a\n" + b"\x00" * 100)
    assert result["cry_category"] == "hambre"
    assert result["cry_confidence"] == 0.82
