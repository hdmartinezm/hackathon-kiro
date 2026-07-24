# Profile Page Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a profile page for storing baby, parent, and pediatrician data that provides context to AI analysis.

**Architecture:** Local storage using SharedPreferences following the existing `AppSettings` pattern. `ProfileData` model with JSON serialization, `ProfileService` for persistence, and `ProfileScreen` with sectioned form. Profile context is included in analysis API requests.

**Tech Stack:** Flutter, Provider, SharedPreferences, dart:convert

## Global Constraints

- All text must be bilingual (Spanish/English) using `context.l10n`
- Follow existing code patterns from `AppSettings` and other views
- All fields are optional (no required validation)
- Weight in kg, height in cm, gestational weeks 20-44 range

---

## File Structure

| File | Purpose |
|------|---------|
| `lib/models/profile_data.dart` | Immutable data model with JSON serialization |
| `lib/services/profile_service.dart` | SharedPreferences persistence + ChangeNotifier |
| `lib/views/profile_screen.dart` | UI form with collapsible sections |
| `test/models/profile_data_test.dart` | Unit tests for model |
| `test/services/profile_service_test.dart` | Unit tests for service |

---

### Task 1: ProfileData Model

**Files:**
- Create: `lib/models/profile_data.dart`
- Test: `test/models/profile_data_test.dart`

**Interfaces:**
- Consumes: Nothing
- Produces: `ProfileData` class with `toJson()`, `fromJson()`, `copyWith()`, `toAnalysisContext()`

- [ ] **Step 1: Write test for JSON serialization**

```dart
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

      expect(context['baby_weight_kg'], 5.5);
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter test test/models/profile_data_test.dart`
Expected: FAIL with "Target of URI doesn't exist"

- [ ] **Step 3: Implement ProfileData model**

```dart
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter test test/models/profile_data_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add lib/models/profile_data.dart test/models/profile_data_test.dart
git commit -m "feat: add ProfileData model with JSON serialization"
```

---

### Task 2: ProfileService

**Files:**
- Create: `lib/services/profile_service.dart`
- Test: `test/services/profile_service_test.dart`

**Interfaces:**
- Consumes: `ProfileData` from Task 1
- Produces: `ProfileService` with `load()`, `save(ProfileData)`, `clear()`, `profile` getter

- [ ] **Step 1: Write test for ProfileService**

```dart
// test/services/profile_service_test.dart
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter test test/services/profile_service_test.dart`
Expected: FAIL with "Target of URI doesn't exist"

- [ ] **Step 3: Implement ProfileService**

```dart
// lib/services/profile_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/profile_data.dart';

/// Service for persisting and managing user profile data.
///
/// Follows the [AppSettings] pattern: uses [SharedPreferences] for storage
/// and extends [ChangeNotifier] for reactive UI updates.
class ProfileService extends ChangeNotifier {
  static const _profileKey = 'user_profile';

  SharedPreferences? _prefs;
  ProfileData _profile = const ProfileData();

  /// The current profile data.
  ProfileData get profile => _profile;

  /// Whether the profile has meaningful data (baby name set).
  bool get hasProfile => _profile.babyName != null;

  /// Loads persisted profile from SharedPreferences.
  ///
  /// Call once at app startup, before using [profile].
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final jsonString = _prefs?.getString(_profileKey);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _profile = ProfileData.fromJson(json);
      } catch (e) {
        debugPrint('Error loading profile: $e');
        _profile = const ProfileData();
      }
    }
  }

  /// Saves [profile] to SharedPreferences and notifies listeners.
  Future<void> save(ProfileData profile) async {
    _profile = profile;
    notifyListeners();
    final jsonString = jsonEncode(profile.toJson());
    await _prefs?.setString(_profileKey, jsonString);
  }

  /// Clears the profile data and notifies listeners.
  Future<void> clear() async {
    _profile = const ProfileData();
    notifyListeners();
    await _prefs?.remove(_profileKey);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter test test/services/profile_service_test.dart`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add lib/services/profile_service.dart test/services/profile_service_test.dart
