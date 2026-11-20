import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AtlasColors {
  AtlasColors._();

  // Official brand palette
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

  ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AtlasColors.oceanTeal,
      brightness: Brightness.light,
    ).copyWith(
      primary: AtlasColors.deepTeal,
      secondary: AtlasColors.champagne,
      surface: AtlasColors.white,
      error: AtlasColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AtlasColors.ivory,

      textTheme: GoogleFonts.plusJakartaSansTextTheme(),

      appBarTheme: const AppBarTheme(
        backgroundColor: AtlasColors.ivory,
        foregroundColor: AtlasColors.deepTeal,
        elevation: 0,
        centerTitle: false,
      ),

      cardTheme: CardThemeData(
        color: AtlasColors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(
            color: Color(0xFFE8ECEA),
            width: 0.8,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AtlasColors.deepTeal,
          foregroundColor: AtlasColors.white,
          elevation: 0,
          minimumSize: const Size(0, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F4F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 19,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xFFE5EAE8),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AtlasColors.oceanTeal,
            width: 1.5,
          ),
        ),
      ),

      dividerColor: const Color(0xFFE8ECEA),

      iconTheme: const IconThemeData(
        color: AtlasColors.deepTeal,
      ),
    );
  }

  ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AtlasColors.oceanTeal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF79B9B7),
      secondary: AtlasColors.champagne,
      surface: AtlasColors.darkSurface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AtlasColors.darkBackground,

      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),

      cardTheme: CardThemeData(
        color: AtlasColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(
            color: Color(0xFF34464C),
          ),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AtlasColors.darkBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AtlasColors.oceanTeal,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      dividerColor: const Color(0xFF34464C),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Atlas Academy',
      debugShowCheckedModeBanner: false,

      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,

      home: const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AtlasColors.oceanTeal,
          ),
        ),
      ),
    );
  }
}
