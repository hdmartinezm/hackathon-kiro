// lib/models/profile_data.dart

/// Data model for user profile information.
///
/// Contains parent, baby, and pediatrician details used for:
/// 1. Display in the profile screen
/// 2. Providing context to AI analysis
class ProfileData {
  // Parents
  final String? motherName;
  final String? fatherName;

  // Baby
  final String? babyName;
  final DateTime? birthDate;
  final double? birthWeightKg;
  final double? currentWeightKg;
  final double? birthHeightCm;
  final double? currentHeightCm;
  final int? gestationalWeeks;

  // Pediatrician
  final String? pediatricianName;
  final String? pediatricianPhone;
  final String? clinicName;

  const ProfileData({
    this.motherName,
    this.fatherName,
    this.babyName,
    this.birthDate,
    this.birthWeightKg,
    this.currentWeightKg,
    this.birthHeightCm,
    this.currentHeightCm,
    this.gestationalWeeks,
    this.pediatricianName,
    this.pediatricianPhone,
    this.clinicName,
  });

  /// Calculates baby's age in months from birth date.
  int? get ageInMonths {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return (now.year - birthDate!.year) * 12 + (now.month - birthDate!.month);
  }

  /// Returns profile context for AI analysis, or null if no relevant data.
  Map<String, dynamic>? toAnalysisContext() {
    final hasData = ageInMonths != null ||
        currentWeightKg != null ||
        currentHeightCm != null ||
        gestationalWeeks != null;

    if (!hasData) return null;

    return {
      if (ageInMonths != null) 'baby_age_months': ageInMonths,
      if (currentWeightKg != null) 'baby_weight_kg': currentWeightKg,
      if (currentHeightCm != null) 'baby_height_cm': currentHeightCm,
      if (gestationalWeeks != null) 'gestational_weeks_at_birth': gestationalWeeks,
    };
  }

  Map<String, dynamic> toJson() => {
        if (motherName != null) 'mother_name': motherName,
        if (fatherName != null) 'father_name': fatherName,
        if (babyName != null) 'baby_name': babyName,
        if (birthDate != null) 'birth_date': birthDate!.toIso8601String(),
        if (birthWeightKg != null) 'birth_weight_kg': birthWeightKg,
        if (currentWeightKg != null) 'current_weight_kg': currentWeightKg,
        if (birthHeightCm != null) 'birth_height_cm': birthHeightCm,
        if (currentHeightCm != null) 'current_height_cm': currentHeightCm,
        if (gestationalWeeks != null) 'gestational_weeks': gestationalWeeks,
        if (pediatricianName != null) 'pediatrician_name': pediatricianName,
        if (pediatricianPhone != null) 'pediatrician_phone': pediatricianPhone,
        if (clinicName != null) 'clinic_name': clinicName,
      };

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        motherName: json['mother_name'] as String?,
        fatherName: json['father_name'] as String?,
        babyName: json['baby_name'] as String?,
        birthDate: json['birth_date'] != null
            ? DateTime.parse(json['birth_date'] as String)
            : null,
        birthWeightKg: (json['birth_weight_kg'] as num?)?.toDouble(),
        currentWeightKg: (json['current_weight_kg'] as num?)?.toDouble(),
        birthHeightCm: (json['birth_height_cm'] as num?)?.toDouble(),
        currentHeightCm: (json['current_height_cm'] as num?)?.toDouble(),
        gestationalWeeks: json['gestational_weeks'] as int?,
        pediatricianName: json['pediatrician_name'] as String?,
        pediatricianPhone: json['pediatrician_phone'] as String?,
        clinicName: json['clinic_name'] as String?,
      );

  ProfileData copyWith({
    String? motherName,
    String? fatherName,
    String? babyName,
    DateTime? birthDate,
    double? birthWeightKg,
    double? currentWeightKg,
    double? birthHeightCm,
    double? currentHeightCm,
    int? gestationalWeeks,
    String? pediatricianName,
    String? pediatricianPhone,
    String? clinicName,
  }) =>
      ProfileData(
        motherName: motherName ?? this.motherName,
        fatherName: fatherName ?? this.fatherName,
        babyName: babyName ?? this.babyName,
        birthDate: birthDate ?? this.birthDate,
        birthWeightKg: birthWeightKg ?? this.birthWeightKg,
        currentWeightKg: currentWeightKg ?? this.currentWeightKg,
        birthHeightCm: birthHeightCm ?? this.birthHeightCm,
        currentHeightCm: currentHeightCm ?? this.currentHeightCm,
        gestationalWeeks: gestationalWeeks ?? this.gestationalWeeks,
        pediatricianName: pediatricianName ?? this.pediatricianName,
        pediatricianPhone: pediatricianPhone ?? this.pediatricianPhone,
        clinicName: clinicName ?? this.clinicName,
      );
}
