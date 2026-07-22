import 'package:flutter_test/flutter_test.dart';

import 'package:babyhealth/core/api_config.dart';

void main() {
  group('ApiConfig', () {
    test('baseUrl returns default fallback http://localhost:8000', () {
      // Arrange & Act
      final baseUrl = ApiConfig.baseUrl;

      // Assert — when no --dart-define is provided, the default is used
      expect(baseUrl, equals('http://localhost:8000'));
    });

    test('baseUrl returns a non-empty String', () {
      // Arrange & Act
      final baseUrl = ApiConfig.baseUrl;

      // Assert
      expect(baseUrl, isNotEmpty);
      expect(baseUrl, isA<String>());
    });

    test('baseUrl returns a value with valid URL format', () {
      // Arrange & Act
      final baseUrl = ApiConfig.baseUrl;

      // Assert — must start with http:// or https://
      expect(
        baseUrl.startsWith('http://') || baseUrl.startsWith('https://'),
        isTrue,
        reason: 'baseUrl must be a valid HTTP(S) URL, got: $baseUrl',
      );
    });

    test('baseUrl reflects custom API_BASE_URL when provided via --dart-define',
        () {
      // This test validates both resolution paths at compile time:
      // - Default run (flutter test): validates fallback to http://localhost:8000
      // - Custom run (flutter test --dart-define=API_BASE_URL=...): validates
      //   that the custom value is used
      //
      // String.fromEnvironment is resolved at compile time, so the value
      // depends on how the test was invoked.
      const definedValue = String.fromEnvironment('API_BASE_URL');

      // Arrange & Act
      final baseUrl = ApiConfig.baseUrl;

      // Assert
      if (definedValue.isNotEmpty && definedValue != 'http://localhost:8000') {
        // Custom --dart-define was provided at compile time
        expect(baseUrl, equals(definedValue));
      } else {
        // No custom define — default fallback applies
        expect(baseUrl, equals('http://localhost:8000'));
      }
    });
  });
}
