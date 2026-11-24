import 'dart:math' as math;

const double minContrastRatio = 4.5;
const double minTouchTarget = 48;

const List<String> colorKeys = <String>[
  'segmentOn',
  'displayBackground',
  'displayBorder',
  'keyBackground',
  'keyForeground',
  'keyBorder',
];

const Map<String, num> minValues = <String, num>{
  'displayRadius': 0,
  'displayPaddingHorizontal': 0,
  'displayPaddingVertical': 0,
  'digitWidth': 8,
  'digitHeight': 16,
  'keyRadius': 0,
  'keyPadding': 0,
  'keyMinHeight': minTouchTarget,
  'screenPadding': 0,
  'keyboardHeight': 200,
};

const Map<String, num> maxValues = <String, num>{
  'displayRadius': 64,
  'displayPaddingHorizontal': 64,
  'displayPaddingVertical': 64,
  'digitWidth': 80,
  'digitHeight': 120,
  'keyRadius': 64,
  'keyPadding': 32,
  'keyMinHeight': 200,
  'screenPadding': 64,
  'keyboardHeight': 2000,
};

final RegExp hexColorPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

double relativeLuminance(String hex) {
  final String value = hex.replaceFirst('#', '');
  if (value.length != 6) {
    throw FormatException('Color debe ser #RRGGBB: $hex');
  }
  return 0.2126 * _channel(value, 0) +
      0.7152 * _channel(value, 2) +
      0.0722 * _channel(value, 4);
}

double contrastRatio(String foregroundHex, String backgroundHex) {
  final double a = relativeLuminance(foregroundHex);
  final double b = relativeLuminance(backgroundHex);
  final double high = math.max(a, b);
  final double low = math.min(a, b);
  return (high + 0.05) / (low + 0.05);
}

List<String> validateTokens(Map<String, Object?> values) {
  final List<String> errors = <String>[];
  for (final String key in colorKeys) {
    final Object? value = values[key];
    if (value == null) {
      errors.add('$key ausente');
    } else if (value is! String || !hexColorPattern.hasMatch(value)) {
      errors.add('$key debe ser #RRGGBB');
    }
  }
  for (final String key in minValues.keys) {
    final Object? value = values[key];
    if (value == null) {
      errors.add('$key ausente');
    } else if (value is! num) {
      errors.add('$key debe ser numérico');
    } else if (value < minValues[key]! || value > maxValues[key]!) {
      errors.add('$key fuera de rango');
    }
  }
  final Object? segmentOn = values['segmentOn'];
  final Object? displayBackground = values['displayBackground'];
  if (segmentOn is String &&
      displayBackground is String &&
      hexColorPattern.hasMatch(segmentOn) &&
      hexColorPattern.hasMatch(displayBackground) &&
      contrastRatio(segmentOn, displayBackground) < minContrastRatio) {
    errors.add('segmento/display por debajo de 4.5:1');
  }
  final Object? keyForeground = values['keyForeground'];
  final Object? keyBackground = values['keyBackground'];
  if (keyForeground is String &&
      keyBackground is String &&
      hexColorPattern.hasMatch(keyForeground) &&
      hexColorPattern.hasMatch(keyBackground) &&
      contrastRatio(keyForeground, keyBackground) < minContrastRatio) {
    errors.add('texto/botón por debajo de 4.5:1');
  }
  final Object? minHeight = values['keyMinHeight'];
  if (minHeight is num && minHeight < minTouchTarget) {
    errors.add('botón por debajo de 48 dp');
  }
  return errors;
}

double _channel(String hex, int offset) {
  final int value = int.parse(hex.substring(offset, offset + 2), radix: 16);
  final double channel = value / 255;
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4) as double;
}
