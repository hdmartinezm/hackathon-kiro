/// DTO for the `POST /analyze` request body.
///
/// Sends the [videoKey] (obtained from `GET /upload-url`), an optional
/// [sessionId] for traceability, and optional [profileContext] for AI context.
class AnalyzeRequestDto {
  /// S3 key of the previously uploaded video.
  final String videoKey;

  /// Optional session identifier for traceability.
  final String? sessionId;

  /// Optional profile context for AI analysis (baby age, weight, etc.).
  final Map<String, dynamic>? profileContext;

  const AnalyzeRequestDto({
    required this.videoKey,
    this.sessionId,
    this.profileContext,
  });

  /// Converts this DTO to a JSON-compatible map for the request body.
  Map<String, dynamic> toJson() {
    return {
      'video_key': videoKey,
      if (sessionId != null) 'session_id': sessionId,
      if (profileContext != null) 'profile_context': profileContext,
    };
  }
}
