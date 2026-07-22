import '../models/captured_media.dart';
import '../models/mime_validator.dart';
import '../models/upload_url_dto.dart';
import '../models/upload_url_request_dto.dart';
import '../services/http_client.dart';
import '../services/storage_service.dart';

/// Coordinates the upload flow: MIME validation, pre-signed URL request, and S3 upload.
///
/// Injects [HttpClient] for API calls and [StorageService] for the actual
/// S3 PUT. Validates the video MIME type against the backend-accepted set
/// before requesting a pre-signed URL.
class UploadRepository {
  final HttpClient _httpClient;
  final StorageService _storageService;

  /// MIME types accepted by the backend for video upload.
  ///
  /// Defined in `docs/api-contracts.md`. Currently:
  /// - `video/mp4` (Android recording, file picker)
  /// - `video/webm` (Web recording, file picker)
  static const List<String> acceptedMimeTypes = [
    'video/mp4',
    'video/webm',
  ];

  UploadRepository({
    required HttpClient httpClient,
    required StorageService storageService,
  })  : _httpClient = httpClient,
        _storageService = storageService;

  /// Requests a pre-signed upload URL for the given [contentType].
  ///
  /// Calls `GET /upload-url?media_type=video&content_type={contentType}`.
  /// Throws [HttpClientException] on HTTP errors.
  Future<UploadUrlDto> getUploadUrl(String contentType) async {
    final requestDto = UploadUrlRequestDto(contentType: contentType);

    final response = await _httpClient.get(
      '/upload-url',
      queryParams: requestDto.toJson(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpClientException(
        message: 'Failed to get upload URL with HTTP ${response.statusCode}',
        statusCode: response.statusCode,
        body: response.body,
      );
    }

    return UploadUrlDto.fromJson(response.jsonBody);
  }

  /// Uploads [media] to S3 and returns the assigned `video_key`.
  ///
  /// Steps:
  /// 1. Validates [media.mimeType] against [acceptedMimeTypes].
  /// 2. Requests a pre-signed URL via [getUploadUrl] with the media's MIME.
  /// 3. Delegates the actual PUT to [StorageService.uploadMedia].
  /// 4. Returns the `videoKey` from the [UploadUrlDto].
  ///
  /// Throws [ArgumentError] if the MIME type is not accepted.
  /// Throws [HttpClientException] on HTTP or upload errors.
  Future<String> uploadMedia(CapturedMedia media) async {
    validateVideoMimeType(media.mimeType, acceptedMimeTypes);

    final uploadUrlDto = await getUploadUrl(media.mimeType);

    await _storageService.uploadMedia(uploadUrlDto, media);

    return uploadUrlDto.videoKey;
  }
}
