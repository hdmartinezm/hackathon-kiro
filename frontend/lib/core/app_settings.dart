import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists the user's UI preferences: theme mode (light/dark) and
/// language (English/Spanish).
///
/// Defaults follow the browser/device: the initial locale comes from the
/// platform language and the initial theme follows the system brightness.
/// Once the user picks a preference it is persisted with [SharedPreferences]
/// and reused on the next visit.
class AppSettings extends ChangeNotifier {
  static const _themeKey = 'pref_theme_mode';
  static const _localeKey = 'pref_locale';

  static const supportedLocales = [Locale('es'), Locale('en')];

  SharedPreferences? _prefs;

  ThemeMode _themeMode = ThemeMode.system;
  Locale? _locale; // null → follow system/browser language

  ThemeMode get themeMode => _themeMode;
  Locale? get locale => _locale;

  /// Effective dark state given the current mode and the platform brightness.
  bool get isDark {
    if (_themeMode == ThemeMode.system) {
      return PlatformDispatcher.instance.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  /// Effective language code ('es' or 'en'), resolving system default.
  String get languageCode =>
      _locale?.languageCode ?? _systemLanguageCode();

  static String _systemLanguageCode() {
    final code =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return code == 'en' ? 'en' : 'es';
  }

  /// Loads persisted preferences (call once at startup, before runApp).
  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    final savedTheme = _prefs?.getString(_themeKey);
    switch (savedTheme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }

    final savedLocale = _prefs?.getString(_localeKey);
    if (savedLocale == 'es' || savedLocale == 'en') {
      _locale = Locale(savedLocale!);
    } else {
      _locale = null; // follow system/browser
    }
  }

  /// Sets the theme mode and persists it.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _prefs?.setString(
      _themeKey,
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
              ? 'dark'
              : 'system',
    );
  }

  /// Toggles between light and dark (resolving from the current effective mode).
  Future<void> toggleTheme() async {
    await setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Sets the language and persists it. Pass null to follow the browser.
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    if (locale == null) {
      await _prefs?.remove(_localeKey);
    } else {
      await _prefs?.setString(_localeKey, locale.languageCode);
    }
  }
}
