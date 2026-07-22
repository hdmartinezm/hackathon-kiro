/// Validates that a video MIME type belongs to the set accepted by the backend.
///
/// Throws an [ArgumentError] if [mimeType] is not in [acceptedMimes].
/// This is invoked before requesting a pre-signed upload URL to fail fast
/// on incompatible formats.
///
/// Example:
/// ```dart
/// validateVideoMimeType('video/mp4', ['video/mp4', 'video/webm']); // OK
/// validateVideoMimeType('video/avi', ['video/mp4', 'video/webm']); // throws
/// ```
void validateVideoMimeType(
  String mimeType,
  List<String> acceptedMimes,
) {
  if (!acceptedMimes.contains(mimeType)) {
    throw ArgumentError(
      'MIME type "$mimeType" is not in the accepted set: '
      '${acceptedMimes.join(", ")}',
    );
  }
}
