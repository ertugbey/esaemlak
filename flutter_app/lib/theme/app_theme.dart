import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium Corporate Theme for EsaEmlak
/// Airbnb/Zingat kalitesinde ferah ve profesyonel tasarım
class AppTheme {
  // ═══════════════════════════════════════════════════════════════════
  // PREMIUM COLOR PALETTE
  // ═══════════════════════════════════════════════════════════════════
  
  // Primary - Derin Gece Mavisi (Güven veren)
  static const Color primaryNavy = Color(0xFF1A237E);
  static const Color primaryNavyLight = Color(0xFF3949AB);
  static const Color primaryNavyDark = Color(0xFF0D1442);
  
  // Secondary - Altın Sarısı (Premium hissi)
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color goldAccentLight = Color(0xFFFFE44D);
  static const Color goldAccentDark = Color(0xFFCCAA00);
  
  // Teal Accent (Call-to-action)
  static const Color accentTeal = Color(0xFF00897B);
  static const Color accentTealLight = Color(0xFF4DB6AC);
  
  // Success/Error
  static const Color successGreen = Color(0xFF43A047);
  static const Color errorRed = Color(0xFFE53935);
  static const Color warningOrange = Color(0xFFFB8C00);
  
  // Light Mode Surfaces
  static const Color lightBackground = Color(0xFFF5F7FA); // Hafif mavi-gri arkaplan
  static const Color lightSurface = Color(0xFFFFFFFF);    // Kart beyazı
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightDivider = Color(0xFFCBD5E1);    // Daha belirgin kenarlık
  
  // Dark Mode Surfaces
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A1F2E);
  static const Color darkCard = Color(0xFF232B3E);
  static const Color darkDivider = Color(0xFF3A3F4B);

  // Text Colors - YÜKSEK KONTRAST
  static const Color textPrimary = Color(0xFF0F172A);     // Çok koyu (neredeyse siyah)
  static const Color textSecondary = Color(0xFF475569);   // Koyu gri (okunabilir)
  static const Color textMuted = Color(0xFF64748B);       // Orta gri (hala okunabilir)

  // Legacy compatibility
  static Color get primaryBlue => primaryNavy;
  static Color get secondaryBlue => primaryNavyLight;

  // ═══════════════════════════════════════════════════════════════════
  // TYPOGRAPHY - Poppins Font Family
  // ═══════════════════════════════════════════════════════════════════
  
  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return GoogleFonts.poppinsTextTheme(base).copyWith(
      // Display - Hero headlines
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: textColor,
        letterSpacing: -0.5,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      // Headlines
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      // Titles
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.1,
      ),
      // Body
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.5,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: 0.25,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textColor.withOpacity(0.7),
        letterSpacing: 0.4,
      ),
      // Labels
      labelLarge: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textColor.withOpacity(0.6),
        letterSpacing: 0.5,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════
  
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFE8EAF6),
        secondary: goldAccent,
        onSecondary: primaryNavyDark,
        secondaryContainer: Color(0xFFFFF8E1),
        tertiary: accentTeal,
        surface: lightSurface,
        onSurface: textPrimary,
        error: errorRed,
      ),
      
      // Backgrounds
      scaffoldBackgroundColor: lightBackground,
      
      // Typography
      textTheme: _buildTextTheme(base.textTheme, textPrimary),
      
      // AppBar
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: lightSurface,
        foregroundColor: primaryNavy,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: primaryNavy,
        ),
        iconTheme: const IconThemeData(color: primaryNavy),
      ),
      
      // Cards - Premium rounded corners
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.zero,
      ),
      
      // Buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: goldAccent,
          foregroundColor: primaryNavyDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryNavy,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: primaryNavy.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryNavy,
          side: const BorderSide(color: primaryNavy, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryNavy,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      
      // Input Fields - YÜKSEK KONTRAST TASARIM
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white, // Beyaz dolgu
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5), // Belirgin kenarlık
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryNavy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF64748B), // Okunabilir hint
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.poppins(
          color: const Color(0xFF334155), // Koyu label
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: GoogleFonts.poppins(
          color: primaryNavy,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: const Color(0xFF475569),
        suffixIconColor: const Color(0xFF475569),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F0F5),
        selectedColor: primaryNavy.withOpacity(0.15),
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
      ),
      
      // Bottom Navigation
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.1),
        indicatorColor: goldAccent.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryNavy, size: 24);
          }
          return const IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      
      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: Color(0xFFD0D0D0),
        dragHandleSize: Size(40, 4),
        showDragHandle: true,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: lightDivider,
        thickness: 1,
        space: 1,
      ),
      
      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: textSecondary,
        ),
        leadingAndTrailingTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      
      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: goldAccent,
        foregroundColor: primaryNavyDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: primaryNavyDark,
        contentTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      
      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: primaryNavy,
        unselectedLabelColor: textSecondary,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: primaryNavy, width: 3),
        ),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryNavy,
        linearTrackColor: Color(0xFFE0E0E0),
        circularTrackColor: Color(0xFFE0E0E0),
      ),
      
      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryNavy,
        inactiveTrackColor: primaryNavy.withOpacity(0.2),
        thumbColor: primaryNavy,
        overlayColor: primaryNavy.withOpacity(0.1),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════════
  
  static ThemeData get darkTheme {
    final base = ThemeData.dark();
    const darkPrimary = Color(0xFF7986CB);
    const darkGold = Color(0xFFFFD54F);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: darkPrimary,
        onPrimary: Colors.black,
        primaryContainer: Color(0xFF303F9F),
        secondary: darkGold,
        onSecondary: Colors.black,
        tertiary: accentTealLight,
        surface: darkSurface,
        onSurface: Colors.white,
        error: Color(0xFFEF5350),
      ),
      
      scaffoldBackgroundColor: darkBackground,
      
      textTheme: _buildTextTheme(base.textTheme, Colors.white),
      
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 4,
        backgroundColor: darkSurface,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkGold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          side: const BorderSide(color: darkPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: darkPrimary.withOpacity(0.2),
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCard,
        indicatorColor: darkGold.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: Color(0xFF4A4A4A),
        showDragHandle: true,
      ),
      
      dividerTheme: const DividerThemeData(
        color: darkDivider,
        thickness: 1,
      ),
      
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        subtitleTextStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Colors.grey[400],
        ),
      ),
      
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPrimary,
        linearTrackColor: Color(0xFF3A3F4B),
      ),
    );
  }
}
