/// Enum representing the severity status of an analysis result.
///
/// Maps to the backend's `status` field values:
/// - `"normal"` → [normal]
/// - `"requiere_atencion"` → [requiereAtencion]
/// - `"urgente"` → [urgente]
enum AnalysisStatus {
  /// No concerning findings detected.
  normal,

  /// Some signs detected that require attention.
  requiereAtencion,

  /// Critical findings detected — immediate medical attention recommended.
  urgente;

  /// Creates an [AnalysisStatus] from its backend JSON string value.
  ///
  /// Throws [ArgumentError] if [value] is not a recognized status.
  static AnalysisStatus fromJson(String value) {
    switch (value) {
      case 'normal':
        return AnalysisStatus.normal;
      case 'requiere_atencion':
        return AnalysisStatus.requiereAtencion;
      case 'urgente':
        return AnalysisStatus.urgente;
      default:
        throw ArgumentError('Unknown AnalysisStatus value: $value');
    }
  }

  /// Returns the JSON string representation for this status.
  String toJson() {
    switch (this) {
      case AnalysisStatus.normal:
        return 'normal';
      case AnalysisStatus.requiereAtencion:
        return 'requiere_atencion';
      case AnalysisStatus.urgente:
        return 'urgente';
    }
  }
}
