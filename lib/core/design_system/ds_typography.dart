import 'package:flutter/material.dart';

class DSTypography {
  const DSTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final Color bodyColor = brightness == Brightness.dark
        ? Colors.white70
        : Colors.black87;

    return TextTheme(
      displayMedium: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.w300,
        letterSpacing: 2,
        color: bodyColor,
      ),
      headlineMedium: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: TextStyle(fontSize: 15, color: bodyColor),
      labelLarge: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
