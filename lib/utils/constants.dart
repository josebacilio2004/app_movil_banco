import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Stitch Design System Palette
  static const Color primaryRed = Color(0xFFB5000B);
  static const Color primaryContainer = Color(0xFFE30613);
  static const Color secondaryBlue = Color(0xFF416182);
  static const Color tertiaryBlue = Color(0xFF0059A8);
  
  static const Color background = Color(0xFFF9F9FC);
  static const Color surface = Color(0xFFF9F9FC);
  static const Color onSurface = Color(0xFF1A1C1E);
  
  static const Color containerLow = Color(0xFFF3F3F6);
  static const Color containerHigh = Color(0xFFE8E8EB);
  static const Color containerHighest = Color(0xFFE2E2E5);
  
  static const Color textGray = Color(0xFF5E3F3B);
  static const Color outline = Color(0xFF936E69);
  static const Color errorRed = Color(0xFFBA1A1A);
  static const Color successGreen = Color(0xFF2E7D32);

  // Gradient definitions from Stitch
  static const LinearGradient bcpGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryRed, primaryContainer],
  );
}

class AppStyles {
  // Typography mapping from Stitch
  static TextStyle headline({double size = 22, Color color = AppColors.onSurface, FontWeight weight = FontWeight.bold}) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static TextStyle body({double size = 14, Color color = AppColors.onSurface, FontWeight weight = FontWeight.normal}) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    )
  ];

  static const List<BoxShadow> intenseShadow = [
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    )
  ];

  static BorderRadius radiusXL = BorderRadius.circular(12);
  static BorderRadius radius2XL = BorderRadius.circular(20);
  static BorderRadius radius3XL = BorderRadius.circular(32);
  static BorderRadius radiusFull = BorderRadius.circular(999);
}
