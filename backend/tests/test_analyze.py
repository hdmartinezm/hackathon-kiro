"""Tests para el endpoint de análisis multimodal."""
import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


@patch("app.routers.analyze.download_object")
@patch("app.routers.analyze.analyze_image")
@patch("app.routers.analyze.analyze_cry_spectrogram")
@patch("app.routers.analyze.extract_frame_from_video")
@patch("app.routers.analyze.extract_audio_spectrogram")
@patch("app.routers.analyze.save_result")
def test_analyze_video_success(
    mock_save, mock_spectrogram, mock_frame, mock_cry, mock_visual, mock_download
):
    mock_download.return_value = b"fake-video-bytes"
    mock_frame.return_value = b"fake-frame-jpeg"
    mock_spectrogram.return_value = b"fake-spectrogram-png"
    mock_visual.return_value = {
        "status": "normal",
        "observations": "Bebé en buen estado",
        "recommendations": "Continuar con cuidados normales",
        "confidence": 0.85,
    }
    mock_cry.return_value = {
        "cry_category": "hambre",
        "cry_label": "Llanto por hambre",
        "cry_confidence": 0.78,
        "cry_recommendation": "Alimentar al bebé",
    }
    mock_save.return_value = "result-123"

    response = client.post("/analyze", json={"video_key": "videos/test.mp4"})
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "normal"
    assert data["cry_category"] == "hambre"
    assert data["cry_confidence"] == 0.78
    assert "disclaimer" in data
    assert "session_id" in data


def test_analyze_missing_video_key():
    response = client.post("/analyze", json={})
    assert response.status_code == 422


@patch("app.routers.analyze.download_object")
def test_analyze_video_download_error(mock_download):
    mock_download.side_effect = Exception("S3 error")
    response = client.post("/analyze", json={"video_key": "videos/nonexistent.mp4"})
    assert response.status_code == 500
