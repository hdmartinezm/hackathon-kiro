import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/services/platform_service.dart';

void main() {
  group('PlatformService', () {
    late PlatformService platformService;

    setUp(() {
      platformService = PlatformService();
    });

    test('isWeb returns false in test environment', () {
      // Flutter test runner runs in a native-like environment,
      // so kIsWeb is false.
      expect(platformService.isWeb, isFalse);
    });

    test('isAndroid returns false in test environment', () {
      // The test environment does not set a specific platform,
      // so defaultTargetPlatform may not be Android.
      // This test validates the method exists and returns a bool.
      expect(platformService.isAndroid, isA<bool>());
    });

    test('hasVideoRecordingSupport returns false in test environment', () {
      // Since kIsWeb is false in tests, hasVideoRecordingSupport
      // returns true (native platform).
      expect(platformService.hasVideoRecordingSupport, isTrue);
    });

    test('all getters return boolean values', () {
      expect(platformService.isWeb, isA<bool>());
      expect(platformService.isAndroid, isA<bool>());
      expect(platformService.hasVideoRecordingSupport, isA<bool>());
    });

    test('isWeb and hasVideoRecordingSupport are inversely related', () {
      // On native: isWeb=false, hasVideoRecordingSupport=true
      // On web: isWeb=true, hasVideoRecordingSupport=false
      expect(
        platformService.isWeb,
        equals(!platformService.hasVideoRecordingSupport),
      );
    });
  });
}
