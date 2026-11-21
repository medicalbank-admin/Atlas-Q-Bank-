import 'package:flutter/material.dart';

import '../features/auth/screens/auth_gate.dart';

/// Central visual identity for The Atlas Academy.
///
/// Legacy colour names are retained as aliases so existing screens continue
/// to compile while the app is redesigned screen by screen.
class AtlasColors {
  // Official navy, blue, white and champagne-gold palette.
  static const Color navy = Color(0xFF071B3D);
  static const Color deepNavy = Color(0xFF0B2450);
  static const Color royalBlue = Color(0xFF174A91);
  static const Color brightBlue = Color(0xFF2868C7);
  static const Color paleBlue = Color(0xFFEAF1FC);
  static const Color champagne = Color(0xFFE4BE68);
  static const Color gold = Color(0xFFC69A3B);
  static const Color ivory = Color(0xFFF5F7FC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF17243A);
  static const Color secondaryText = Color(0xFF71809A);
  static const Color border = Color(0xFFE1E8F3);
  static const Color success = Color(0xFF21865A);
  static const Color error = Color(0xFFD64F5B);
  static const Color info = Color(0xFF3478D4);
  static const Color darkBackground = Color(0xFF06142D);
  static const Color darkSurface = Color(0xFF10264A);

  // Backward-compatible names used by existing screens.
  static const Color deepTeal = navy;
  static const Color oceanTeal = royalBlue;
  static const Color softTeal = paleBlue;
}

class AtlasAcademyApp extends StatelessWidget {
  const AtlasAcademyApp({super.key});

  ThemeData _lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AtlasColors.navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: AtlasColors.navy,
      onPrimary: AtlasColors.white,
      secondary: AtlasColors.champagne,
      onSecondary: AtlasColors.navy,
      surface: AtlasColors.white,
      onSurface: AtlasColors.charcoal,
      error: AtlasColors.error,
      outline: AtlasColors.border,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AtlasColors.ivory,
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AtlasColors.ivory,
      appBarTheme: const AppBarTheme(
        backgroundColor: AtlasColors.ivory,
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AtlasColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AtlasColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AtlasColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 17,
        ),
        hintStyle: const TextStyle(
          color: AtlasColors.secondaryText,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AtlasColors.secondaryText,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AtlasColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AtlasColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AtlasColors.royalBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AtlasColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AtlasColors.error,
            width: 1.5,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AtlasColors.navy,
          foregroundColor: AtlasColors.white,
          elevation: 0,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AtlasColors.navy,
          minimumSize: const Size(0, 50),
          side: const BorderSide(
            color: AtlasColors.royalBlue,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AtlasColors.royalBlue,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AtlasColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AtlasColors.navy,
        contentTextStyle: const TextStyle(color: AtlasColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AtlasColors.white,
        selectedItemColor: AtlasColors.navy,
        unselectedItemColor: AtlasColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  ThemeData _darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AtlasColors.royalBlue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AtlasColors.champagne,
      secondary: AtlasColors.brightBlue,
      surface: AtlasColors.darkSurface,
      onSurface: AtlasColors.white,
      error: AtlasColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AtlasColors.darkBackground,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AtlasColors.darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AtlasColors.darkBackground,
        foregroundColor: AtlasColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AtlasColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AtlasColors.champagne,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Atlas Academy',
      debugShowCheckedModeBanner: false,
      theme: _lightTheme(),
      darkTheme: _darkTheme(),
      // The reference design is primarily a bright interface with navy panels.
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}
