import 'package:flutter/material.dart';

import '../features/auth/screens/auth_gate.dart';

/// The single source of truth for The Atlas Academy visual identity.
class AtlasColors {
  static const Color navy = Color(0xFF123B68);
  static const Color deepNavy = Color(0xFF164B7A);
  static const Color royalBlue = Color(0xFF2563A6);
  static const Color brightBlue = Color(0xFF3B82C4);
  static const Color paleBlue = Color(0xFFEAF4FC);
  static const Color champagne = Color(0xFF9CC9ED);
  static const Color gold = Color(0xFF5A9BD5);
  static const Color ivory = Color(0xFFF2F7FF);
  static const Color white = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1D344A);
  static const Color secondaryText = Color(0xFF71869A);
  static const Color border = Color(0xFFDCE8F2);
  static const Color success = Color(0xFF21865A);
  static const Color error = Color(0xFFD64F5B);
  static const Color warning = Color(0xFFB7791F);
  static const Color info = Color(0xFF3478D4);
  static const Color darkBackground = Color(0xFF06142D);
  static const Color darkSurface = Color(0xFF10264A);

  // Backward-compatible aliases used by existing screens.
  static const Color deepTeal = navy;
  static const Color oceanTeal = royalBlue;
  static const Color softTeal = paleBlue;
}

/// Shared dimensions used by newly built screens and reusable components.
class AtlasDesign {
  static const double pagePadding = 20;
  static const double sectionGap = 26;
  static const double cardRadius = 20;
  static const double controlRadius = 15;
  static const double buttonHeight = 54;
}

class AtlasAcademyApp extends StatelessWidget {
  const AtlasAcademyApp({super.key});

  TextTheme _textTheme(Color textColor) {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
    ).textTheme.apply(
      bodyColor: textColor,
      displayColor: textColor,
      fontSizeFactor: 1,
    ).copyWith(
      displayLarge: const TextStyle(
        fontSize: 34,
        height: 1.12,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.1,
      ),
      displayMedium: const TextStyle(
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineLarge: const TextStyle(
        fontSize: 26,
        height: 1.2,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      ),
      headlineMedium: const TextStyle(
        fontSize: 22,
        height: 1.25,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      titleLarge: const TextStyle(
        fontSize: 19,
        height: 1.3,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: const TextStyle(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: const TextStyle(fontSize: 15, height: 1.55),
      bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
      bodySmall: const TextStyle(fontSize: 12, height: 1.45),
      labelLarge: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
      ),
    ).apply(
      // Re-apply after copyWith: replacement TextStyles otherwise lose the
      // explicit foreground colour inherited from the base theme.
      bodyColor: textColor,
      displayColor: textColor,
    );
  }

  ThemeData _lightTheme() {
    final scheme = ColorScheme.fromSeed(
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
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF2F7FF),
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: _textTheme(AtlasColors.charcoal),
      dialogTheme: const DialogThemeData(
        backgroundColor: AtlasColors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(color: AtlasColors.navy, fontSize: 20, fontWeight: FontWeight.w800),
        contentTextStyle: TextStyle(color: AtlasColors.charcoal, fontSize: 14, height: 1.5),
      ),
      primaryTextTheme: _textTheme(AtlasColors.white),
      scaffoldBackgroundColor: AtlasColors.ivory,
      appBarTheme: const AppBarTheme(
        backgroundColor: const Color(0xFFF2F7FF),
        foregroundColor: AtlasColors.navy,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: AtlasColors.navy,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.35,
        ),
      ),
      cardTheme: CardThemeData(
        color: AtlasColors.white,
        elevation: 1,
        shadowColor: Color(0x160E315A),
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AtlasDesign.cardRadius),
          side: const BorderSide(color: AtlasColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // The editable value itself must be explicit; hint/label styles do not
        // control the text entered by the user.
        // Explicit input text colour prevents white-on-white fields on devices
        // whose system brightness or inherited text theme differs.
        hintFadeDuration: const Duration(milliseconds: 150),
        floatingLabelStyle: const TextStyle(color: AtlasColors.royalBlue, fontWeight: FontWeight.w700),
        // Dropdown menu and form field labels stay dark on light surfaces.
        prefixIconColor: AtlasColors.royalBlue,
        suffixIconColor: AtlasColors.secondaryText,
        fillColor: AtlasColors.white,
        // Editable field text uses the explicit bodyLarge colour in textTheme.
        // Individual fields on dark surfaces must supply a light TextField style.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 16,
        ),
        hintStyle: const TextStyle(
          color: AtlasColors.secondaryText,
          fontSize: 14,
        ),
        labelStyle: const TextStyle(
          color: AtlasColors.secondaryText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasDesign.controlRadius),
          borderSide: const BorderSide(color: AtlasColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasDesign.controlRadius),
          borderSide: const BorderSide(color: AtlasColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasDesign.controlRadius),
          borderSide: const BorderSide(
            color: AtlasColors.royalBlue,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasDesign.controlRadius),
          borderSide: const BorderSide(color: AtlasColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasDesign.controlRadius),
          borderSide: const BorderSide(
            color: AtlasColors.error,
            width: 1.5,
          ),
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(cursorColor: AtlasColors.royalBlue, selectionColor: Color(0x332868C7), selectionHandleColor: AtlasColors.royalBlue),
      dropdownMenuTheme: const DropdownMenuThemeData(textStyle: TextStyle(color: AtlasColors.charcoal)),
      popupMenuTheme: const PopupMenuThemeData(
        color: AtlasColors.white,
        textStyle: TextStyle(color: AtlasColors.charcoal, fontSize: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AtlasColors.white,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AtlasColors.navy,
          foregroundColor: AtlasColors.white,
          disabledBackgroundColor: AtlasColors.navy.withValues(alpha: 0.45),
          disabledForegroundColor: AtlasColors.white.withValues(alpha: 0.8),
          elevation: 0,
          minimumSize: const Size(0, AtlasDesign.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasDesign.controlRadius),
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
          minimumSize: const Size(0, AtlasDesign.buttonHeight),
          side: const BorderSide(color: AtlasColors.royalBlue, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AtlasDesign.controlRadius),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AtlasColors.white,
        selectedItemColor: AtlasColors.navy,
        unselectedItemColor: AtlasColors.secondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AtlasColors.royalBlue,
        linearTrackColor: AtlasColors.paleBlue,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AtlasColors.paleBlue,
        selectedColor: AtlasColors.navy,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelStyle: const TextStyle(
          color: AtlasColors.navy,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  ThemeData _darkTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AtlasColors.royalBlue,
      brightness: Brightness.dark,
    ).copyWith(
      primary: AtlasColors.champagne,
      onPrimary: AtlasColors.navy,
      secondary: AtlasColors.brightBlue,
      surface: AtlasColors.darkSurface,
      onSurface: AtlasColors.white,
      error: AtlasColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AtlasColors.darkBackground,
    );

    return base.copyWith(
      textTheme: _textTheme(AtlasColors.white),
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
          borderRadius: BorderRadius.circular(AtlasDesign.cardRadius),
          side: const BorderSide(color: Colors.white12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AtlasColors.darkSurface,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white54),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasDesign.controlRadius),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasDesign.controlRadius),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AtlasDesign.controlRadius),
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
      themeMode: ThemeMode.light,
      home: const AuthGate(),
    );
  }
}
