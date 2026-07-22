/// Configuración de la aplicación BabyHealth.
class AppConfig {
  static const String apiBaseUrl = 'https://192.168.0.97:8000';

  // Endpoints
  static const String healthEndpoint = '/health';
  static const String uploadUrlEndpoint = '/upload-url';
  static const String analyzeEndpoint = '/analyze';
  static const String analyzeImageEndpoint = '/analyze-image';

  // Constantes
  static const int maxVideoSizeMb = 50;
  static const int maxImageSizeMb = 10;
  static const int recordingDurationSeconds = 7;
  static const int uploadUrlExpirationSeconds = 300;

  // Tipos permitidos
  static const List<String> allowedVideoTypes = ['video/mp4', 'video/webm'];
  static const List<String> allowedImageTypes = [
    'image/jpeg',
    'image/png',
    'image/webp'
  ];

  // Disclaimer
  static const String disclaimer =
      'Esta herramienta es solo orientativa. No reemplaza la evaluación médica '
      'profesional. Consulte a su pediatra ante cualquier preocupación sobre la '
      'salud de su bebé.';

  // UI Constants
  static const double confidenceThreshold = 0.5;
  static const int splashDurationSeconds = 4;
}
