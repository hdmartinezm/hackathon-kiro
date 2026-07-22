/// DTO for the `POST /analyze` request body.
///
/// Sends the [videoKey] (obtained from `GET /upload-url`) and an optional
/// [sessionId] for traceability.
class AnalyzeRequestDto {
  /// S3 key of the previously uploaded video.
  final String videoKey;

  /// Optional session identifier for traceability.
  final String? sessionId;

  const AnalyzeRequestDto({
    required this.videoKey,
    this.sessionId,
  });

  /// Converts this DTO to a JSON-compatible map for the request body.
  Map<String, dynamic> toJson() {
    return {
      'video_key': videoKey,
      if (sessionId != null) 'session_id': sessionId,
    };
  }
}
