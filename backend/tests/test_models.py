"""Tests para modelos Pydantic."""
import pytest
from hypothesis import given, strategies as st
from app.models.requests import AnalyzeRequest
from app.models.responses import AnalysisResult, UploadUrlResponse, ErrorResponse


class TestAnalyzeRequest:
    def test_valid_request(self):
        req = AnalyzeRequest(video_key="videos/test.mp4")
        assert req.video_key == "videos/test.mp4"
        assert req.session_id is None

    def test_request_with_session(self):
        req = AnalyzeRequest(video_key="videos/test.mp4", session_id="sess-123")
        assert req.session_id == "sess-123"

    def test_request_missing_video_key(self):
        with pytest.raises(Exception):
            AnalyzeRequest()

    @given(video_key=st.text(min_size=1, max_size=500))
    def test_request_accepts_any_string_video_key(self, video_key):
        req = AnalyzeRequest(video_key=video_key)
        assert req.video_key == video_key


class TestAnalysisResult:
    def test_valid_result(self):
        result = AnalysisResult(
            status="normal",
            observations="Todo bien",
            recommendations="Seguir así",
            session_id="sess-123",
        )
        assert result.status == "normal"
        assert result.disclaimer is not None

    def test_result_with_cry_fields(self):
        result = AnalysisResult(
            status="requiere_atencion",
            observations="Bebé llorando",
            recommendations="Verificar necesidades",
            session_id="sess-456",
            cry_category="hambre",
            cry_label="Llanto por hambre",
            cry_confidence=0.85,
            cry_recommendation="Alimentar al bebé",
        )
        assert result.cry_category == "hambre"
        assert result.cry_confidence == 0.85

    def test_invalid_status(self):
        with pytest.raises(Exception):
            AnalysisResult(
                status="invalid_status",
                observations="Test",
                recommendations="Test",
                session_id="sess-789",
            )

    @given(
        status=st.sampled_from(["normal", "requiere_atencion", "urgente"]),
        observations=st.text(min_size=1, max_size=1000),
        recommendations=st.text(min_size=1, max_size=1000),
    )
    def test_result_with_valid_status(self, status, observations, recommendations):
        result = AnalysisResult(
            status=status,
            observations=observations,
            recommendations=recommendations,
            session_id="test-session",
        )
        assert result.status == status


class TestUploadUrlResponse:
    def test_valid_response(self):
        resp = UploadUrlResponse(
            upload_url="https://s3.amazonaws.com/bucket/key?signed=1",
            expires_at="2024-01-01T00:05:00+00:00",
            video_key="videos/test.mp4",
            content_type="video/mp4",
        )
        assert resp.upload_url.startswith("https://")
        assert resp.content_type == "video/mp4"


class TestErrorResponse:
    def test_error_response(self):
        err = ErrorResponse(detail="Not found", code="NOT_FOUND")
        assert err.detail == "Not found"
        assert err.code == "NOT_FOUND"

    def test_error_without_code(self):
        err = ErrorResponse(detail="Something went wrong")
        assert err.code is None
