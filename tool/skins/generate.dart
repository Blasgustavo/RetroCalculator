// Generador de skins v1 y helpers compartidos con el compiler v2.
// La definición YAML es estable: el checksum de lcd_classica no cambia.
// V2 (tool/design/compile.dart) reutiliza el renderizado de tokens y itera
// todas las skins de design/app.design.json desde tokensForDesignSkins.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:retro_calculator/core/design_system/token_validation.dart'
    show validateTokens;
import 'package:yaml/yaml.dart';

import '../design/schema.dart' show DesignSeed, SkinSpec;

const String legacyDefinitionPath = 'tool/skins/definitions/lcd_classica.yaml';
const String legacyDartPath =
    'lib/core/design_system/generated/skin_tokens_lcd_classica.dart';
const String legacyManifestPath = 'assets/catalog/manifest.json';
const String legacyChecksum =
    '26d270cf605e455cbbe2f970d915dfefcd18bae6e9dc7b089220e97669bc77aa';

/// Datos de la definición v1 ya validados y normalizados a LF.
class LegacySkinDefinition {
  const LegacySkinDefinition({
    required this.raw,
    required this.doc,
    required this.tokens,
  });

  final String raw;
  final YamlMap doc;
  final Map<String, Object?> tokens;
}

/// SHA-256 sobre bytes UTF-8 del contenido LF canónico.
String checksumOf(String content) =>
    sha256.convert(utf8.encode(content)).toString();

/// Itera las skins de la semilla v2 en el orden del JSON.
///
/// El compiler usa estos tokens para generar `SkinTokens.generatedDefault`
/// y el mapa `designSkinTokens`; la validación de reglas sigue en validate.dart.
List<Map<String, Object?>> tokensForDesignSkins(DesignSeed design) =>
    design.skins.map((SkinSpec skin) => skin.tokens).toList();

LegacySkinDefinition readLegacySkinDefinition({required Directory root}) {
  final String raw = File(
    _join(root, legacyDefinitionPath.split('/')),
  ).readAsStringSync().replaceAll('\r\n', '\n');
  final YamlMap doc = loadYaml(raw) as YamlMap;
  if (doc['schemaVersion'] != 1) {
    throw StateError('schemaVersion no soportado: ${doc['schemaVersion']}');
  }
  final Map<String, Object?> tokens = tokensFromYaml(doc);
  final List<String> errors = validateTokens(tokens);
  if (errors.isNotEmpty) {
    throw StateError('Definición inválida: ${errors.join('; ')}');
  }
  return LegacySkinDefinition(raw: raw, doc: doc, tokens: tokens);
}

Map<String, Object?> tokensFromYaml(YamlMap doc) {
  final YamlMap modules = doc['modules'] as YamlMap;
  final YamlMap palette = modules['palette'] as YamlMap;
  final YamlMap display = modules['display'] as YamlMap;
  final YamlMap buttons = modules['buttons'] as YamlMap;
  final YamlMap shell = modules['shell'] as YamlMap;
  return <String, Object?>{
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
}

/// Renderiza la definición v1 exactamente como en el generador original.
String renderLegacySkinTokens(LegacySkinDefinition definition) =>
    renderSkinTokensDart(
      definition.tokens,
      name: 'skinTokensLcdClasica',
      command: 'dart run tool/skins/generate.dart',
    );

String renderSkinTokensDart(
  Map<String, Object?> tokens, {
  required String name,
  required String command,
}) {
  String color(String key) =>
      'Color(0xFF${(tokens[key]! as String).replaceFirst('#', '').toUpperCase()})';
  return '''
// GENERADO: $command. No editar a mano.
import 'package:flutter/material.dart';
import '../skin_tokens.dart';

const SkinTokens $name = SkinTokens(
  segmentOn: ${color('segmentOn')},
  displayBackground: ${color('displayBackground')},
  displayBorder: ${color('displayBorder')},
  displayRadius: ${tokens['displayRadius']},
  displayPadding: EdgeInsets.symmetric(horizontal: ${tokens['displayPaddingHorizontal']}, vertical: ${tokens['displayPaddingVertical']}),
  digitWidth: ${tokens['digitWidth']},
  digitHeight: ${tokens['digitHeight']},
  keyBackground: ${color('keyBackground')},
  keyForeground: ${color('keyForeground')},
  keyBorder: ${color('keyBorder')},
  keyRadius: ${tokens['keyRadius']},
  keyPadding: ${tokens['keyPadding']},
  keyMinHeight: ${tokens['keyMinHeight']},
  screenPadding: ${tokens['screenPadding']},
  keyboardHeight: ${tokens['keyboardHeight']},
);
''';
}

/// Manifiesto v1 intacto: schemaVersion 1 con definitionYaml embebido.
Map<String, Object?> buildLegacyManifest(LegacySkinDefinition definition) =>
    <String, Object?>{
      'schemaVersion': 1,
      'version': definition.doc['version'],
      'entries': <Object?>[
        <String, Object?>{
          'id': definition.doc['id'],
          'nameKey': definition.doc['nameKey'],
          'definition': legacyDefinitionPath,
          'definitionYaml': definition.raw,
          'checksum': checksumOf(definition.raw),
          'rewardDurationHours': definition.doc['rewardDurationHours'] ?? 24,
          'capabilities': (definition.doc['capabilities'] as YamlList).toList(),
          'source': definition.doc['source'],
          'tokens': definition.tokens,
        },
      ],
    };

void main() {
  // LF canónico: el mismo SHA-256 en Windows, macOS y CI Linux.
  final LegacySkinDefinition definition = readLegacySkinDefinition(
    root: Directory.current,
  );
  File(_join(Directory.current, legacyDartPath.split('/')))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(renderLegacySkinTokens(definition));
  File(_join(Directory.current, legacyManifestPath.split('/')))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync('${jsonEncode(buildLegacyManifest(definition))}\n');
}

String _join(Directory root, List<String> parts) =>
    <String>[root.path, ...parts].join(Platform.pathSeparator);
