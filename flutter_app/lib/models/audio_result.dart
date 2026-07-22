/// Resultado del análisis de audio.
class AudioResult {
  final String category;
  final String label;
  final double confidence;
  final String recommendation;

  AudioResult({
    required this.category,
    required this.label,
    required this.confidence,
    required this.recommendation,
  });

  factory AudioResult.fromJson(Map<String, dynamic> json) {
    return AudioResult(
      category: json['cry_category'] ?? json['category'] ?? 'desconocido',
      label: json['cry_label'] ?? json['label'] ?? 'Sin clasificación',
      confidence: (json['cry_confidence'] ?? json['confidence'] ?? 0.0).toDouble(),
      recommendation: json['cry_recommendation'] ??
          json['recommendation'] ??
          'Consulte a su pediatra',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'label': label,
      'confidence': confidence,
      'recommendation': recommendation,
    };
  }
}
