import '../config/app_config.dart';

/// Filtro de confianza para resultados de clasificación.
/// Si la confianza es menor al umbral, se marca como "desconocido".
class ConfidenceFilter {
  final double threshold;

  ConfidenceFilter({this.threshold = AppConfig.confidenceThreshold});

  /// Verifica si el nivel de confianza es aceptable.
  bool isConfident(double confidence) {
    return confidence >= threshold;
  }

  /// Filtra el resultado: si no es confiable, retorna categoría 'desconocido'.
  String filterCategory(String category, double confidence) {
    if (isConfident(confidence)) {
      return category;
    }
    return 'desconocido';
  }

  /// Filtra el label: si no es confiable, retorna mensaje genérico.
  String filterLabel(String label, double confidence) {
    if (isConfident(confidence)) {
      return label;
    }
    return 'No se pudo clasificar con certeza';
  }
}
