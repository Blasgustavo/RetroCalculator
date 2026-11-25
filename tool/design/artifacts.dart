// Renderizado puro de los artefactos del compiler v2. Sin Flutter y sin
// efectos secundarios: compile.dart decide cuándo y dónde escribirlos.

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:retro_calculator/core/design_system/token_validation.dart'
    show colorKeys, minValues;

import '../skins/generate.dart' as legacy;
import 'schema.dart';

const String generatedHeader =
    '// GENERADO: dart run tool/design/compile.dart. No editar a mano.\n';
const String manifestV2Path = 'assets/catalog/manifest.v2.json';

const List<String> generatedPaths = <String>[
  'lib/core/design_system/generated/design_tokens.dart',
  'lib/features/skins/data/generated/screens.g.dart',
  'lib/features/skins/data/generated/profiles.g.dart',
  'lib/features/skins/data/generated/images.g.dart',
  'lib/features/skins/data/generated/sounds.g.dart',
];

class GeneratedFile {
  const GeneratedFile(this.path, this.content);

  final String path;
  final String content;
}

/// Genera los cinco artefactos a partir de una semilla ya validada.
List<GeneratedFile> buildArtifacts(
  DesignSeed design, {
  required Directory root,
  required File designFile,
}) {
  final String designPath = _relativePath(root, designFile);
  return <GeneratedFile>[
    GeneratedFile(
      generatedPaths[0],
      _designTokens(design, designPath: designPath),
    ),
    GeneratedFile(generatedPaths[1], _screens(design)),
    GeneratedFile(generatedPaths[2], _profiles(design)),
    GeneratedFile(
      generatedPaths[3],
      _images(design, assetsRoot: _assetsRoot(designFile)),
    ),
    GeneratedFile(
      generatedPaths[4],
      _sounds(design, assetsRoot: _assetsRoot(designFile)),
    ),
  ];
}

/// Manifiesto v2: `definition` es una ruta, nunca un YAML embebido.
///
/// `signature` queda vacía a la espera de V7; la clave privada de firma nunca
/// entra al repositorio. V7 migrará el cliente de manifest.json (v1) a este
/// archivo, que se emite de forma aditiva para no romper los 56 tests heredados.
Map<String, Object?> buildManifestV2(
  DesignSeed design, {
  required Directory root,
  required File designFile,
}) {
  final String designPath = _relativePath(root, designFile);
  final String designChecksum = legacy.checksumOf(
    designFile.readAsStringSync().replaceAll('\r\n', '\n'),
  );
  final legacy.LegacySkinDefinition definition = legacy
      .readLegacySkinDefinition(root: root);
  final String legacyChecksum = legacy.checksumOf(definition.raw);
  if (legacyChecksum != legacy.legacyChecksum) {
    throw StateError(
      'El checksum de ${legacy.legacyDefinitionPath} cambió: '
      'se esperaba ${legacy.legacyChecksum} y se calculó $legacyChecksum',
    );
  }

  final List<Object?> entries = design.skins.map((SkinSpec skin) {
    final bool isLegacy = skin.id == 'lcd_classica';
    return <String, Object?>{
      'id': skin.id,
      'nameKey': skin.nameKey,
      'isDefault': skin.isDefault,
      'definition': isLegacy ? legacy.legacyDefinitionPath : designPath,
      'checksum': isLegacy ? legacyChecksum : designChecksum,
      'tokens': skin.tokens,
    };
  }).toList();

  final Directory assets = _assetsRoot(designFile);
  final List<Object?> images = design.images.map((ImageSpec image) {
    final List<int> bytes = File(
      _join(assets.path, <String>[image.file]),
    ).readAsBytesSync();
    return <String, Object?>{
      'id': image.id,
      'file': image.file,
      'format': image.format,
      'maxWidth': image.maxWidth,
      'maxHeight': image.maxHeight,
      'checksum': sha256.convert(bytes).toString(),
    };
  }).toList();
  final List<Object?> sounds = design.sounds.events.entries.map((
    MapEntry<String, String> event,
  ) {
    final List<int> bytes = File(
      _join(assets.path, <String>[event.value]),
    ).readAsBytesSync();
    return <String, Object?>{
      'event': event.key,
      'file': event.value,
      'checksum': sha256.convert(bytes).toString(),
    };
  }).toList();

  return <String, Object?>{
    'version': design.version,
    'channel': design.publishing.channel,
    'entries': entries,
    'assets': <String, Object?>{'images': images, 'sounds': sounds},
    'signature': '',
  };
}

