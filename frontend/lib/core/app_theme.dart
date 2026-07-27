import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme definitions for BabyHealth (light + dark).
///
/// Mirrors the marketing landing "look & feel":
/// - Trust teal:    #4B9B9B (dark #2B7A7A)
/// - Warmth coral:  #DF7B5E
/// - Warm off-white background #FAF7F4 / dark #14110F
/// - Typography: Georgia serif headings, Inter body, Space Grotesk accent.
class AppTheme {
  AppTheme._();

  // Brand
  static const Color primary = Color(0xFF4B9B9B); // trust
  static const Color primaryDark = Color(0xFF2B7A7A); // trust-dark
  static const Color primaryContainer = Color(0xFFC8E8E8); // trust-light
  static const Color accent = Color(0xFFDF7B5E); // warmth
  static const Color accentLight = Color(0xFFF0B9A8);

  // Aurora accents
  static const Color auroraTeal = Color(0xFF73D2D2);
  static const Color auroraMint = Color(0xFFA7F3D0);
  static const Color auroraCoral = Color(0xFFF7A38B);
  static const Color auroraPeach = Color(0xFFFFD5C2);

  // Light surfaces
  static const Color lightBg = Color(0xFFFAF7F4);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF2A2A28); // heading
  static const Color lightBody = Color(0xFF4A4946);
  static const Color lightMuted = Color(0xFF7B7974);
  static const Color lightBorder = Color(0xFFE8E1D9);

  // Dark surfaces
  static const Color darkBg = Color(0xFF14110F);
  static const Color darkSurface = Color(0xFF1E1A17);
  static const Color darkText = Color(0xFFF2EFEC);
  static const Color darkBody = Color(0xFFC9C4BE);
  static const Color darkMuted = Color(0xFF8A857E);
  static const Color darkBorder = Color(0xFF2E2823);

  /// Serif family for headings (web-safe, matches landing's Georgia serif).
  static const String serifFamily = 'Georgia';

  /// Accent font (Space Grotesk) for eyebrow/label text.
  static TextStyle accentText({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// Serif heading style helper.
  static TextStyle serif({
    double? fontSize,
    FontWeight fontWeight = FontWeight.bold,
    Color? color,
    double height = 1.15,
  }) =>
      TextStyle(
        fontFamily: serifFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      );

  static ThemeData get light => _base(
        brightness: Brightness.light,
        bg: lightBg,
        colorScheme: const ColorScheme.light(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: primaryContainer,
          onPrimaryContainer: primaryDark,
          secondary: accent,
          onSecondary: Colors.white,
          surface: lightSurface,
          onSurface: lightText,
          outline: lightBorder,
        ),
        foreground: lightText,
      );

  static ThemeData get dark => _base(
        brightness: Brightness.dark,
        bg: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          onPrimary: Colors.white,
          primaryContainer: Color(0xFF10343D),
          onPrimaryContainer: primaryContainer,
          secondary: accent,
          onSecondary: Colors.white,
          surface: darkSurface,
          onSurface: darkText,
          outline: darkBorder,
        ),
        foreground: darkText,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color bg,
    required ColorScheme colorScheme,
    required Color foreground,
  }) {
    final baseTheme = ThemeData(brightness: brightness, useMaterial3: true);
    return baseTheme.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: colorScheme,
      // Inter as the default body/UI font.
      textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme).apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: foreground,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      dividerColor: colorScheme.outline,
    );
  }
}

/// Convenience brightness-aware colors resolved from the current [BuildContext].
extension AppColorsX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Page background.
  Color get bg => isDark ? AppTheme.darkBg : AppTheme.lightBg;

  /// Card / section surface.
  Color get surface => isDark ? AppTheme.darkSurface : AppTheme.lightSurface;

  /// Primary (heading) text color.
  Color get textColor => isDark ? AppTheme.darkText : AppTheme.lightText;

  /// Body text color.
  Color get bodyColor => isDark ? AppTheme.darkBody : AppTheme.lightBody;

  /// Muted text color.
  Color get mutedColor => isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

  /// Border / outline color.
  Color get border => isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

  /// Soft teal container (chips, icon badges).
  Color get tealContainer =>
      isDark ? const Color(0xFF10343D) : AppTheme.primaryContainer;
}