git commit -m "feat: add ProfileService with SharedPreferences persistence"
```

---

### Task 3: Localization Strings

**Files:**
- Modify: `lib/core/app_localizations.dart`

**Interfaces:**
- Consumes: Nothing
- Produces: Profile-related localization getters in `AppLocalizations`

- [ ] **Step 1: Add profile localization strings**

Add the following getters to `AppLocalizations` class in `lib/core/app_localizations.dart`, after the existing strings (before the closing brace of the class):

```dart
  // ── Profile ──
  String get profile => _t('Perfil', 'Profile');
  String get parents => _t('Padres', 'Parents');
  String get baby => _t('Bebé', 'Baby');
  String get pediatrician => _t('Pediatra', 'Pediatrician');
  String get motherName => _t('Nombre de la madre', "Mother's name");
  String get fatherName => _t('Nombre del padre', "Father's name");
  String get babyName => _t('Nombre del bebé', "Baby's name");
  String get birthDate => _t('Fecha de nacimiento', 'Birth date');
  String get birthWeight => _t('Peso al nacer (kg)', 'Birth weight (kg)');
  String get currentWeight => _t('Peso actual (kg)', 'Current weight (kg)');
  String get birthHeight => _t('Talla al nacer (cm)', 'Birth height (cm)');
  String get currentHeight => _t('Talla actual (cm)', 'Current height (cm)');
  String get gestationalWeeks => _t('Semanas de gestación al nacer', 'Gestational weeks at birth');
  String get pediatricianName => _t('Nombre del pediatra', "Pediatrician's name");
  String get pediatricianPhone => _t('Teléfono', 'Phone');
  String get clinicName => _t('Nombre de la clínica', 'Clinic name');
  String get saveProfile => _t('Guardar perfil', 'Save profile');
  String get profileSaved => _t('Perfil guardado', 'Profile saved');
  String get selectDate => _t('Seleccionar fecha', 'Select date');
  String get babyAge => _t('Edad del bebé', "Baby's age");
  String babyAgeMonths(int months) => _t('$months meses', '$months months');
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter analyze lib/core/app_localizations.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add lib/core/app_localizations.dart
git commit -m "feat: add profile localization strings"
```

---

### Task 4: Provider Setup

**Files:**
- Modify: `lib/main.dart`

**Interfaces:**
- Consumes: `ProfileService` from Task 2
- Produces: `ProfileService` available via Provider

- [ ] **Step 1: Add ProfileService import and provider**

In `lib/main.dart`, add import at the top with other service imports:
```dart
import 'services/profile_service.dart';
```

In the `main()` function, after loading appSettings and before the authService setup, add:
```dart
  // Load profile data
  final profileService = ProfileService();
  await profileService.load();
```

In the `MultiProvider` providers list, after the `Provider<AuthService>.value(value: authService),` line, add:
```dart
        // -- Profile service (singleton) --
        ChangeNotifierProvider<ProfileService>.value(value: profileService),
```

- [ ] **Step 2: Verify the app compiles**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter analyze lib/main.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add lib/main.dart
git commit -m "feat: add ProfileService to Provider setup"
```

---

### Task 5: ProfileScreen UI

**Files:**
- Create: `lib/views/profile_screen.dart`
- Modify: `lib/main.dart` (add route)

**Interfaces:**
- Consumes: `ProfileService` via Provider, localization strings from Task 3
- Produces: `ProfileScreen` widget with form sections

- [ ] **Step 1: Create ProfileScreen**

