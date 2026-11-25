import 'package:flutter/material.dart';

// El compiler v2 emite design_tokens.dart; aquí solo se construye el objeto
// Flutter. Las reglas de tokens siguen en token_validation.dart.
import 'generated/design_tokens.dart' as generated;

/// Valores puramente visuales de una skin. Nunca contiene lógica de cálculo.
@immutable
class SkinTokens {
  const SkinTokens({
    required this.segmentOn,
    required this.displayBackground,
    required this.displayBorder,
    required this.displayRadius,
    required this.displayPadding,
    required this.digitWidth,
    required this.digitHeight,
    this.keyBackground,
    this.keyForeground,
    this.keyBorder,
    this.keyRadius,
    required this.keyPadding,
    required this.keyMinHeight,
    required this.screenPadding,
    required this.keyboardHeight,
  });

  final Color segmentOn;
  final Color displayBackground;
  final Color displayBorder;
  final double displayRadius;
  final EdgeInsetsGeometry displayPadding;
  final double digitWidth;
  final double digitHeight;
  final Color? keyBackground;
  final Color? keyForeground;
  final Color? keyBorder;
  final double? keyRadius;
  final double keyPadding;
  final double keyMinHeight;
  final double screenPadding;
  final double keyboardHeight;

  /// Skin `default` de design/app.design.json, generada por el compiler v2.
  ///
  /// V9 la activará como default de la app y actualizará los goldens; hoy es
  /// aditiva para no romper los tests heredados de 44 dp.
  static const SkinTokens generatedDefault = SkinTokens(
    segmentOn: Color(generated.generatedDefaultSegmentOn),
    displayBackground: Color(generated.generatedDefaultDisplayBackground),
    displayBorder: Color(generated.generatedDefaultDisplayBorder),
    displayRadius: generated.generatedDefaultDisplayRadius,
    displayPadding: EdgeInsets.symmetric(
      horizontal: generated.generatedDefaultDisplayPaddingHorizontal,
      vertical: generated.generatedDefaultDisplayPaddingVertical,
    ),
    digitWidth: generated.generatedDefaultDigitWidth,
    digitHeight: generated.generatedDefaultDigitHeight,
    keyBackground: Color(generated.generatedDefaultKeyBackground),
    keyForeground: Color(generated.generatedDefaultKeyForeground),
    keyBorder: Color(generated.generatedDefaultKeyBorder),
    keyRadius: generated.generatedDefaultKeyRadius,
    keyPadding: generated.generatedDefaultKeyPadding,
    keyMinHeight: generated.generatedDefaultKeyMinHeight,
    screenPadding: generated.generatedDefaultScreenPadding,
    keyboardHeight: generated.generatedDefaultKeyboardHeight,
  );

  /// Alias temporal del MVP: se conserva en 44 dp hasta V9.
  static const SkinTokens classicAmber = SkinTokens(
    segmentOn: Color(0xFFFFB000),
    displayBackground: Color(0xFF1E1B12),
    displayBorder: Color(0xFF3A3320),
    displayRadius: 8,
    displayPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    digitWidth: 26,
    digitHeight: 48,
    keyPadding: 3,
    keyMinHeight: 44,
    screenPadding: 12,
    keyboardHeight: 380,
  );
}
