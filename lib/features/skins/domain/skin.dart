import 'package:flutter/foundation.dart';

import '../../../core/design_system/generated/skin_tokens_lcd_classica.dart';
import '../../../core/design_system/skin_tokens.dart';

@immutable
class Skin {
  const Skin({
    required this.id,
    required this.nameKey,
    required this.tokens,
    required this.isFree,
    required this.source,
  });

  final String id;
  final String nameKey;
  final SkinTokens tokens;
  final bool isFree;
  final String source;

  /// Skin generada desde la semilla v2. Aditiva: V9 la activará como default.
  static const Skin generatedDefault = Skin(
    id: 'default',
    nameKey: 'skinDefaultName',
    tokens: SkinTokens.generatedDefault,
    isFree: true,
    source: 'compiled',
  );

  static const Skin classicAmber = Skin(
    id: 'classic_amber',
    nameKey: 'skinClassicName',
    tokens: SkinTokens.classicAmber,
    isFree: true,
    source: 'compiled',
  );

  /// Gratuita; la selección es cosmética y no afecta al cálculo.
  static const Skin lcdClasica = Skin(
    id: 'lcd_classica',
    nameKey: 'skinLcdClassicaName',
    tokens: skinTokensLcdClasica,
    isFree: true,
    source: 'compiled',
  );
}
