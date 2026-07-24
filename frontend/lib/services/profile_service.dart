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
