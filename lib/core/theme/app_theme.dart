import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// BiyaheMeter design tokens — light & dark.
/// Business logic must never hardcode these; use Theme.of(context).
class AppTheme {
  AppTheme._();

  // ── Brand tokens (legacy aliases kept for existing callers) ──
  static const Color gold = Color(0xFFFFB800);
  static const Color cardBg = Color(0x33FFFFFF);
  static const Color cardBorder = Color(0x22FFFFFF);

  // ── Light palette ──
  static const Color lightBackground = Color(0xFFF4F6FA);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightAccent = Color(0xFF2563EB);
  static const Color lightSuccess = Color(0xFF16A34A);
  static const Color lightWarning = Color(0xFFF59E0B);
  static const Color lightDanger = Color(0xFFDC2626);
  static const Color lightOnSurface = Color(0xFF0F172A);
  static const Color lightOnSurfaceMuted = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // ── Dark palette ──
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkCard = Color(0xFF1B1F28);
  static const Color darkAccent = Color(0xFF60A5FA);
  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color darkWarning = Color(0xFFFBBF24);
  static const Color darkDanger = Color(0xFFEF4444);
  static const Color darkOnSurface = Color(0xFFF1F5F9);
  static const Color darkOnSurfaceMuted = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF2A3140);

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark ? darkOnSurface : lightOnSurface;
    final muted =
        brightness == Brightness.dark ? darkOnSurfaceMuted : lightOnSurfaceMuted;

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: base,
        height: 1.05,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: base,
        height: 1.1,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: base,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: base,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: base,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: base,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: base,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: base,
        height: 1.45,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: base,
        height: 1.4,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: muted,
        height: 1.35,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: base,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: muted,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        color: muted,
      ),
    );
  }

  /// Orbitron for fare / meter numerals only.
  static TextStyle fareStyle({
    required Brightness brightness,
    double fontSize = 40,
    FontWeight fontWeight = FontWeight.w700,
    Color? color,
  }) {
    final fallback =
        brightness == Brightness.dark ? darkOnSurface : lightOnSurface;
    return GoogleFonts.orbitron(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: -0.8,
      height: 1.0,
      color: color ?? fallback,
    );
  }

  static Color successOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkSuccess
          : lightSuccess;

  static Color warningOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkWarning
          : lightWarning;

  static Color dangerOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkDanger
          : lightDanger;

  static Color mutedOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkOnSurfaceMuted
          : lightOnSurfaceMuted;

  static Color borderOf(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkBorder
          : lightBorder;

  static List<BoxShadow> softShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.04),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static ThemeData get lightTheme {
    final scheme = ColorScheme.light(
      primary: lightAccent,
      onPrimary: Colors.white,
      secondary: lightSuccess,
      onSecondary: Colors.white,
      tertiary: lightWarning,
      error: lightDanger,
      onError: Colors.white,
      surface: lightCard,
      onSurface: lightOnSurface,
      surfaceContainerHighest: const Color(0xFFE8ECF4),
      outline: lightBorder,
      outlineVariant: const Color(0xFFCBD5E1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: lightBackground,
      cardColor: lightCard,
      dividerColor: lightBorder,
      textTheme: _textTheme(Brightness.light),
      iconTheme: const IconThemeData(color: lightOnSurface, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightOnSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: lightOnSurface,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return lightOnSurfaceMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lightAccent;
          return lightBorder;
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    final scheme = ColorScheme.dark(
      primary: darkAccent,
      onPrimary: darkBackground,
      secondary: darkSuccess,
      onSecondary: darkBackground,
      tertiary: darkWarning,
      error: darkDanger,
      onError: Colors.white,
      surface: darkCard,
      onSurface: darkOnSurface,
      surfaceContainerHighest: const Color(0xFF252A36),
      outline: darkBorder,
      outlineVariant: const Color(0xFF3A4254),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: darkBackground,
      cardColor: darkCard,
      dividerColor: darkBorder,
      textTheme: _textTheme(Brightness.dark),
      iconTheme: const IconThemeData(color: darkOnSurface, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkOnSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: darkOnSurface,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return darkOnSurfaceMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkAccent;
          return darkBorder;
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