```dart
// lib/views/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/app_localizations.dart';
import '../models/profile_data.dart';
import '../services/profile_service.dart';

/// Profile screen for entering baby, parent, and pediatrician data.
///
/// Three collapsible sections with form fields. All fields optional.
/// Saves to SharedPreferences via [ProfileService].
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late TextEditingController _motherNameController;
  late TextEditingController _fatherNameController;
  late TextEditingController _babyNameController;
  late TextEditingController _birthWeightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _birthHeightController;
  late TextEditingController _currentHeightController;
  late TextEditingController _gestationalWeeksController;
  late TextEditingController _pediatricianNameController;
  late TextEditingController _pediatricianPhoneController;
  late TextEditingController _clinicNameController;

  DateTime? _birthDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileService>().profile;

    _motherNameController = TextEditingController(text: profile.motherName);
    _fatherNameController = TextEditingController(text: profile.fatherName);
    _babyNameController = TextEditingController(text: profile.babyName);
    _birthWeightController = TextEditingController(
      text: profile.birthWeightKg?.toString() ?? '',
    );
    _currentWeightController = TextEditingController(
      text: profile.currentWeightKg?.toString() ?? '',
    );
    _birthHeightController = TextEditingController(
      text: profile.birthHeightCm?.toString() ?? '',
    );
    _currentHeightController = TextEditingController(
      text: profile.currentHeightCm?.toString() ?? '',
    );
    _gestationalWeeksController = TextEditingController(
      text: profile.gestationalWeeks?.toString() ?? '',
    );
    _pediatricianNameController = TextEditingController(
      text: profile.pediatricianName,
    );
    _pediatricianPhoneController = TextEditingController(
      text: profile.pediatricianPhone,
    );
    _clinicNameController = TextEditingController(text: profile.clinicName);
    _birthDate = profile.birthDate;
  }

  @override
  void dispose() {
    _motherNameController.dispose();
    _fatherNameController.dispose();
    _babyNameController.dispose();
    _birthWeightController.dispose();
    _currentWeightController.dispose();
    _birthHeightController.dispose();
    _currentHeightController.dispose();
    _gestationalWeeksController.dispose();
    _pediatricianNameController.dispose();
    _pediatricianPhoneController.dispose();
    _clinicNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                title: l10n.parents,
                icon: Icons.family_restroom_rounded,
                children: [
                  _buildTextField(
                    controller: _motherNameController,
                    label: l10n.motherName,
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _fatherNameController,
                    label: l10n.fatherName,
                    icon: Icons.person_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: l10n.baby,
                icon: Icons.child_care_rounded,
                children: [
                  _buildTextField(
                    controller: _babyNameController,
                    label: l10n.babyName,
                    icon: Icons.face_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildDatePicker(context),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          controller: _birthWeightController,
                          label: l10n.birthWeight,
                          icon: Icons.monitor_weight_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNumberField(
                          controller: _currentWeightController,
                          label: l10n.currentWeight,
                          icon: Icons.monitor_weight_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildNumberField(
                          controller: _birthHeightController,
                          label: l10n.birthHeight,
                          icon: Icons.straighten_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildNumberField(
                          controller: _currentHeightController,
                          label: l10n.currentHeight,
                          icon: Icons.straighten_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildNumberField(
                    controller: _gestationalWeeksController,
                    label: l10n.gestationalWeeks,
                    icon: Icons.calendar_month_rounded,
                    isInteger: true,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: l10n.pediatrician,
                icon: Icons.medical_services_rounded,
                children: [
                  _buildTextField(
                    controller: _pediatricianNameController,
                    label: l10n.pediatricianName,
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _pediatricianPhoneController,
                    label: l10n.pediatricianPhone,
                    icon: Icons.phone_rounded,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _clinicNameController,
                    label: l10n.clinicName,
                    icon: Icons.local_hospital_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    l10n.saveProfile,
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF389BB0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF389BB0), size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isInteger = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          isInteger ? RegExp(r'[0-9]') : RegExp(r'[0-9.]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context) {
    final l10n = context.l10n;

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _birthDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _birthDate = date);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: l10n.birthDate,
          prefixIcon: const Icon(Icons.calendar_today_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _birthDate != null
              ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
              : l10n.selectDate,
          style: TextStyle(
            color: _birthDate != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final profile = ProfileData(
      motherName: _motherNameController.text.isNotEmpty
          ? _motherNameController.text
          : null,
      fatherName: _fatherNameController.text.isNotEmpty
          ? _fatherNameController.text
          : null,
      babyName: _babyNameController.text.isNotEmpty
          ? _babyNameController.text
          : null,
      birthDate: _birthDate,
      birthWeightKg: double.tryParse(_birthWeightController.text),
      currentWeightKg: double.tryParse(_currentWeightController.text),
      birthHeightCm: double.tryParse(_birthHeightController.text),
      currentHeightCm: double.tryParse(_currentHeightController.text),
      gestationalWeeks: int.tryParse(_gestationalWeeksController.text),
      pediatricianName: _pediatricianNameController.text.isNotEmpty
          ? _pediatricianNameController.text
          : null,
      pediatricianPhone: _pediatricianPhoneController.text.isNotEmpty
          ? _pediatricianPhoneController.text
          : null,
      clinicName: _clinicNameController.text.isNotEmpty
          ? _clinicNameController.text
          : null,
    );

    await context.read<ProfileService>().save(profile);

    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.profileSaved),
          backgroundColor: const Color(0xFF389BB0),
        ),
      );
    }
  }
}
```

