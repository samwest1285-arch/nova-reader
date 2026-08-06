import 'package:flutter/material.dart';

/// Earth-tone color palette for Nova Reader.
class NovaColors {
  // Primary earth tones
  static const Color deepBrown = Color(0xFF3E2723);
  static const Color warmBrown = Color(0xFF5D4037);
  static const Color mediumBrown = Color(0xFF795548);
  static const Color lightBrown = Color(0xFFA1887F);
  static const Color tan = Color(0xFFD7CCC8);

  // Greens
  static const Color deepGreen = Color(0xFF1B5E20);
  static const Color forestGreen = Color(0xFF2E7D32);
  static const Color mossGreen = Color(0xFF558B2F);
  static const Color sageGreen = Color(0xFF8BC34A);
  static const Color paleGreen = Color(0xFFC8E6C9);

  // Golds & ambers
  static const Color deepGold = Color(0xFFF57F17);
  static const Color warmGold = Color(0xFFFFB300);
  static const Color softGold = Color(0xFFFFD54F);
  static const Color paleGold = Color(0xFFFFF8E1);

  // Terracotta & rust
  static const Color terracotta = Color(0xFFBF360C);
  static const Color rust = Color(0xFFD84315);
  static const Color burntOrange = Color(0xFFE65100);
  static const Color warmClay = Color(0xFFEF6C00);
  static const Color softClay = Color(0xFFFFCCBC);

  // Neutrals
  static const Color cream = Color(0xFFFFF3E0);
  static const Color parchment = Color(0xFFFFF8E1);
  static const Color warmWhite = Color(0xFFFFFBF0);
  static const Color charcoal = Color(0xFF212121);
  static const Color darkGray = Color(0xFF424242);

  // Accent variants for time-of-day
  static const Color morningAccent = Color(0xFFFFB300); // Bright gold
  static const Color afternoonAccent = Color(0xFF795548); // Warm brown
  static const Color sunsetAccent = Color(0xFFBF360C); // Terracotta
  static const Color nightAccent = Color(0xFF2E7D32); // Cool green
}

/// Time-of-day modes for theme adaptation.
enum TimeOfDayMode { auto, manual }

/// Represents the current time segment for theme adaptation.
enum DaySegment {
  morning,
  afternoon,
  sunset,
  night;

  /// Determines the day segment from the current system time.
  static DaySegment fromTimeOfDay(TimeOfDay time) {
    final hour = time.hour;
    if (hour >= 5 && hour < 12) return DaySegment.morning;
    if (hour >= 12 && hour < 17) return DaySegment.afternoon;
    if (hour >= 17 && hour < 20) return DaySegment.sunset;
    return DaySegment.night;
  }

  /// Returns the accent color for this day segment.
  Color get accentColor {
    switch (this) {
      case DaySegment.morning:
        return NovaColors.morningAccent;
      case DaySegment.afternoon:
        return NovaColors.afternoonAccent;
      case DaySegment.sunset:
        return NovaColors.sunsetAccent;
      case DaySegment.night:
        return NovaColors.nightAccent;
    }
  }

  /// Returns a label for this day segment.
  String get label {
    switch (this) {
      case DaySegment.morning:
        return 'Morning';
      case DaySegment.afternoon:
        return 'Afternoon';
      case DaySegment.sunset:
        return 'Sunset';
      case DaySegment.night:
        return 'Night';
    }
  }
}

/// Builds the Nova Reader theme based on the current day segment.
class NovaTheme {
  /// Creates the full [ThemeData] for the app.
  static ThemeData buildTheme({DaySegment segment = DaySegment.afternoon}) {
    final accentColor = segment.accentColor;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: NovaColors.warmBrown,
      onPrimary: Colors.white,
      secondary: accentColor,
      onSecondary: Colors.white,
      tertiary: NovaColors.deepGreen,
      onTertiary: Colors.white,
      error: NovaColors.terracotta,
      onError: Colors.white,
      surface: NovaColors.warmWhite,
      onSurface: NovaColors.charcoal,
      outline: NovaColors.lightBrown,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: NovaColors.warmWhite,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: NovaColors.deepBrown,
        foregroundColor: NovaColors.paleGold,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Georgia',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: NovaColors.paleGold,
        ),
        iconTheme: const IconThemeData(color: NovaColors.paleGold),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: NovaColors.cream,
        elevation: 2,
        shadowColor: NovaColors.mediumBrown.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: NovaColors.tan.withValues(alpha: 0.5)),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NovaColors.warmBrown,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NovaColors.warmBrown,
          side: const BorderSide(color: NovaColors.warmBrown),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Input fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: NovaColors.cream,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: NovaColors.lightBrown),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: NovaColors.tan),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        labelStyle: TextStyle(color: NovaColors.mediumBrown),
        hintStyle: TextStyle(color: NovaColors.lightBrown),
      ),

      // Bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: NovaColors.deepBrown,
        selectedItemColor: NovaColors.paleGold,
        unselectedItemColor: NovaColors.lightBrown,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),

      // Floating action button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Sliders
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: NovaColors.tan,
        thumbColor: accentColor,
        overlayColor: accentColor.withValues(alpha: 0.12),
        valueIndicatorColor: accentColor,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentColor;
          return NovaColors.lightBrown;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor.withValues(alpha: 0.5);
          }
          return NovaColors.tan;
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: NovaColors.cream,
        selectedColor: accentColor.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: NovaColors.charcoal),
        side: BorderSide(color: NovaColors.tan),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: NovaColors.warmWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: NovaColors.deepBrown,
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: NovaColors.deepBrown,
        contentTextStyle: const TextStyle(color: NovaColors.paleGold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: NovaColors.tan.withValues(alpha: 0.5),
        thickness: 1,
      ),

      // Progress indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: accentColor,
        linearTrackColor: NovaColors.tan,
      ),

      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: NovaColors.deepBrown,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: NovaColors.deepBrown,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: NovaColors.deepBrown,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: NovaColors.deepBrown,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: NovaColors.deepBrown,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: NovaColors.deepBrown,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: NovaColors.charcoal,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: NovaColors.charcoal,
        ),
        titleSmall: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: NovaColors.charcoal,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 16,
          color: NovaColors.charcoal,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 14,
          color: NovaColors.charcoal,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 12,
          color: NovaColors.darkGray,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: NovaColors.mediumBrown,
        ),
        labelMedium: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: NovaColors.mediumBrown,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 10,
          color: NovaColors.lightBrown,
        ),
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: NovaColors.mediumBrown,
        size: 24,
      ),
    );
  }
}
