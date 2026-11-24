import 'package:flutter/material.dart';

import 'ds_colors.dart';
import 'ds_typography.dart';

class DSTheme {
  const DSTheme._();

  static ThemeData toMaterialTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: DSColors.primary,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark
          ? DSColors.darkBackground
          : DSColors.lightBackground,
      textTheme: DSTypography.textTheme(brightness),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: isDark ? DSColors.darkSurface : DSColors.lightSurface,
        foregroundColor: isDark
            ? DSColors.darkOnSurface
            : DSColors.lightOnSurface,
        elevation: 0,
      ),
    );
  }
}
