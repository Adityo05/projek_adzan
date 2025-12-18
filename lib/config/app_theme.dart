import 'package:flutter/material.dart';

/// Konfigurasi tema aplikasi Azan
/// Menggunakan desain modern dengan nuansa Islami (Tema Terang)
class AppTheme {
  // Warna utama aplikasi dengan nuansa Islami (Tema Putih & Hijau)
  // Warna Utama: Emerald Green (Zamrud)
  static const Color primaryColor = Color(0xFF00695C); // Emerald Teal
  static const Color primaryLightColor = Color(0xFF4DB6AC);
  static const Color primaryDarkColor = Color(0xFF004D40);

  // Warna Aksen: Soft Gold / Sand (Elegan)
  static const Color accentColor = Color(0xFFC5A059);
  static const Color accentLightColor = Color(0xFFFFE082);

  static const Color backgroundColor = Color(0xFFF9F9F9); // Off-white luxury
  static const Color surfaceColor = Color(0xFFFFFFFF); // Putih bersih
  static const Color cardColor = Color(0xFFFFFFFF);

  static const Color textPrimaryColor = Color(0xFF263238); // Blue Grey Dark
  static const Color textSecondaryColor = Color(0xFF78909C); // Blue Grey Light
  static const Color textInverseColor = Color(0xFFFFFFFF);

  static const Color successColor = Color(0xFF4CAF50);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color errorColor = Color(0xFFD32F2F);

  // Gradien untuk background
  // Gradien Mewah untuk Header (Emerald ke Teal Gelap)
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00695C), Color(0xFF004D40)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Colors.white, Colors.white], // Plain white
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFC5A059), Color(0xFFFDD835)],
  );

  // Gradien untuk Active Card
  static const LinearGradient activePrayerGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00695C), Color(0xFF26A69A)],
  );

  // Border radius yang lebih sophisticated
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 16.0;
  static const double borderRadiusLarge = 24.0;
  static const double borderRadiusXLarge = 32.0;

  // Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  // Shadow yang lebih soft
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0xFF00695C).withValues(alpha: 0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -5,
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Color(0xFF004D40).withValues(alpha: 0.3),
      blurRadius: 25,
      offset: const Offset(0, 10),
      spreadRadius: -5,
    ),
  ];

  // Text Styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle headingSmallInverse = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textInverseColor,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimaryColor,
  );

  static const TextStyle titleMediumInverse = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textInverseColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );

  static const TextStyle bodyMediumInverse = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textInverseColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    letterSpacing: 1.0,
  );

  static const TextStyle prayerTimeStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    fontFamily: 'monospace',
    letterSpacing: -1.0,
  );

  static const TextStyle countdownStyle = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    fontFamily: 'monospace',
    letterSpacing: 1.0,
  );

  /// Membuat ThemeData untuk aplikasi
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        error: errorColor,
        onPrimary: textInverseColor,
        onSecondary: textPrimaryColor,
        onSurface: textPrimaryColor,
        onError: textInverseColor,
        // Properti deprecated 'background' dihapus
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor, // Hijau solid
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          // Text Putih
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textInverseColor,
        ),
        iconTheme: IconThemeData(color: textInverseColor), // Icon Putih
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardTheme(
        color: cardColor,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: textInverseColor,
          elevation: 2,
          padding: const EdgeInsets.symmetric(
            horizontal: spacingLarge,
            vertical: spacingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryColor),
      ),
      iconTheme: const IconThemeData(color: primaryColor, size: 24),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryColor, // Hijau solid
        selectedItemColor: textInverseColor, // Putih solid
        unselectedItemColor: textInverseColor.withValues(
          alpha: 0.6,
        ), // Putih transparan
        type: BottomNavigationBarType.fixed,
        elevation: 16,
        showUnselectedLabels: true,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor;
          }
          return Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withValues(alpha: 0.5);
          }
          return Colors.grey.withValues(alpha: 0.3);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryColor,
        inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
        thumbColor: primaryColor,
        overlayColor: primaryColor.withValues(alpha: 0.1),
      ),
      dividerTheme: DividerThemeData(
        color: textSecondaryColor.withValues(alpha: 0.1),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimaryColor,
        contentTextStyle: bodyMedium.copyWith(color: textInverseColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(
            color: textSecondaryColor.withValues(alpha: 0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: BorderSide(
            color: textSecondaryColor.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
