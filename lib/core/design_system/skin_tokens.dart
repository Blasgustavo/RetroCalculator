import 'package:flutter/material.dart';

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

  /// Tema gratuito heredado. Sus valores son los del MVP antes de las skins.
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
