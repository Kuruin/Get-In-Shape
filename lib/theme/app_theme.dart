import 'package:flutter/material.dart';

class AppColors {
  // Current active brightness flag synchronized by root MaterialApp builder
  static bool isDark = false;

  // --- Canonical Surfaces ---
  // Palette (Dark colors only):
  // --black: #000000 (deepest canvas/scaffold background)
  // --onyx: #111111 (cards, modals, navigation bar)
  // --carbon-black: #232323 (recessed insets, surface tints, track rings)
  // --graphite: #343434 (hairline borders, outlines, dividers)
  // --iron-grey: #464646 (primary action CTAs, indicator pills)
  // [Excluded lighter shades: #575757, #696969, #7a7a7a]
  static Color get canvas =>
      isDark ? const Color(0xFF000000) : const Color(0xFFF7F4EE);
  static Color get surfaceCard =>
      isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
  static Color get surfaceWhite =>
      isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
  static Color get sandCard =>
      isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
  static Color get inset =>
      isDark ? const Color(0xFF232323) : const Color(0xFFF5F2EB);
  static Color get stoneTint =>
      isDark ? const Color(0xFF232323) : const Color(0xFFF5F5F4);
  static Color get trackRing =>
      isDark ? const Color(0xFF232323) : const Color(0xFFEDE8DE);

  // --- Obsidian Slate & Carbon Brand Palette ---
  static Color get obsidian =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E232A);
  static Color get obsidianDark =>
      isDark ? const Color(0xFF000000) : const Color(0xFF111827);
  static Color get onObsidian =>
      isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static Color get carbon =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
  static Color get actionDark =>
      isDark ? const Color(0xFF343434) : const Color(0xFF1E232A);
  static Color get softCharcoal =>
      isDark ? const Color(0xFF111111) : const Color(0xFF1E232A);
  static Color get darkButton =>
      isDark ? const Color(0xFF232323) : const Color(0xFF1E232A);
  static Color get primary =>
      isDark ? const Color(0xFF343434) : const Color(0xFF1E232A);
  static Color get primaryLight =>
      isDark ? const Color(0xFF232323) : const Color(0xFF333A44);
  static Color get primaryDark =>
      isDark ? const Color(0xFF000000) : const Color(0xFF111827);
  static Color get primaryContainer =>
      isDark ? const Color(0xFF111111) : const Color(0xFFF5F2EB);
  static Color get onPrimary =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFFFFFFFF);

  // --- Warm Stone, Muted & Borders ---
  static Color get stone =>
      isDark ? const Color(0xFFA3A3A3) : const Color(0xFF57534E);
  static Color get stoneMuted =>
      isDark ? const Color(0xFF737373) : const Color(0xFF57534E);
  static Color get stoneLight =>
      isDark ? const Color(0xFF232323) : const Color(0xFFE7E5E4);
  static Color get stoneBorder =>
      isDark ? const Color(0xFF343434) : const Color(0xFFE5E7EB);
  static Color get borderSubtle =>
      isDark ? const Color(0xFF232323) : const Color(0xFFE5E1D8);
  static Color get mutedGray =>
      isDark ? const Color(0xFF737373) : const Color(0xFF8A8F98);
  static Color get textPrimary =>
      isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
  static Color get textSecondary =>
      isDark ? const Color(0xFFA3A3A3) : const Color(0xFF57534E);
  static Color get textMuted =>
      isDark ? const Color(0xFF737373) : const Color(0xFF8A8F98);

  // --- Accent System (Functional Fitness Accents & Status) ---
  static Color get accentMint =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF10B981);
  static Color get accentMintDark =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
  static Color get accentMintText =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
  static Color get accentMintTint =>
      isDark ? const Color(0xFF0E2218) : const Color(0xFFECFDF5);
  static Color get accentMintBorder =>
      isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5);
  static Color get accentMintCircle =>
      isDark ? const Color(0xFF10B981) : const Color(0xFFA7F3D0);

  static Color get emerald50 =>
      isDark ? const Color(0xFF0E2218) : const Color(0xFFECFDF5);
  static Color get emerald100 =>
      isDark ? const Color(0xFF133827) : const Color(0xFFD1FAE5);
  static Color get emerald200 =>
      isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0);
  static Color get emerald700 =>
      isDark ? const Color(0xFF34D399) : const Color(0xFF047857);

  // --- Semantic & Status ---
  static const Color accentRed = Color(0xFFDC2626);
  static Color get accentRedLight =>
      isDark ? const Color(0xFF2A0C0E) : const Color(0xFFFEF2F2);
  static const Color accentGold = Color(0xFFD4A359);
  static Color get accentRose =>
      isDark ? const Color(0xFFFB7185) : const Color(0xFF8A8F98);
  static Color get accentOlive =>
      isDark ? const Color(0xFF10B981) : const Color(0xFF10B981);

  // --- Backward-Compatibility Aliases ---
  static Color get background => canvas;
  static Color get surface => surfaceCard;
  static Color get surfaceElevated => surfaceCard;
  static Color get surfaceBorder => stoneBorder;
  static Color get surfaceHighlight => inset;

  static Color get accentPeach => obsidian;
  static Color get accentPeachLight => stoneTint;
  static Color get accentPeachText => obsidian;

  static Color get accentSky => stoneTint;
  static Color get accentSkyDark => stone;
  static Color get accentSkyLight => stoneTint;
  static Color get accentSkyText => stone;

  static Color get accentYellow => emerald50;
  static Color get accentYellowText => emerald700;
}

