# Profile Page Design

## Overview

Add a profile page to store contextual data about the baby, parents, and pediatrician. This data provides context to AI models during video/audio analysis for better health assessments.

## Requirements

- Store parent data (mother and father names)
- Store baby information (name, birth date, weight, height, gestational age at birth)
- Store pediatrician information (name, contact, clinic)
- Send profile data with analysis requests to provide AI context
- Support both English and Spanish (bilingual)
- Persist data locally on the device

## Architecture

### New Files

| File | Purpose |
|------|---------|
| `lib/models/profile_data.dart` | Data model for profile information |
| `lib/services/profile_service.dart` | Persistence and state management |
| `lib/views/profile_screen.dart` | UI form with sections |

### Data Model

```dart
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

  // Computed property
  int? get ageInMonths {
    if (birthDate == null) return null;
    final now = DateTime.now();
    return (now.year - birthDate!.year) * 12 +
           (now.month - birthDate!.month);
  }

  // JSON serialization
  Map<String, dynamic> toJson();
  factory ProfileData.fromJson(Map<String, dynamic> json);

  // copyWith for immutable updates
  ProfileData copyWith({...});
}
```

### Profile Service

Follows the existing `AppSettings` pattern using SharedPreferences:

```dart
class ProfileService extends ChangeNotifier {
  static const _profileKey = 'user_profile';
  SharedPreferences? _prefs;
  ProfileData _profile = const ProfileData();

  ProfileData get profile => _profile;
  bool get hasProfile => _profile.babyName != null;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final json = _prefs?.getString(_profileKey);
    if (json != null) {
      _profile = ProfileData.fromJson(jsonDecode(json));
    }
  }

  Future<void> save(ProfileData profile) async {
    _profile = profile;
    notifyListeners();
    await _prefs?.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clear() async {
    _profile = const ProfileData();
    notifyListeners();
    await _prefs?.remove(_profileKey);
  }
}
```

### Profile Screen UI

Three expandable sections:

1. **Parents Section**
   - Mother name (text field)
   - Father name (text field)

2. **Baby Section**
   - Baby name (text field)
   - Birth date (date picker)
   - Birth weight in kg (number field)
   - Current weight in kg (number field)
   - Birth height in cm (number field)
   - Current height in cm (number field)
   - Gestational weeks at birth (number field, 20-44 range)

3. **Pediatrician Section**
   - Pediatrician name (text field)
   - Phone number (text field)
   - Clinic name (text field)

All fields are optional. Form has a Save button that persists to SharedPreferences.

### Integration with Analysis

Extend `AnalyzeRequestDto` to include profile context:

```dart
class AnalyzeRequestDto {
  final String videoKey;
  final String? sessionId;
  final Map<String, dynamic>? profileContext;

  Map<String, dynamic> toJson() => {
    'video_key': videoKey,
    if (sessionId != null) 'session_id': sessionId,
    if (profileContext != null) 'profile_context': profileContext,
  };
}
```

The profile context sent to the API will include:
- Baby's age in months (computed from birth date)
- Current weight and height
- Gestational weeks at birth (important for preterm assessments)

Example context:
```json
{
  "profile_context": {
    "baby_age_months": 6,
    "baby_weight_kg": 7.5,
    "baby_height_cm": 65,
    "gestational_weeks_at_birth": 38
  }
}
```

### Navigation

Add profile icon to HomeScreen app bar, between settings and logout:

```dart
IconButton(
  icon: const Icon(Icons.person_rounded),
  tooltip: context.l10n.profile,
  onPressed: () => Navigator.of(context).pushNamed('/profile'),
)
```

Add route in `main.dart`:
```dart
'/profile': (_) => const ProfileScreen(),
```

### Provider Setup

Add to main.dart providers:
```dart
ChangeNotifierProvider<ProfileService>(
  create: (_) => ProfileService()..load(),
),
```

## Localization

New strings for `app_localizations.dart`:

| Key | Spanish | English |
|-----|---------|---------|
| profile | Perfil | Profile |
| parents | Padres | Parents |
| baby | Bebé | Baby |
| pediatrician | Pediatra | Pediatrician |
| motherName | Nombre de la madre | Mother's name |
| fatherName | Nombre del padre | Father's name |
| babyName | Nombre del bebé | Baby's name |
| birthDate | Fecha de nacimiento | Birth date |
| birthWeight | Peso al nacer (kg) | Birth weight (kg) |
| currentWeight | Peso actual (kg) | Current weight (kg) |
| birthHeight | Talla al nacer (cm) | Birth height (cm) |
| currentHeight | Talla actual (cm) | Current height (cm) |
| gestationalWeeks | Semanas de gestación al nacer | Gestational weeks at birth |
| pediatricianName | Nombre del pediatra | Pediatrician's name |
| pediatricianPhone | Teléfono | Phone |
| clinicName | Nombre de la clínica | Clinic name |
| saveProfile | Guardar perfil | Save profile |
| profileSaved | Perfil guardado | Profile saved |
| selectDate | Seleccionar fecha | Select date |

## Implementation Steps

1. Create `ProfileData` model with JSON serialization
2. Create `ProfileService` with SharedPreferences persistence
3. Add ProfileService to Provider setup in main.dart
4. Add localization strings to `app_localizations.dart`
5. Create `ProfileScreen` with sectioned form
6. Add profile route to main.dart
7. Add profile button to HomeScreen app bar
8. Extend `AnalyzeRequestDto` with profileContext
9. Update `AnalysisRepository` to include profile context
10. Update `AnalysisViewModel` to read profile and include in requests

## Testing

- Unit tests for `ProfileData` JSON serialization
- Unit tests for `ProfileService` save/load
- Widget tests for `ProfileScreen` form validation
- Integration test for profile data in analysis requests