String _designTokens(DesignSeed design, {required String designPath}) {
  final List<Map<String, Object?>> tokens = legacy.tokensForDesignSkins(design);
  final Map<String, Object?> defaults = design.skins
      .firstWhere((SkinSpec skin) => skin.isDefault)
      .tokens;
  final StringBuffer out = StringBuffer(generatedHeader);
  out.writeln(
    '// Datos puros de la semilla. Sin Flutter: lo consume el compiler',
  );
  out.writeln('// y las reglas de token_validation.dart.');
  out.writeln();
  out.writeln('const int designSchemaVersion = ${design.schemaVersion};');
  out.writeln('const int designVersion = ${design.version};');
  out.writeln(
    'const List<String> designChannels = <String>[${design.channels.map(_stringLiteral).join(', ')}];',
  );
  out.writeln();
  out.writeln('/// Tokens de todas las skins, en el orden del JSON.');
  out.writeln(
    'const Map<String, Map<String, Object?>> designSkinTokens = '
    '<String, Map<String, Object?>>{',
  );
  for (int i = 0; i < design.skins.length; i++) {
    out.writeln(
      '  ${_stringLiteral(design.skins[i].id)}: ${_literal(tokens[i])},',
    );
  }
  out.writeln('};');
  out.writeln();
  out.writeln(
    '/// Tokens crudos de la skin default, listos para validateTokens().',
  );
  out.writeln(
    'const String generatedDefaultDefinition = ${_stringLiteral(designPath)};',
  );
  out.writeln(
    'const Map<String, Object?> generatedDefaultTokenValues = '
    '${_literal(defaults)};',
  );
  out.writeln();
  for (final String key in colorKeys) {
    final String hex = defaults[key]! as String;
    out.writeln(
      'const int generatedDefault${_camel(key)} = '
      '0xFF${hex.replaceFirst('#', '').toUpperCase()};',
    );
  }
  for (final String key in minValues.keys) {
    out.writeln(
      'const double generatedDefault${_camel(key)} = '
      '${jsonEncode(defaults[key]!)};',
    );
  }
  return '$out';
}

String _screens(DesignSeed design) {
  final StringBuffer out = StringBuffer(generatedHeader);
  out.writeln(
    '/// Pantallas y breakpoints de design/app.design.json. Datos puros.',
  );
  out.writeln(
    'const Map<String, Map<String, List<Object?>>> screenSpecs = '
    '<String, Map<String, List<Object?>>>{',
  );
  for (final MapEntry<String, Map<String, List<DesignNode>>> screen
      in design.screens.entries) {
    out.writeln('  ${_stringLiteral(screen.key)}: <String, List<Object?>>{');
    for (final MapEntry<String, List<DesignNode>> breakpoint
        in screen.value.entries) {
      final List<String> nodes = breakpoint.value
          .map((DesignNode node) => _literal(_nodeMap(node)))
          .toList();
      out.writeln(
        '    ${_stringLiteral(breakpoint.key)}: <Object?>[${nodes.join(', ')}],',
      );
    }
    out.writeln('  },');
  }
  out.writeln('};');
  return '$out';
}

