import 'package:flutter/material.dart';

class AppColors {
  // --- Canonical Porcelain & Ceramic Surfaces ---
  static const Color canvas = Color(0xFFF7F4EE); // Warm oatmeal / porcelain canvas
  static const Color surfaceCard = Color(0xFFFFFFFF); // Crisp ceramic white card
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color sandCard = Color(0xFFFFFFFF);
  static const Color inset = Color(0xFFF5F2EB); // Recessed container background
  static const Color stoneTint = Color(0xFFF5F5F4); // Subtle neutral stone tint
  static const Color trackRing = Color(0xFFEDE8DE); // Concentric ring track

  // --- Obsidian Slate & Carbon Brand Palette ---
  static const Color obsidian = Color(0xFF1E232A); // Deep obsidian slate
  static const Color obsidianDark = Color(0xFF111827); // Carbon pitch
  static const Color carbon = Color(0xFF111827);
  static const Color actionDark = Color(0xFF1E232A);
  static const Color softCharcoal = Color(0xFF1E232A);
  static const Color darkButton = Color(0xFF1E232A);
  static const Color primary = Color(0xFF1E232A);
  static const Color primaryLight = Color(0xFF333A44);
  static const Color primaryDark = Color(0xFF111827);
  static const Color primaryContainer = Color(0xFFF5F2EB);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Warm Stone, Muted & Borders ---
  static const Color stone = Color(0xFF57534E); // Warm stone muted
  static const Color stoneMuted = Color(0xFF57534E);
  static const Color stoneLight = Color(0xFFE7E5E4); // Subtle stone border
  static const Color stoneBorder = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFE5E1D8);
  static const Color mutedGray = Color(0xFF8A8F98);
  static const Color textPrimary = Color(0xFF111827); // High-contrast carbon text
  static const Color textSecondary = Color(0xFF57534E); // Stone secondary text
  static const Color textMuted = Color(0xFF8A8F98); // Muted grey text

  // --- Emerald & Mint Accent System ---
  static const Color accentMint = Color(0xFF10B981); // Emerald accent
  static const Color accentMintDark = Color(0xFF047857); // Deep emerald text
  static const Color accentMintText = Color(0xFF047857);
  static const Color accentMintTint = Color(0xFFECFDF5); // Emerald-50 background
  static const Color accentMintBorder = Color(0xFFD1FAE5); // Emerald-100 border
  static const Color accentMintCircle = Color(0xFFA7F3D0); // Emerald-200 accent

  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald700 = Color(0xFF047857);

  // --- Semantic & Status ---
  static const Color accentRed = Color(0xFFDC2626);
  static const Color accentRedLight = Color(0xFFFEF2F2);
  static const Color accentGold = Color(0xFFD4A359);
  static const Color accentRose = Color(0xFF8A8F98);
  static const Color accentOlive = Color(0xFF10B981);

  // --- Backward-Compatibility Aliases (Harmonized to Unified Palette) ---
  static const Color background = Color(0xFFF7F4EE);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE5E7EB);
  static const Color surfaceHighlight = Color(0xFFF5F2EB);

  static const Color accentPeach = Color(0xFF1E232A);
  static const Color accentPeachLight = Color(0xFFF5F5F4);
  static const Color accentPeachText = Color(0xFF1E232A);

  static const Color accentSky = Color(0xFFF5F5F4);
  static const Color accentSkyDark = Color(0xFF57534E);
  static const Color accentSkyLight = Color(0xFFF5F5F4);
  static const Color accentSkyText = Color(0xFF57534E);

  static const Color accentYellow = Color(0xFFECFDF5);
  static const Color accentYellowText = Color(0xFF047857);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      fontFamily: 'Manrope',
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvas,
      primaryColor: AppColors.obsidian,
      // Strip Material tap effects for custom luxury feel
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      // Text selection matching brand colors
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: AppColors.accentMint.withValues(alpha: 0.35),
        selectionHandleColor: AppColors.accentMint,
        cursorColor: AppColors.obsidian,
      ),
      colorScheme: const ColorScheme.light(
        primary: AppColors.obsidian,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.inset,
        surface: AppColors.surfaceCard,
        onSurface: AppColors.textPrimary,
        secondary: AppColors.accentMint,
        error: AppColors.accentRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.obsidian),
        titleTextStyle: TextStyle(
          color: AppColors.obsidian,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          fontFamily: 'Manrope',
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.stoneBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          backgroundColor: AppColors.obsidian,
          foregroundColor: AppColors.onPrimary,
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
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          foregroundColor: AppColors.obsidian,
          side: const BorderSide(color: AppColors.stoneBorder, width: 1.5),
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
        ).copyWith(
          overlayColor: WidgetStateProperty.all(Colors.transparent),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceCard,
        elevation: 0,
        indicatorColor: AppColors.inset,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.obsidian, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.obsidian,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              fontFamily: 'Manrope',
            );
          }
          return const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'Manrope',
          );
        }),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  // Backward compatibility alias for darkTheme referencing the unified porcelain theme
  static ThemeData get darkTheme => theme;
  static ThemeData get lightTheme => theme;
}
