import 'package:flutter/material.dart';

/// Central theme definitions for BabyHealth (light + dark).
///
/// Brand palette:
/// - Primary teal:   #389BB0
/// - Light teal:     #D6F2F7
/// - Accent coral:   #E87055
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF389BB0);
  static const Color primaryContainer = Color(0xFFD6F2F7);
  static const Color accent = Color(0xFFE87055);

  // Light surfaces
  static const Color lightBg = Color(0xFFFAF7F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2B2826);
  static const Color lightBorder = Color(0xFFE5E0DA);

  // Dark surfaces
  static const Color darkBg = Color(0xFF16191C);
  static const Color darkSurface = Color(0xFF1F2429);
  static const Color darkText = Color(0xFFF2EFEC);
  static const Color darkBorder = Color(0xFF39414A);

  static ThemeData get light {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primary,
        primaryContainer: primaryContainer,
        secondary: accent,
        surface: lightSurface,
        onSurface: lightText,
        outline: lightBorder,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: lightText,
        centerTitle: true,
      ),
      dividerColor: lightBorder,
    );
  }

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        primaryContainer: Color(0xFF10343D),
        onPrimaryContainer: primaryContainer,
        secondary: accent,
        surface: darkSurface,
        onSurface: darkText,
        outline: darkBorder,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: darkText,
        centerTitle: true,
      ),
      dividerColor: darkBorder,
    );
  }
}

/// Convenience brightness-aware colors resolved from the current [BuildContext].
///
/// Use these in custom-painted sections (landing, home) so they adapt to
/// light/dark automatically instead of hardcoding literal colors.
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Page background.
  Color get bg => isDark ? AppTheme.darkBg : AppTheme.lightBg;

  /// Card / section surface.
  Color get surface => isDark ? AppTheme.darkSurface : AppTheme.lightSurface;

  /// Primary text color.
  Color get textColor => isDark ? AppTheme.darkText : AppTheme.lightText;

  /// Border / outline color.
  Color get border => isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

  /// Soft teal container (chips, icon badges).
  Color get tealContainer =>
      isDark ? const Color(0xFF10343D) : AppTheme.primaryContainer;
}
