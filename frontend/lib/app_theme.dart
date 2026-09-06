import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// CampusLink design system — single source of truth.
///
/// Modern gradient style: indigo→violet brand gradient, soft surfaces,
/// rounded cards, gentle shadows. Light + dark, follows the system.
class AppTheme {
  AppTheme._();

  // ---------- Brand palette ----------
  static const Color brandIndigo = Color(0xFF4F46E5);
  static const Color brandViolet = Color(0xFF7C3AED);
  static const Color brandPink = Color(0xFFEC4899);
  static const Color brandCyan = Color(0xFF06B6D4);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandIndigo, brandViolet],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandViolet, brandPink],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981)],
  );

  // Semantic colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);

  // Role colors
  static const Color adminColor = Color(0xFF8B5CF6);
  static const Color teacherColor = Color(0xFF10B981);
  static const Color studentColor = Color(0xFFF59E0B);
  static const Color guestColor = Color(0xFF3B82F6);

  // ---------- Surfaces ----------
  static const Color darkBackground = Color(0xFF0F1117);
  static const Color darkSurface = Color(0xFF171A21);
  static const Color darkCard = Color(0xFF1E2230);
  static const Color darkBorder = Color(0xFF2A2F3E);

  static const Color lightBackground = Color(0xFFF6F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE7E9F2);

  // ---------- Radii / spacing ----------
  static const double radiusS = 10;
  static const double radiusM = 16;
  static const double radiusL = 24;
  static const double radiusXL = 32;

  static List<BoxShadow> softShadow(Color color, {bool dark = false}) => [
        BoxShadow(
          color: dark ? Colors.black.withOpacity(0.35) : color.withOpacity(0.18),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ];

  /// Decorated container with the brand gradient (for headers, buttons, FABs).
  static BoxDecoration gradientBox({double radius = radiusM, List<double>? stops}) {
    return BoxDecoration(
      gradient: brandGradient,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: softShadow(brandIndigo),
    );
  }

  /// Standard card decoration that adapts to brightness.
  static BoxDecoration cardBox(ThemeData theme, {double radius = radiusM}) {
    final dark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: dark ? darkCard : lightSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: dark ? darkBorder : lightBorder),
      boxShadow: [
        BoxShadow(
          color: dark ? Colors.black.withOpacity(0.25) : const Color(0xFF4F46E5).withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ---------- Themes ----------
  static ThemeData get darkTheme => _build(Brightness.dark);
  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brandIndigo,
      brightness: brightness,
    ).copyWith(
      primary: brandIndigo,
      secondary: brandViolet,
      tertiary: brandPink,
      error: errorColor,
      surface: isDark ? darkSurface : lightSurface,
      surfaceContainerHighest: isDark ? darkCard : const Color(0xFFEEF0F8),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark ? darkBackground : lightBackground,
      primaryColor: brandIndigo,
      splashFactory: InkRipple.splashFactory,

      // AppBar: clean surface with bottom border
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? darkBackground : lightSurface,
        foregroundColor: isDark ? Colors.white : const Color(0xFF111827),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: isDark ? Colors.white : const Color(0xFF111827),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF111827)),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: isDark ? darkCard : lightSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
          side: BorderSide(color: isDark ? darkBorder : lightBorder),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? darkCard : const Color(0xFFF2F4FA),
        hintStyle: TextStyle(color: (isDark ? Colors.white : Colors.black).withOpacity(0.35)),
        labelStyle: TextStyle(color: (isDark ? Colors.white70 : Colors.black54)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: BorderSide(color: isDark ? darkBorder : lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: brandIndigo, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: errorColor, width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: errorColor, width: 1.6),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandIndigo,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
          textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandIndigo,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandIndigo,
          side: const BorderSide(color: brandIndigo, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: brandIndigo,
          textStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? darkCard : const Color(0xFFF0F1F9),
        selectedColor: brandIndigo,
        labelStyle: TextStyle(color: isDark ? Colors.white : const Color(0xFF111827)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? darkSurface : lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusL)),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkCard : const Color(0xFF1F2937),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? darkSurface : lightSurface,
        selectedItemColor: brandIndigo,
        unselectedItemColor: isDark ? Colors.white38 : Colors.black38,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 11.5),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? darkSurface : lightSurface,
        indicatorColor: brandIndigo.withOpacity(0.12),
        elevation: 0,
        height: 68,
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brandIndigo,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
      ),

      dividerTheme: DividerThemeData(
        color: isDark ? darkBorder : lightBorder,
        thickness: 1,
        space: 1,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : (isDark ? Colors.white38 : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brandIndigo : (isDark ? darkBorder : lightBorder),
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? brandIndigo : Colors.transparent,
        ),
        side: BorderSide(color: isDark ? Colors.white38 : Colors.black26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(color: brandIndigo),

      tabBarTheme: TabBarThemeData(
        labelColor: brandIndigo,
        unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),

      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusM)),
        iconColor: isDark ? Colors.white70 : Colors.black54,
      ),

      textTheme: (isDark ? Typography.material2021().white : Typography.material2021().black)
          .apply(
        bodyColor: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827),
        displayColor: isDark ? Colors.white : const Color(0xFF111827),
      )
          .copyWith(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.3),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        headlineSmall: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w400, height: 1.45),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
        bodySmall: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, height: 1.35),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}
