import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/design_system/skin_tokens.dart';

void main() {
  test('los tokens heredados reproducen el aspecto actual sin cambios', () {
    const SkinTokens tokens = SkinTokens.classicAmber;
    expect(tokens.segmentOn, const Color(0xFFFFB000));
    expect(tokens.displayBackground, const Color(0xFF1E1B12));
    expect(tokens.displayBorder, const Color(0xFF3A3320));
    expect(tokens.displayRadius, 8);
    expect(
      tokens.displayPadding,
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
    expect(tokens.digitWidth, 26);
    expect(tokens.digitHeight, 48);
    expect(tokens.keyPadding, 3);
    expect(tokens.keyMinHeight, 44);
    expect(tokens.screenPadding, 12);
    expect(tokens.keyboardHeight, 380);
    expect(tokens.keyBackground, isNull);
    expect(tokens.keyForeground, isNull);
    expect(tokens.keyBorder, isNull);
    expect(tokens.keyRadius, isNull);
  });

  test('la skin generada usa 48 dp sin reemplazar el alias heredado', () {
    const SkinTokens generated = SkinTokens.generatedDefault;
    expect(generated.keyMinHeight, 48);
    expect(generated.keyBackground, const Color(0xFFE8D9A0));
    expect(generated.keyForeground, const Color(0xFF1E1B12));
    expect(generated.segmentOn, const Color(0xFFFFB000));
    expect(SkinTokens.classicAmber.keyMinHeight, 44);
    expect(SkinTokens.classicAmber.keyBackground, isNull);
  });
}
