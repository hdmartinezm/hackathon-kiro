/// Reads the backend API base URL from `--dart-define=API_BASE_URL`.
///
/// Usage:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://api.example.com
/// flutter build apk --dart-define=API_BASE_URL=https://api.example.com
/// flutter build web --dart-define=API_BASE_URL=https://api.example.com
/// ```
class ApiConfig {
  ApiConfig._();

  /// The default fallback used when `--dart-define=API_BASE_URL` is not provided.
  static const String _defaultBaseUrl = 'http://localhost:8000';

  /// The backend API base URL, read from compile-time define.
  ///
  /// Falls back to `http://localhost:8000` when the define is not set.
  static String get baseUrl =>
      const String.fromEnvironment('API_BASE_URL',
          defaultValue: _defaultBaseUrl);
}