- [ ] **Step 2: Add route to main.dart**

In `lib/main.dart`, add import at top:
```dart
import 'views/profile_screen.dart';
```

Add route in the `routes:` map after `/verify-email`:
```dart
        '/profile': (_) => const ProfileScreen(),
```

- [ ] **Step 3: Verify the app compiles**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter analyze lib/views/profile_screen.dart lib/main.dart`
Expected: No errors

- [ ] **Step 4: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add lib/views/profile_screen.dart lib/main.dart
git commit -m "feat: add ProfileScreen with sectioned form"
```

---

### Task 6: Navigation from HomeScreen

**Files:**
- Modify: `lib/views/home_screen.dart`

**Interfaces:**
- Consumes: Profile route from Task 5, localization from Task 3
- Produces: Profile icon button in app bar

- [ ] **Step 1: Add profile button to app bar**

In `lib/views/home_screen.dart`, find the `actions:` list in the AppBar (around line 61) and add the profile icon button before `const SettingsControls()`:

```dart
          IconButton(
            icon: const Icon(Icons.person_rounded),
            tooltip: context.l10n.profile,
            onPressed: () => Navigator.of(context).pushNamed('/profile'),
          ),
```

- [ ] **Step 2: Verify the app compiles**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter analyze lib/views/home_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add lib/views/home_screen.dart
git commit -m "feat: add profile navigation to HomeScreen"
```

---

### Task 7: Extend AnalyzeRequestDto with Profile Context

**Files:**
- Modify: `lib/models/analyze_request_dto.dart`

**Interfaces:**
- Consumes: Nothing
- Produces: `AnalyzeRequestDto` with optional `profileContext` field

- [ ] **Step 1: Add profileContext field**

Replace the content of `lib/models/analyze_request_dto.dart` with:

```dart
/// DTO for the `POST /analyze` request body.
///
/// Sends the [videoKey] (obtained from `GET /upload-url`), an optional
/// [sessionId] for traceability, and optional [profileContext] for AI context.
class AnalyzeRequestDto {
  /// S3 key of the previously uploaded video.
  final String videoKey;

  /// Optional session identifier for traceability.
  final String? sessionId;

  /// Optional profile context for AI analysis (baby age, weight, etc.).
  final Map<String, dynamic>? profileContext;

  const AnalyzeRequestDto({
    required this.videoKey,
    this.sessionId,
    this.profileContext,
  });

  /// Converts this DTO to a JSON-compatible map for the request body.
  Map<String, dynamic> toJson() {
    return {
      'video_key': videoKey,
      if (sessionId != null) 'session_id': sessionId,
      if (profileContext != null) 'profile_context': profileContext,
    };
  }
}
```

- [ ] **Step 2: Verify the app compiles**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter analyze lib/models/analyze_request_dto.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add lib/models/analyze_request_dto.dart
git commit -m "feat: add profileContext to AnalyzeRequestDto"
```

---

### Task 8: Update AnalysisRepository to Accept Profile Context

**Files:**
- Modify: `lib/repositories/analysis_repository.dart`

**Interfaces:**
- Consumes: Updated `AnalyzeRequestDto` from Task 7
- Produces: `analyze()` and `analyzeWithGemini()` methods with optional `profileContext` parameter

- [ ] **Step 1: Add profileContext parameter to methods**

In `lib/repositories/analysis_repository.dart`, update the `analyze` method signature:

```dart
  Future<AnalysisResult> analyze(
    String videoKey, {
    String? sessionId,
    Map<String, dynamic>? profileContext,
  }) async {
    return _analyzeWithEndpoint('/analyze', videoKey,
        sessionId: sessionId, profileContext: profileContext);
  }
```

Update the `analyzeWithGemini` method signature:

```dart
  Future<AnalysisResult> analyzeWithGemini(
    String videoKey, {
    String? sessionId,
    Map<String, dynamic>? profileContext,
  }) async {
    return _analyzeWithEndpoint('/analyze-gemini', videoKey,
        sessionId: sessionId, profileContext: profileContext);
  }
```

Update the `_analyzeWithEndpoint` method signature and body:

```dart
  Future<AnalysisResult> _analyzeWithEndpoint(
    String endpoint,
    String videoKey, {
    String? sessionId,
    Map<String, dynamic>? profileContext,
  }) async {
    final requestDto = AnalyzeRequestDto(
      videoKey: videoKey,
      sessionId: sessionId,
      profileContext: profileContext,
    );
    // ... rest of method unchanged
```

- [ ] **Step 2: Verify the app compiles**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter analyze lib/repositories/analysis_repository.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add lib/repositories/analysis_repository.dart
git commit -m "feat: add profileContext parameter to AnalysisRepository"
```

---

### Task 9: Update AnalysisViewModel to Include Profile Context

**Files:**
- Modify: `lib/viewmodels/analysis_viewmodel.dart`

**Interfaces:**
- Consumes: `ProfileService`, updated `AnalysisRepository` from Task 8
- Produces: `startAnalysis()` method that includes profile context

- [ ] **Step 1: Add ProfileService dependency and include context**

In `lib/viewmodels/analysis_viewmodel.dart`:

Add import at top:
```dart
import '../models/profile_data.dart';
```

Update the class to accept optional profile context in startAnalysis. Update the `startAnalysis` method to accept profile context:

```dart
  Future<void> startAnalysis(
    CapturedMedia media, {
    AnalysisProvider provider = AnalysisProvider.bedrock,
    ProfileData? profile,
  }) async {
    _state = _state.copyWith(status: 'uploading', errorMessage: null);
    notifyListeners();

    try {
      final videoKey = await _uploadRepository.uploadMedia(media);

      _state = _state.copyWith(status: 'analyzing');
      notifyListeners();

      final profileContext = profile?.toAnalysisContext();

      final result = switch (provider) {
        AnalysisProvider.bedrock => await _analysisRepository.analyze(
            videoKey,
            profileContext: profileContext,
          ),
        AnalysisProvider.gemini => await _analysisRepository.analyzeWithGemini(
            videoKey,
            profileContext: profileContext,
          ),
      };

      _state = _state.copyWith(status: 'completed', result: result);
      notifyListeners();
    } catch (e) {
      _state = _state.copyWith(
        status: 'error',
        errorMessage: 'Analysis failed: $e',
      );
      notifyListeners();
    }
  }
```

- [ ] **Step 2: Verify the app compiles**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter analyze lib/viewmodels/analysis_viewmodel.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add lib/viewmodels/analysis_viewmodel.dart
git commit -m "feat: include profile context in analysis requests"
```

---

### Task 10: Update AnalysisScreen to Pass Profile

**Files:**
- Modify: `lib/views/analysis_screen.dart`

**Interfaces:**
- Consumes: `ProfileService` via Provider, updated `AnalysisViewModel` from Task 9
- Produces: Analysis screen that passes profile to viewmodel

- [ ] **Step 1: Add ProfileService import and pass profile**

In `lib/views/analysis_screen.dart`, add import at top:
```dart
import '../services/profile_service.dart';
```

Find where `startAnalysis` is called (look for `viewModel.startAnalysis`) and update to pass profile:

```dart
final profile = context.read<ProfileService>().profile;
viewModel.startAnalysis(
  widget.config.media,
  provider: widget.config.provider,
  profile: profile,
);
```

- [ ] **Step 2: Verify the app compiles**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter analyze lib/views/analysis_screen.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add lib/views/analysis_screen.dart
git commit -m "feat: pass profile context to analysis"
```

---

### Task 11: Run All Tests and Final Verification

**Files:**
- All files from previous tasks

**Interfaces:**
- Consumes: All implementations
- Produces: Verified working feature

- [ ] **Step 1: Run all tests**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter test`
Expected: All tests PASS

- [ ] **Step 2: Run flutter analyze**

Run: `cd /Users/hectormartinez/hackathon-Kiro/frontend && flutter analyze`
Expected: No errors

- [ ] **Step 3: Final commit with all changes**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git add -A
git commit -m "feat: complete profile page implementation

- Add ProfileData model with JSON serialization
- Add ProfileService with SharedPreferences persistence
- Add ProfileScreen with sectioned form
- Add profile navigation from HomeScreen
- Include profile context in AI analysis requests
- Add bilingual localization strings"
```

- [ ] **Step 4: Push to remote**

```bash
cd /Users/hectormartinez/hackathon-Kiro/frontend
git push
```
