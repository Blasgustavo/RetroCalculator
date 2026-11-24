import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/design_system/token_validation.dart';

const Map<String, Object?> lcdTokens = <String, Object?>{
  'segmentOn': '#B8E986',
  'displayBackground': '#1E2A1F',
  'displayBorder': '#3A3320',
  'displayRadius': 8,
  'displayPaddingHorizontal': 16,
  'displayPaddingVertical': 12,
  'digitWidth': 26,
  'digitHeight': 48,
  'keyBackground': '#E8F0D6',
  'keyForeground': '#1E2A1F',
  'keyBorder': '#4F6F52',
  'keyRadius': 6,
  'keyPadding': 3,
  'keyMinHeight': 48,
  'screenPadding': 12,
  'keyboardHeight': 380,
};

void main() {
  test('blanco sobre negro da 21:1', () {
    expect(contrastRatio('#FFFFFF', '#000000'), closeTo(21, 0.01));
  });

  test('la LCD clásica cumple las 16 claves, contraste y tamaño táctil', () {
    expect(lcdTokens, hasLength(16));
    expect(validateTokens(lcdTokens), isEmpty);
  });

  test('rechaza ausencias, formato, rango, contraste bajo y botón pequeño', () {
    final Map<String, Object?> missing = Map<String, Object?>.from(lcdTokens)
      ..remove('displayBorder');
    expect(validateTokens(missing), contains('displayBorder ausente'));

    final Map<String, Object?> malformed = Map<String, Object?>.from(lcdTokens)
      ..['keyForeground'] = 'verde';
    expect(
      validateTokens(malformed),
      contains('keyForeground debe ser #RRGGBB'),
    );

    final Map<String, Object?> outOfRange = Map<String, Object?>.from(lcdTokens)
      ..['digitWidth'] = 2;
    expect(validateTokens(outOfRange), contains('digitWidth fuera de rango'));

    final Map<String, Object?> lowContrast =
        Map<String, Object?>.from(lcdTokens)
          ..['segmentOn'] = '#777777'
          ..['displayBackground'] = '#888888';
    expect(
      validateTokens(lowContrast),
      contains('segmento/display por debajo de 4.5:1'),
    );

    final Map<String, Object?> smallKey = Map<String, Object?>.from(lcdTokens)
      ..['keyMinHeight'] = 44;
    expect(validateTokens(smallKey), contains('botón por debajo de 48 dp'));
  });
}