String _profiles(DesignSeed design) {
  final List<Object?> profiles = design.profiles.map((ProfileSpec profile) {
    return <String, Object?>{
      'id': profile.id,
      'labelKey': profile.labelKey,
      'capabilityId': profile.capabilityId,
      'isScientific': profile.isScientific,
      'defaultAngleMode': profile.defaultAngleMode,
      'decimalDigits': profile.decimalDigits,
      'inputs': profile.inputs,
      'formulas': profile.formulas,
      'keyRows': profile.keyRows,
    };
  }).toList();
  return '$generatedHeader'
      '/// Perfiles declarativos de la semilla. Sin lógica de cálculo.\n'
      'const List<Map<String, Object?>> profileSpecs = '
      '<Map<String, Object?>>[${profiles.map(_literal).join(', ')}];\n';
}

String _images(DesignSeed design, {required Directory assetsRoot}) {
  final List<Object?> images = design.images.map((ImageSpec image) {
    final List<int> bytes = File(
      _join(assetsRoot.path, <String>[image.file]),
    ).readAsBytesSync();
    return <String, Object?>{
      'id': image.id,
      'file': image.file,
      'format': image.format,
      'maxWidth': image.maxWidth,
      'maxHeight': image.maxHeight,
      'checksum': sha256.convert(bytes).toString(),
    };
  }).toList();
  return '$generatedHeader'
      '/// Imágenes declaradas en la semilla, con checksum del asset versionado.\n'
      'const List<Map<String, Object?>> imageAssets = '
      '<Map<String, Object?>>[${images.map(_literal).join(', ')}];\n';
}

String _sounds(DesignSeed design, {required Directory assetsRoot}) {
  final StringBuffer out = StringBuffer(generatedHeader);
  out.writeln('/// Eventos de sonido declarados en la semilla.');
  out.writeln('const bool soundsEnabled = ${design.sounds.enabled};');
  out.writeln('const Map<String, String> soundEvents = <String, String>{');
  for (final MapEntry<String, String> event in design.sounds.events.entries) {
    final List<int> bytes = File(
      _join(assetsRoot.path, <String>[event.value]),
    ).readAsBytesSync();
    out.writeln(
      '  ${_stringLiteral(event.key)}: ${_stringLiteral(event.value)}, '
      '// ${sha256.convert(bytes).toString()}',
    );
  }
  out.writeln('};');
  return '$out';
}

Map<String, Object?> _nodeMap(DesignNode node) {
  final Map<String, Object?> result = <String, Object?>{'type': node.type};
  if (node.key != null) result['key'] = node.key;
  if (node.titleKey != null) result['titleKey'] = node.titleKey;
  if (node.when != null) result['when'] = node.when;
  if (node.value != null) result['value'] = node.value;
  if (node.height != null) result['height'] = node.height;
  if (node.alignment != null) result['alignment'] = node.alignment;
  if (node.child != null) result['child'] = _nodeMap(node.child!);
  if (node.children != null) {
    result['children'] = node.children!.map(_nodeMap).toList();
  }
  return result;
}

String _literal(Object? value) {
  if (value == null) return 'null';
  if (value is String) return _stringLiteral(value);
  if (value is Map<String, Object?>) {
    return '{${value.entries.map((MapEntry<String, Object?> entry) => '${_stringLiteral(entry.key)}: ${_literal(entry.value)}').join(', ')}}';
  }
  if (value is List<Object?>) {
    return '<Object?>[${value.map(_literal).join(', ')}]';
  }
  return jsonEncode(value);
}

String _stringLiteral(String value) =>
    jsonEncode(value).replaceAll(r'$', r'\$');

String _camel(String snake) => snake
    .split('_')
    .map(
      (String part) =>
          part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1),
    )
    .join();

Directory _assetsRoot(File designFile) =>
    Directory(_join(designFile.parent.path, <String>['assets']));

String _relativePath(Directory root, File file) {
  final String rootPath = root.path
      .replaceAll(r'\', '/')
      .replaceAll(RegExp(r'/$'), '');
  final String filePath = file.path.replaceAll(r'\', '/');
  final String prefix = '$rootPath/';
  return filePath.startsWith(prefix)
      ? filePath.substring(prefix.length)
      : filePath;
}

String _join(String root, List<String> parts) =>
    <String>[root, ...parts].join(Platform.pathSeparator);
