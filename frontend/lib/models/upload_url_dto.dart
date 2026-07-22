/// DTO for parsing the `GET /upload-url` response from the backend.
///
/// Contains the pre-signed upload URL, expiration timestamp, S3 video key,
/// and the MIME type that the backend signed into the URL.
class UploadUrlDto {
  /// Pre-signed URL for direct PUT upload to S3.
  final String uploadUrl;

  /// ISO 8601 timestamp of when the pre-signed URL expires.
  final String expiresAt;

  /// S3 key assigned to the video. Used in `POST /analyze`.
  final String videoKey;

  /// MIME type that the backend signed into the pre-signed URL.
  ///
  /// The client MUST send this exact value as the `Content-Type` header
  /// in the PUT request to S3.
  final String contentType;

  const UploadUrlDto({
    required this.uploadUrl,
    required this.expiresAt,
    required this.videoKey,
    required this.contentType,
  });

  /// Parses an [UploadUrlDto] from the backend JSON response.
  ///
  /// Expected JSON structure:
  /// ```json
  /// {
  ///   "upload_url": "...",
  ///   "expires_at": "2026-07-20T20:00:00Z",
  ///   "video_key": "sessions/abc-123/video.mp4",
  ///   "content_type": "video/mp4"
  /// }
  /// ```
  factory UploadUrlDto.fromJson(Map<String, dynamic> json) {
    return UploadUrlDto(
      uploadUrl: json['upload_url'] as String,
      expiresAt: json['expires_at'] as String,
      videoKey: json['video_key'] as String,
      contentType: json['content_type'] as String,
    );
  }
}
