import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/models/upload_url_request_dto.dart';

void main() {
  group('UploadUrlRequestDto', () {
    test('toJson returns correct map with default mediaType', () {
      final dto = UploadUrlRequestDto(contentType: 'video/mp4');

      final json = dto.toJson();

      expect(json, hasLength(2));
      expect(json['media_type'], equals('video'));
      expect(json['content_type'], equals('video/mp4'));
    });

    test('toJson returns correct map with custom mediaType', () {
      final dto = UploadUrlRequestDto(
        mediaType: 'video',
        contentType: 'video/webm',
      );

      final json = dto.toJson();

      expect(json['media_type'], equals('video'));
      expect(json['content_type'], equals('video/webm'));
    });

    test('toJson keys match backend contract (snake_case)', () {
      final dto = UploadUrlRequestDto(contentType: 'video/mp4');

      final json = dto.toJson();

      expect(json.keys, containsAll(['media_type', 'content_type']));
    });

    test('contentType reflects the actual video MIME type', () {
      final dtoMp4 = UploadUrlRequestDto(contentType: 'video/mp4');
      final dtoWebm = UploadUrlRequestDto(contentType: 'video/webm');

      expect(dtoMp4.toJson()['content_type'], equals('video/mp4'));
      expect(dtoWebm.toJson()['content_type'], equals('video/webm'));
    });
  });
}