class AppTheme {
  static ThemeData get lightTheme => _buildTheme(Brightness.light);
  static ThemeData get darkTheme => _buildTheme(Brightness.dark);
  static ThemeData get theme => lightTheme;

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? const Color(0xFF000000) : const Color(0xFFF7F4EE);
    final surface = isDark ? const Color(0xFF111111) : const Color(0xFFFFFFFF);
    final textPrimary = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF111827);
    final textSecondary = isDark
        ? const Color(0xFFA3A3A3)
        : const Color(0xFF57534E);
    final textMuted = isDark
        ? const Color(0xFF737373)
        : const Color(0xFF8A8F98);
    final border = isDark ? const Color(0xFF343434) : const Color(0xFFE5E7EB);
    final primary = isDark ? const Color(0xFF464646) : const Color(0xFF1E232A);
    final onPrimary = const Color(0xFFFFFFFF);
    final inset = isDark ? const Color(0xFF232323) : const Color(0xFFF5F2EB);

    return ThemeData(
      fontFamily: 'Manrope',
      brightness: brightness,
      scaffoldBackgroundColor: canvas,
      primaryColor: primary,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor:
            (isDark ? const Color(0xFF464646) : AppColors.accentMint)
                .withValues(alpha: 0.35),
        selectionHandleColor: isDark
            ? const Color(0xFF464646)
            : AppColors.accentMint,
        cursorColor: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E232A),
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: inset,
        surface: surface,
        onSurface: textPrimary,
        secondary: isDark ? const Color(0xFF464646) : AppColors.accentMint,
        onSecondary: Colors.white,
        error: AppColors.accentRed,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF1E232A),
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1E232A),
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          fontFamily: 'Manrope',
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            fontFamily: 'Manrope',
          ),
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.transparent)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          foregroundColor: isDark
              ? const Color(0xFFFFFFFF)
              : const Color(0xFF1E232A),
          side: BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            fontFamily: 'Manrope',
          ),
        ).copyWith(overlayColor: WidgetStateProperty.all(Colors.transparent)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF000000) : surface,
        elevation: 0,
        indicatorColor: isDark ? const Color(0xFF232323) : inset,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E232A),
              size: 22,
            );
          }
          return IconThemeData(color: textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF1E232A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Manrope',
            );
          }
          return TextStyle(
            color: textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Manrope',
          );
        }),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          color: textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headlineMedium: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        titleLarge: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
