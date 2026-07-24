// test/models/profile_data_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:babyhealth/models/profile_data.dart';

void main() {
  group('ProfileData', () {
    test('toJson and fromJson round trip', () {
      final profile = ProfileData(
        motherName: 'Maria',
        fatherName: 'Carlos',
        babyName: 'Sofia',
        birthDate: DateTime(2026, 1, 15),
        birthWeightKg: 3.2,
        currentWeightKg: 5.5,
        birthHeightCm: 50,
        currentHeightCm: 60,
        gestationalWeeks: 39,
        pediatricianName: 'Dr. Garcia',
        pediatricianPhone: '555-1234',
        clinicName: 'Hospital Central',
      );

      final json = profile.toJson();
      final restored = ProfileData.fromJson(json);

      expect(restored.motherName, 'Maria');
      expect(restored.fatherName, 'Carlos');
      expect(restored.babyName, 'Sofia');
      expect(restored.birthDate, DateTime(2026, 1, 15));
      expect(restored.birthWeightKg, 3.2);
      expect(restored.currentWeightKg, 5.5);
      expect(restored.birthHeightCm, 50);
      expect(restored.currentHeightCm, 60);
      expect(restored.gestationalWeeks, 39);
      expect(restored.pediatricianName, 'Dr. Garcia');
      expect(restored.pediatricianPhone, '555-1234');
      expect(restored.clinicName, 'Hospital Central');
    });

    test('fromJson handles null values', () {
      final json = <String, dynamic>{};
      final profile = ProfileData.fromJson(json);

      expect(profile.motherName, isNull);
      expect(profile.babyName, isNull);
      expect(profile.birthDate, isNull);
    });

    test('ageInMonths calculates correctly', () {
      final profile = ProfileData(
        birthDate: DateTime.now().subtract(const Duration(days: 180)),
      );

      expect(profile.ageInMonths, greaterThanOrEqualTo(5));
      expect(profile.ageInMonths, lessThanOrEqualTo(7));
    });

    test('ageInMonths returns null when birthDate is null', () {
      const profile = ProfileData();
      expect(profile.ageInMonths, isNull);
    });

    test('toAnalysisContext returns relevant fields for AI', () {
      final profile = ProfileData(
        birthDate: DateTime(2026, 1, 15),
        currentWeightKg: 5.5,
        currentHeightCm: 60,
        gestationalWeeks: 38,
      );

      final context = profile.toAnalysisContext();

      expect(context, isNotNull);
      expect(context!['baby_weight_kg'], 5.5);
      expect(context['baby_height_cm'], 60);
      expect(context['gestational_weeks_at_birth'], 38);
      expect(context.containsKey('baby_age_months'), isTrue);
    });

    test('toAnalysisContext returns null when no relevant data', () {
      const profile = ProfileData();
      expect(profile.toAnalysisContext(), isNull);
    });

    test('copyWith creates modified copy', () {
      const original = ProfileData(motherName: 'Maria');
      final modified = original.copyWith(fatherName: 'Carlos');

      expect(modified.motherName, 'Maria');
      expect(modified.fatherName, 'Carlos');
    });
  });
}
