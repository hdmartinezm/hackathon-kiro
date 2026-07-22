"""Tests para el endpoint de upload."""
import pytest
from unittest.mock import patch, MagicMock
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_upload_url_invalid_content_type():
    response = client.get("/upload-url?content_type=application/pdf")
    assert response.status_code == 400


def test_upload_url_default_content_type():
    with patch("app.routers.upload.generate_presigned_url_for_video") as mock_gen:
        mock_gen.return_value = {
            "upload_url": "https://s3.amazonaws.com/test-bucket/videos/test.mp4?signed=1",
            "video_key": "videos/test-uuid.mp4",
            "expires_at": "2024-01-01T00:05:00+00:00",
            "content_type": "video/mp4",
        }
        response = client.get("/upload-url")
        assert response.status_code == 200
        data = response.json()
        assert "upload_url" in data
        assert "video_key" in data
        assert "expires_at" in data
        assert data["content_type"] == "video/mp4"


def test_upload_url_webm():
    with patch("app.routers.upload.generate_presigned_url_for_video") as mock_gen:
        mock_gen.return_value = {
            "upload_url": "https://s3.amazonaws.com/test-bucket/videos/test.webm?signed=1",
            "video_key": "videos/test-uuid.webm",
            "expires_at": "2024-01-01T00:05:00+00:00",
            "content_type": "video/webm",
        }
        response = client.get("/upload-url?content_type=video/webm")
        assert response.status_code == 200
        data = response.json()
        assert data["content_type"] == "video/webm"
