import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:babyhealth/models/profile_data.dart';
import 'package:babyhealth/services/profile_service.dart';

void main() {
  group('ProfileService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial profile is empty', () async {
      final service = ProfileService();
      await service.load();

      expect(service.profile.babyName, isNull);
      expect(service.hasProfile, isFalse);
    });

    test('save persists profile data', () async {
      final service = ProfileService();
      await service.load();

      final profile = ProfileData(
        babyName: 'Sofia',
        currentWeightKg: 5.5,
      );
      await service.save(profile);

      expect(service.profile.babyName, 'Sofia');
      expect(service.profile.currentWeightKg, 5.5);
      expect(service.hasProfile, isTrue);
    });

    test('load restores persisted profile', () async {
      final service1 = ProfileService();
      await service1.load();
      await service1.save(const ProfileData(babyName: 'Sofia'));

      final service2 = ProfileService();
      await service2.load();

      expect(service2.profile.babyName, 'Sofia');
    });

    test('clear removes profile data', () async {
      final service = ProfileService();
      await service.load();
      await service.save(const ProfileData(babyName: 'Sofia'));
      await service.clear();

      expect(service.profile.babyName, isNull);
      expect(service.hasProfile, isFalse);
    });

    test('notifies listeners on save', () async {
      final service = ProfileService();
      await service.load();

      var notified = false;
      service.addListener(() => notified = true);

      await service.save(const ProfileData(babyName: 'Sofia'));

      expect(notified, isTrue);
    });
  });
}
