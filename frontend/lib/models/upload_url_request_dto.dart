/// DTO for the `GET /upload-url` request query parameters.
///
/// Sends [mediaType] (fixed value `"video"`) and [contentType] (the actual
/// MIME type of the video to be uploaded). The backend signs the pre-signed
/// URL with this [contentType].
class UploadUrlRequestDto {
  /// Media type — fixed value `"video"`.
  final String mediaType;

  /// Actual MIME type of the video (e.g. `"video/mp4"`, `"video/webm"`).
  ///
  /// The backend will sign the pre-signed URL with this content type.
  final String contentType;

  const UploadUrlRequestDto({
    this.mediaType = 'video',
    required this.contentType,
  });

  /// Converts this DTO to a map of query parameters.
  Map<String, String> toJson() {
    return {
      'media_type': mediaType,
      'content_type': contentType,
    };
  }
}
