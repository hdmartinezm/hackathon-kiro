import 'dart:typed_data';

/// Immutable value object representing captured video media.
///
/// Contains the raw bytes, file metadata, and optional duration of a video
/// captured via recording or file selection. This class does not depend on
/// `dart:io` and is safe for use across all platforms (Android, Web).
class CapturedMedia {
  /// Raw video bytes.
  final Uint8List bytes;

  /// Original file name (e.g. `"video_20260720.mp4"`).
  final String fileName;

  /// MIME type of the video (e.g. `"video/mp4"`, `"video/webm"`).
  ///
  /// This is determined by the capture service based on the actual container
  /// produced by the platform/plugin, not hardcoded.
  final String mimeType;

  /// Duration of the video, if available.
  final Duration? duration;

  /// Creates an immutable [CapturedMedia] instance.
  ///
  /// All parameters are required except [duration].
  /// Makes a defensive copy of [bytes] to ensure immutability.
  CapturedMedia({
    required Uint8List bytes,
    required this.fileName,
    required this.mimeType,
    this.duration,
  }) : bytes = Uint8List.fromList(bytes);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CapturedMedia &&
        other.fileName == fileName &&
        other.mimeType == mimeType &&
        other.duration == duration &&
        _listEquals(other.bytes, bytes);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(bytes),
        fileName,
        mimeType,
        duration,
      );

  /// Creates a copy with optionally updated fields.
  CapturedMedia copyWith({
    Uint8List? bytes,
    String? fileName,
    String? mimeType,
    Duration? duration,
    bool clearDuration = false,
  }) {
    return CapturedMedia(
      bytes: bytes ?? this.bytes,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      duration: clearDuration ? null : (duration ?? this.duration),
    );
  }

  static bool _listEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
