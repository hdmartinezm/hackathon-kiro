/// Nivel de urgencia del análisis.
enum NivelUrgencia {
  normal,
  requiereAtencion,
  urgente;

  static NivelUrgencia fromString(String value) {
    switch (value.toLowerCase()) {
      case 'normal':
        return NivelUrgencia.normal;
      case 'requiere_atencion':
        return NivelUrgencia.requiereAtencion;
      case 'urgente':
        return NivelUrgencia.urgente;
      default:
        return NivelUrgencia.normal;
    }
  }

  String get label {
    switch (this) {
      case NivelUrgencia.normal:
        return 'Normal';
      case NivelUrgencia.requiereAtencion:
        return 'Requiere Atención';
      case NivelUrgencia.urgente:
        return 'Urgente';
    }
  }
}

/// Resultado del análisis de imagen/video.
class AnalysisResult {
  final NivelUrgencia status;
  final String observations;
  final String recommendations;
  final double? confidence;
  final String? cryCategory;
  final String? cryLabel;
  final double? cryConfidence;
  final String? cryRecommendation;
  final String? error;
  final String sessionId;
  final String disclaimer;

  AnalysisResult({
    required this.status,
    required this.observations,
    required this.recommendations,
    this.confidence,
    this.cryCategory,
    this.cryLabel,
    this.cryConfidence,
    this.cryRecommendation,
    this.error,
    required this.sessionId,
    this.disclaimer =
        'Esta herramienta es solo orientativa. No reemplaza la evaluación médica profesional.',
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      status: NivelUrgencia.fromString(json['status'] ?? 'normal'),
      observations: json['observations'] ?? 'Sin observaciones',
      recommendations: json['recommendations'] ?? 'Consulte a su pediatra',
      confidence: json['confidence']?.toDouble(),
      cryCategory: json['cry_category'],
      cryLabel: json['cry_label'],
      cryConfidence: json['cry_confidence']?.toDouble(),
      cryRecommendation: json['cry_recommendation'],
      error: json['error'],
      sessionId: json['session_id'] ?? '',
      disclaimer: json['disclaimer'] ??
          'Esta herramienta es solo orientativa. No reemplaza la evaluación médica profesional.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.name,
      'observations': observations,
      'recommendations': recommendations,
      'confidence': confidence,
      'cry_category': cryCategory,
      'cry_label': cryLabel,
      'cry_confidence': cryConfidence,
      'cry_recommendation': cryRecommendation,
      'error': error,
      'session_id': sessionId,
      'disclaimer': disclaimer,
    };
  }

  bool get hasCryAnalysis => cryCategory != null && cryCategory!.isNotEmpty;
}
