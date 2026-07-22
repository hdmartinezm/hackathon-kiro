import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/models/analyze_request_dto.dart';

void main() {
  group('AnalyzeRequestDto', () {
    test('toJson returns correct map with videoKey only', () {
      const dto = AnalyzeRequestDto(videoKey: 'sessions/abc-123/video.mp4');

      final json = dto.toJson();

      expect(json, hasLength(1));
      expect(json['video_key'], equals('sessions/abc-123/video.mp4'));
      expect(json.containsKey('session_id'), isFalse);
    });

    test('toJson returns correct map with videoKey and sessionId', () {
      const dto = AnalyzeRequestDto(
        videoKey: 'sessions/abc-123/video.mp4',
        sessionId: 'uuid-session-001',
      );

      final json = dto.toJson();

      expect(json, hasLength(2));
      expect(json['video_key'], equals('sessions/abc-123/video.mp4'));
      expect(json['session_id'], equals('uuid-session-001'));
    });

    test('toJson omits session_id when sessionId is null', () {
      const dto = AnalyzeRequestDto(
        videoKey: 'sessions/abc-123/video.mp4',
        sessionId: null,
      );

      final json = dto.toJson();

      expect(json.containsKey('session_id'), isFalse);
      expect(json['video_key'], equals('sessions/abc-123/video.mp4'));
    });

    test('toJson keys match backend contract (snake_case)', () {
      const dto = AnalyzeRequestDto(
        videoKey: 'sessions/mock-001/video.mp4',
        sessionId: 'mock-session-001',
      );

      final json = dto.toJson();

      // Verify exact keys expected by backend
      expect(json.keys, containsAll(['video_key', 'session_id']));
    });
  });
}
