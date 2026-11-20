import 'package:flutter/material.dart';

class AtlasSpacing {
  AtlasSpacing._();

  // Standard spacing scale
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  // Screen layout
  static const double screenPadding = 22;
  static const double tabletPadding = 32;
  static const double desktopPadding = 40;

  static const double maxContentWidth = 1200;
  static const double maxFormWidth = 460;
}

class AtlasRadius {
  AtlasRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 30;
  static const double pill = 100;

  static BorderRadius get small =>
      BorderRadius.circular(sm);

  static BorderRadius get medium =>
      BorderRadius.circular(md);

  static BorderRadius get large =>
      BorderRadius.circular(lg);

  static BorderRadius get extraLarge =>
      BorderRadius.circular(xl);

  static BorderRadius get rounded =>
      BorderRadius.circular(pill);
}

class AtlasShadows {
  AtlasShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0A123F46),
      blurRadius: 18,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x10123F46),
      blurRadius: 28,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> premium = [
    BoxShadow(
      color: Color(0x1A123F46),
      blurRadius: 36,
      offset: Offset(0, 14),
    ),
    BoxShadow(
      color: Color(0x08D8B66B),
      blurRadius: 12,
      offset: Offset(0, 3),
    ),
  ];
}

class AtlasMotion {
  AtlasMotion._();

  static const Duration fast =
      Duration(milliseconds: 180);

  static const Duration normal =
      Duration(milliseconds: 280);

  static const Duration smooth =
      Duration(milliseconds: 400);

  static const Curve curve = Curves.easeInOutCubic;

  static const Curve entrance = Curves.easeOutCubic;
}
