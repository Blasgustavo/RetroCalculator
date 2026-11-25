import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:retro_calculator/core/design_system/token_validation.dart';
import 'package:yaml/yaml.dart';

const String _definitionPath = 'tool/skins/definitions/lcd_classica.yaml';
const String _dartOutput =
    'lib/core/design_system/generated/skin_tokens_lcd_classica.dart';
const String _manifestOutput = 'assets/catalog/manifest.json';

void main() {
  // LF canónico: el mismo SHA-256 en Windows, macOS y CI Linux.
  final String raw = File(
    _definitionPath,
  ).readAsStringSync().replaceAll('\r\n', '\n');
  final YamlMap doc = loadYaml(raw) as YamlMap;
  if (doc['schemaVersion'] != 1) {
    throw StateError('schemaVersion no soportado: ${doc['schemaVersion']}');
  }
  final YamlMap modules = doc['modules'] as YamlMap;
  final YamlMap palette = modules['palette'] as YamlMap;
  final YamlMap display = modules['display'] as YamlMap;
  final YamlMap buttons = modules['buttons'] as YamlMap;
  final YamlMap shell = modules['shell'] as YamlMap;

  final Map<String, Object?> tokens = <String, Object?>{
    'segmentOn': palette['segmentOn'],
    'displayBackground': palette['displayBackground'],
    'displayBorder': palette['displayBorder'],
    'displayRadius': display['radius'],
    'displayPaddingHorizontal': display['paddingHorizontal'],
    'displayPaddingVertical': display['paddingVertical'],
    'digitWidth': display['digitWidth'],
    'digitHeight': display['digitHeight'],
    'keyBackground': palette['keyBackground'],
    'keyForeground': palette['keyForeground'],
    'keyBorder': palette['keyBorder'],
    'keyRadius': buttons['radius'],
    'keyPadding': buttons['padding'],
    'keyMinHeight': buttons['minHeight'],
    'screenPadding': shell['screenPadding'],
    'keyboardHeight': shell['keyboardHeight'],
  };
  final List<String> errors = validateTokens(tokens);
  if (errors.isNotEmpty) {
    throw StateError('Definición inválida: ${errors.join('; ')}');
  }

  final String dart =
      '''
// GENERADO: dart run tool/skins/generate.dart. No editar a mano.
import 'package:flutter/material.dart';
import '../skin_tokens.dart';

const SkinTokens skinTokensLcdClasica = SkinTokens(
  segmentOn: ${_color(tokens['segmentOn'] as String)},
  displayBackground: ${_color(tokens['displayBackground'] as String)},
  displayBorder: ${_color(tokens['displayBorder'] as String)},
  displayRadius: ${tokens['displayRadius']},
  displayPadding: EdgeInsets.symmetric(horizontal: ${tokens['displayPaddingHorizontal']}, vertical: ${tokens['displayPaddingVertical']}),
  digitWidth: ${tokens['digitWidth']},
  digitHeight: ${tokens['digitHeight']},
  keyBackground: ${_color(tokens['keyBackground'] as String)},
  keyForeground: ${_color(tokens['keyForeground'] as String)},
  keyBorder: ${_color(tokens['keyBorder'] as String)},
  keyRadius: ${tokens['keyRadius']},
  keyPadding: ${tokens['keyPadding']},
  keyMinHeight: ${tokens['keyMinHeight']},
  screenPadding: ${tokens['screenPadding']},
  keyboardHeight: ${tokens['keyboardHeight']},
);
''';
  File(_dartOutput)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(dart);

  final Map<String, Object?> manifest = <String, Object?>{
    'schemaVersion': 1,
    'version': doc['version'],
    'entries': <Object?>[
      <String, Object?>{
        'id': doc['id'],
        'nameKey': doc['nameKey'],
        'definition': _definitionPath,
        'definitionYaml': raw,
        'checksum': sha256.convert(utf8.encode(raw)).toString(),
        'rewardDurationHours': doc['rewardDurationHours'] ?? 24,
        'capabilities': (doc['capabilities'] as YamlList).toList(),
        'source': doc['source'],
        'tokens': tokens,
      },
    ],
  };
  File(_manifestOutput)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${jsonEncode(manifest)}\n');
}

String _color(String hex) {
  return 'Color(0xFF${hex.replaceFirst('#', '').toUpperCase()})';
}
