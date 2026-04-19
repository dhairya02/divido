import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Divido brand tokens — kept in sync with [packages/ui-assets/README.md] and
/// [web/app/globals.css]. Treat these as the single source of truth on mobile.
class BrandColors {
  BrandColors._();

  /// Indigo blue used for the primary surface (header bar, selected chips,
  /// FAB hover ring on the web).
  static const Color primary = Color(0xFF6F8BFF);

  /// Lime / pale-green accent used for the wordmark.
  static const Color accent = Color(0xFFE6FDA3);

  /// Secondary purple used by `.btn-primary` on the web (call-to-action).
  static const Color secondary = Color(0xFFC77DFF);

  /// Soft lavender used for muted accents.
  static const Color muted = Color(0xFFB794D9);

  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF111827);

  static const Color foregroundLight = Color(0xFF171717);
  static const Color foregroundDark = Color(0xFFEDEDED);

  // Semantic colors mirroring the web's tailwind palette.
  static const Color success = Color(0xFF065F46);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  static const Color borderLight = Color(0x1A000000); // rgba(0,0,0,0.10)
  static const Color borderDark = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
}

/// Typography — EB Garamond (loaded from Google Fonts at runtime).
TextTheme brandTextTheme(Brightness brightness) {
  final base = brightness == Brightness.light
      ? ThemeData.light().textTheme
      : ThemeData.dark().textTheme;
  return GoogleFonts.ebGaramondTextTheme(base);
}

/// Build the full Divido [ThemeData] for the given brightness.
ThemeData buildBrandTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: BrandColors.primary,
    brightness: brightness,
    primary: BrandColors.primary,
    onPrimary: Colors.white,
    secondary: BrandColors.secondary,
    onSecondary: Colors.white,
    tertiary: BrandColors.accent,
    onTertiary: BrandColors.foregroundLight,
    error: BrandColors.error,
    onError: Colors.white,
    surface: isDark ? BrandColors.backgroundDark : BrandColors.backgroundLight,
    onSurface:
        isDark ? BrandColors.foregroundDark : BrandColors.foregroundLight,
  );

  final textTheme = brandTextTheme(brightness);

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,
    primaryTextTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: BrandColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.ebGaramond(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.w600,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? BrandColors.borderDark : BrandColors.borderLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isDark ? BrandColors.borderDark : BrandColors.borderLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: BrandColors.primary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BrandColors.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.ebGaramond(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: BrandColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.ebGaramond(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: BrandColors.primary,
        textStyle: GoogleFonts.ebGaramond(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor:
            isDark ? BrandColors.foregroundDark : BrandColors.foregroundLight,
        side: BorderSide(
          color: isDark ? BrandColors.borderDark : BrandColors.borderLight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: BrandColors.secondary,
      foregroundColor: Colors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
      selectedColor: BrandColors.primary,
      labelStyle: GoogleFonts.ebGaramond(
        color: isDark ? BrandColors.foregroundDark : BrandColors.foregroundLight,
      ),
      secondaryLabelStyle: GoogleFonts.ebGaramond(color: Colors.white),
      side: BorderSide(
        color: isDark ? BrandColors.borderDark : BrandColors.borderLight,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? BrandColors.borderDark : BrandColors.borderLight,
        ),
      ),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: BrandColors.primary,
      textColor:
          isDark ? BrandColors.foregroundDark : BrandColors.foregroundLight,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      indicatorColor: BrandColors.primary.withValues(alpha: 0.18),
      iconTheme: WidgetStatePropertyAll(
        IconThemeData(color: scheme.onSurface),
      ),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.ebGaramond(
          color: scheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: isDark ? BrandColors.borderDark : BrandColors.borderLight,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: BrandColors.primary,
      contentTextStyle:
          GoogleFonts.ebGaramond(color: Colors.white, fontWeight: FontWeight.w500),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
