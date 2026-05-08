import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  
  static const double screenMargin = 20.0;
  static const double cardRadius = 16.0;
  static const double pillRadius = 999.0;
  static const double navHeight = 72.0;

  static const cardShadow = BoxShadow(
    color: Color(0x33000000), // #00000033
    blurRadius: 16,
    offset: Offset(0, 4), // Typical downward offset for shadow
  );
}
