
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../features/auth/screens/auth_landing_screen.dart';

class AtlasColors {
  static const Color deepTeal = Color(0xFF123F46);
  static const Color oceanTeal = Color(0xFF28777B);
  static const Color softTeal = Color(0xFFE5F1EF);
  static const Color champagne = Color(0xFFD8B66B);
  static const Color gold = Color(0xFFB99145);
  static const Color ivory = Color(0xFFF7F8F5);
  static const Color white = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF202A30);
  static const Color secondaryText = Color(0xFF758087);
  static const Color success = Color(0xFF29966B);
  static const Color error = Color(0xFFD65A61);
  static const Color info = Color(0xFF5487D8);
  static const Color darkBackground = Color(0xFF101B20);
  static const Color darkSurface = Color(0xFF1B292F);
}

class AtlasAcademyApp extends StatelessWidget {
  const AtlasAcademyApp({super.key});

  ThemeData _lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AtlasColors.deepTeal,
        primary: AtlasColors.deepTeal,
        secondary: AtlasColors.champagne,
        surface: AtlasColors.white,
        error: AtlasColors.error,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AtlasColors.ivory,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AtlasColors.ivory,
        foregroundColor: AtlasColors.deepTeal,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AtlasColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AtlasColors.softTeal,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AtlasColors.softTeal,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(
            color: AtlasColors.oceanTeal,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AtlasColors.oceanTeal,
        brightness: Brightness.dark,
        primary: AtlasColors.oceanTeal,
        secondary: AtlasColors.champagne,
        surface: AtlasColors.darkSurface,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AtlasColors.darkBackground,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        base.textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AtlasColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AtlasColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
      themeMode: ThemeMode.system,
      home: const AuthLandingScreen(),
    );
  }
}
