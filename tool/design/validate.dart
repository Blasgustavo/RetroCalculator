// Validador build-time de design/app.design.json. Solo interpreta datos:
// reutiliza las reglas de token_validation.dart y el parser del motor para
// comprobar fórmulas sin ejecutarlas (ADR-0004, ADR-0009).

import 'dart:convert';
import 'dart:io';

import 'package:retro_calculator/core/design_system/token_validation.dart'
    as token_rules;
import 'package:retro_calculator/features/calculator/domain/capabilities/basic_capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/capability.dart';
import 'package:retro_calculator/features/calculator/domain/capabilities/scientific_capability.dart';

import 'formula_validation.dart'
    show FormulaIssue, FormulaValidation, validateFormula;
import 'schema.dart';

class ValidationIssue {
  const ValidationIssue(this.path, this.message);

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

const List<String> arbFiles = <String>[
  'app_en.arb',
  'app_es.arb',
  'app_es_PE.arb',
  'app_pt.arb',
  'app_pt_BR.arb',
];

const Set<String> expectedScreens = <String>{
  'normal',
  'scientific',
  'selector',
};

const String checksumPlaceholder = 'RELLENAR_POR_EL_COMPILER';

const Set<String> forbiddenMonetizationKeys = <String>{
  'price',
  'prices',
  'amount',
  'currency',
  'entitlement',
  'entitlements',
  'rewardDurationHours',
  'banner',
  'interstitial',
};

class _ArbReference {
  const _ArbReference(this.path, this.key);

  final String path;
  final String key;
}

class _PngSize {
  const _PngSize(this.width, this.height);

  final int width;
  final int height;
}

List<ValidationIssue> validateJson(
  Map<String, Object?> json, {
  required Directory projectRoot,
  required Directory assetsRoot,
}) {
  final List<ValidationIssue> issues = <ValidationIssue>[];
  final DesignSeed design;
  try {
    design = DesignSeed.fromJson(json);
  } on DesignSchemaException catch (error) {
    return <ValidationIssue>[ValidationIssue(error.path, error.reason)];
  }

  _validateHeader(design, issues);
  _validateSkins(design, issues);
  _validateImages(design, assetsRoot, issues);
  _validateSounds(design, assetsRoot, issues);
  _validateScreens(design, issues);
  _validateDimensions(design, issues);
  _validateProfiles(design, issues);
  _validateMonetization(design, json, issues);
  _validatePublishing(design, issues);
  _validateArbKeys(design, projectRoot, issues);

  return issues;
}

List<ValidationIssue> validateFile(File file, {Directory? projectRoot}) {
  if (!file.existsSync()) {
    return <ValidationIssue>[
      ValidationIssue(file.path, 'archivo de diseño no existe'),
    ];
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    return <ValidationIssue>[
      ValidationIssue('design', 'JSON no válido: ${error.message}'),
    ];
  }
  if (decoded is! Map<String, Object?>) {
    return <ValidationIssue>[
      const ValidationIssue('design', 'debe ser un objeto JSON'),
    ];
  }
  final Directory root = projectRoot ?? Directory.current;
  final Directory assets = Directory(
    '${file.parent.path}${Platform.pathSeparator}assets',
  );
  return validateJson(decoded, projectRoot: root, assetsRoot: assets);
}

void _validateHeader(DesignSeed design, List<ValidationIssue> issues) {
  if (design.schemaVersion != designSchemaVersion) {
    issues.add(
      ValidationIssue(
        'schemaVersion',
        'se espera $designSchemaVersion, se encontró ${design.schemaVersion}',
      ),
    );
  }
  if (design.version < 1) {
    issues.add(const ValidationIssue('version', 'debe ser al menos 1'));
  }
  for (final String channel in design.channels) {
    if (!designChannels.contains(channel)) {
      issues.add(ValidationIssue('channels', 'canal desconocido: $channel'));
    }
  }
}

void _validateSkins(DesignSeed design, List<ValidationIssue> issues) {
  final Set<String> requiredTokens = <String>{
    ...token_rules.colorKeys,
    ...token_rules.minValues.keys,
  };
  for (int i = 0; i < design.skins.length; i++) {
    final SkinSpec skin = design.skins[i];
    final String tokenPath = 'skins[$i].tokens';
    for (final String key in requiredTokens.difference(
      skin.tokens.keys.toSet(),
    )) {
      issues.add(ValidationIssue('$tokenPath.$key', 'token ausente'));
    }
    for (final String error in token_rules.validateTokens(skin.tokens)) {
      issues.add(ValidationIssue(_tokenErrorPath(error, tokenPath), error));
    }
  }
  final int defaults = design.skins.where((SkinSpec s) => s.isDefault).length;
  if (defaults != 1) {
    issues.add(
      ValidationIssue(
        'skins',
        'debe haber exactamente una skin con isDefault: true (hay $defaults)',
      ),
    );
  }
}

String _tokenErrorPath(String error, String tokenPath) {
  for (final String key in <String>[
    ...token_rules.colorKeys,
    ...token_rules.minValues.keys,
  ]) {
    if (error.startsWith('$key ')) return '$tokenPath.$key';
  }
  if (error.contains('segmento/display')) {
    return '$tokenPath.segmentOn';
  }
  if (error.contains('texto/botón')) {
    return '$tokenPath.keyForeground';
  }
  if (error.contains('48 dp')) return '$tokenPath.keyMinHeight';
  return tokenPath;
}

void _validateImages(
  DesignSeed design,
  Directory assetsRoot,
  List<ValidationIssue> issues,
) {
  final Set<String> declaredIds = design.images
      .map((ImageSpec i) => i.id)
      .toSet();
  for (int i = 0; i < design.skins.length; i++) {
    for (int j = 0; j < design.skins[i].images.length; j++) {
      final String id = design.skins[i].images[j];
      if (!declaredIds.contains(id)) {
        issues.add(
          ValidationIssue('skins[$i].images[$j]', 'imagen no declarada: $id'),
        );
      }
    }
  }
  for (int i = 0; i < design.images.length; i++) {
    final ImageSpec image = design.images[i];
    if (image.file.contains('..') ||
        image.file.contains('/') ||
        image.file.contains('\\')) {
      issues.add(
        ValidationIssue('images[$i].file', 'la ruta debe ser un nombre simple'),
      );
      continue;
    }
    final File file = File(
      '${assetsRoot.path}${Platform.pathSeparator}${image.file}',
    );
    if (!file.existsSync()) {
      issues.add(
        ValidationIssue(
          'images[$i].file',
          'no existe ${image.file} en design/assets',
        ),
      );
      continue;
    }
    final List<int> bytes = file.readAsBytesSync();
    if (bytes.length > maxAssetBytes) {
      issues.add(
        ValidationIssue('images[$i].file', 'excede $maxAssetBytes bytes'),
      );
      continue;
    }
    if (image.format != 'png' || !image.file.toLowerCase().endsWith('.png')) {
      issues.add(
        ValidationIssue(
          'images[$i].format',
          'formato ${image.format} no soportado en V1',
        ),
      );
      continue;
    }
    final _PngSize? size = _pngSize(bytes);
    if (size == null) {
      issues.add(ValidationIssue('images[$i].file', 'no es un PNG válido'));
      continue;
    }
    if (size.width > image.maxWidth || size.height > image.maxHeight) {
      issues.add(
        ValidationIssue(
          'images[$i].file',
          'dimensiones ${size.width}x${size.height} exceden '
              '${image.maxWidth}x${image.maxHeight}',
        ),
      );
    }
    if (image.checksum != checksumPlaceholder &&
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(image.checksum)) {
      issues.add(
        ValidationIssue('images[$i].checksum', 'debe ser SHA-256 hexadecimal'),
      );
    }
  }
}

_PngSize? _pngSize(List<int> bytes) {
  const List<int> signature = <int>[
    0x89,
    0x50,
    0x4e,
    0x47,
    0x0d,
    0x0a,
    0x1a,
    0x0a,
  ];
  if (bytes.length < 24) return null;
  for (int i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) return null;
  }
  if (bytes[12] != 0x49 ||
      bytes[13] != 0x48 ||
      bytes[14] != 0x44 ||
      bytes[15] != 0x52) {
    return null;
  }
  final int width =
      (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
  final int height =
      (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
  if (width <= 0 || height <= 0) return null;
  return _PngSize(width, height);
}

void _validateSounds(
  DesignSeed design,
  Directory assetsRoot,
  List<ValidationIssue> issues,
) {
  if (!design.sounds.enabled) return;
  for (final MapEntry<String, String> event in design.sounds.events.entries) {
    final String path = 'sounds.events.${event.key}';
    if (event.value.contains('..') ||
        event.value.contains('/') ||
        event.value.contains('\\')) {
      issues.add(ValidationIssue(path, 'la ruta debe ser un nombre simple'));
      continue;
    }
    final File file = File(
      '${assetsRoot.path}${Platform.pathSeparator}${event.value}',
    );
    if (!file.existsSync()) {
      issues.add(
        ValidationIssue(path, 'no existe ${event.value} en design/assets'),
      );
      continue;
    }
    final List<int> bytes = file.readAsBytesSync();
    if (bytes.length > maxAssetBytes) {
      issues.add(ValidationIssue(path, 'excede $maxAssetBytes bytes'));
      continue;
    }
    if (!_isWav(bytes)) {
      issues.add(ValidationIssue(path, 'no es un WAV PCM válido'));
    }
  }
}

bool _isWav(List<int> bytes) {
  if (bytes.length < 12) return false;
  final String riff = String.fromCharCodes(bytes.take(4));
  final String wave = String.fromCharCodes(bytes.skip(8).take(4));
  return riff == 'RIFF' && wave == 'WAVE';
}

void _validateScreens(DesignSeed design, List<ValidationIssue> issues) {
  for (final String screen in expectedScreens.difference(
    design.screens.keys.toSet(),
  )) {
    issues.add(ValidationIssue('screens.$screen', 'pantalla ausente'));
  }
  for (final String screen in design.screens.keys) {
    if (!expectedScreens.contains(screen)) {
      issues.add(ValidationIssue('screens.$screen', 'pantalla desconocida'));
    }
    final Map<String, List<DesignNode>> breakpoints = design.screens[screen]!;
    for (final String breakpoint in designBreakpoints.difference(
      breakpoints.keys.toSet(),
    )) {
      issues.add(
        ValidationIssue('screens.$screen.$breakpoint', 'breakpoint ausente'),
      );
    }
    for (final MapEntry<String, List<DesignNode>> entry
        in breakpoints.entries) {
      if (!designBreakpoints.contains(entry.key)) {
        issues.add(
          ValidationIssue(
            'screens.$screen.${entry.key}',
            'breakpoint fuera de mobile/tablet/desktop',
          ),
        );
      }
      for (int i = 0; i < entry.value.length; i++) {
        _validateNode(
          entry.value[i],
          'screens.$screen.${entry.key}[$i]',
          issues,
        );
      }
    }
  }
}

void _validateNode(DesignNode node, String path, List<ValidationIssue> issues) {
  if (!designNodeTypes.contains(node.type)) {
    issues.add(
      ValidationIssue(path, 'tipo "${node.type}" fuera de la whitelist'),
    );
  }
  if (node.child != null) {
    _validateNode(node.child!, '$path.child', issues);
  }
  if (node.children != null) {
    for (int i = 0; i < node.children!.length; i++) {
      _validateNode(node.children![i], '$path.children[$i]', issues);
    }
  }
}

void _validateDimensions(DesignSeed design, List<ValidationIssue> issues) {
  if (design.dimensions.minTouchTarget != seedMinTouchTarget) {
    issues.add(
      ValidationIssue(
        'dimensions.minTouchTarget',
        'debe ser ${seedMinTouchTarget.toInt()} dp, se encontró '
            '${design.dimensions.minTouchTarget}',
      ),
    );
  }
  for (final MapEntry<String, int> entry
      in design.dimensions.breakpoints.entries) {
    if (!designBreakpoints.contains(entry.key)) {
      issues.add(
        ValidationIssue(
          'dimensions.breakpoints.${entry.key}',
          'breakpoint fuera de mobile/tablet/desktop',
        ),
      );
    }
    if (entry.value < 0) {
      issues.add(
        ValidationIssue(
          'dimensions.breakpoints.${entry.key}',
          'minWidth no puede ser negativo',
        ),
      );
    }
  }
}

void _validateProfiles(DesignSeed design, List<ValidationIssue> issues) {
  final Map<String, Set<String>> dependencies = <String, Set<String>>{};
  final Map<String, String> formulaPaths = <String, String>{};
  for (int i = 0; i < design.profiles.length; i++) {
    final ProfileSpec profile = design.profiles[i];
    if (!knownCapabilityIds.contains(profile.capabilityId)) {
      issues.add(
        ValidationIssue(
          'profiles[$i].capabilityId',
          'capabilityId no reconocido: ${profile.capabilityId}',
        ),
      );
    }
    final String inputsPath = 'profiles[$i].inputs';
    final Set<String> reportedDuplicateCodes = <String>{};
    for (final MapEntry<String, String> formula in profile.formulas.entries) {
      final String path = 'profiles[$i].formulas.${formula.key}';
      formulaPaths[formula.key] = path;
      dependencies[formula.key] = _validateFormula(
        name: formula.key,
        expression: formula.value,
        inputs: profile.inputs,
        capability: _capability(profile.capabilityId),
        formulaNames: design.profiles
            .expand((ProfileSpec p) => p.formulas.keys)
            .toSet(),
        path: path,
        inputsPath: inputsPath,
        reportedDuplicateCodes: reportedDuplicateCodes,
        issues: issues,
      );
    }
  }
  _detectFormulaCycles(dependencies, formulaPaths, issues);
}

CalculatorCapability _capability(String id) =>
    id == 'scientific' ? const ScientificCapability() : const BasicCapability();

Set<String> _validateFormula({
  required String name,
  required String expression,
  required List<String> inputs,
  required CalculatorCapability capability,
  required Set<String> formulaNames,
  required String path,
  required String inputsPath,
  required Set<String> reportedDuplicateCodes,
  required List<ValidationIssue> issues,
}) {
  final FormulaValidation result = validateFormula(
    name: name,
    expression: expression,
    inputs: inputs,
    formulaNames: formulaNames,
    functions: capability.functions,
    constants: capability.constants,
  );
  for (final FormulaIssue issue in result.issues) {
    if (issue.code == 'duplicateVariable') {
      // La colisión es del array de entradas, no de una fórmula concreta: se
      // informa una sola vez por perfil y código, aunque colisionen varias
      // entradas con mensajes distintos (ADR-0016).
      if (!reportedDuplicateCodes.add(issue.code)) continue;
      issues.add(ValidationIssue(inputsPath, issue.message));
    } else {
      issues.add(ValidationIssue(path, issue.message));
    }
  }
  return result.dependencies;
}

void _detectFormulaCycles(
  Map<String, Set<String>> dependencies,
  Map<String, String> paths,
  List<ValidationIssue> issues,
) {
  final Set<String> visiting = <String>{};
  final Set<String> visited = <String>{};
  void visit(String key) {
    if (visiting.contains(key)) {
      issues.add(
        ValidationIssue(paths[key] ?? 'profiles', 'fórmula recursiva: $key'),
      );
      return;
    }
    if (!visited.add(key)) return;
    visiting.add(key);
    for (final String dependency in dependencies[key] ?? const <String>{}) {
      visit(dependency);
    }
    visiting.remove(key);
  }

  for (final String key in dependencies.keys) {
    visit(key);
  }
}

void _validateMonetization(
  DesignSeed design,
  Map<String, Object?> json,
  List<ValidationIssue> issues,
) {
  if (design.monetization.ads.type != 'rewarded') {
    issues.add(
      ValidationIssue(
        'monetization.ads.type',
        'solo se permite rewarded, se encontró ${design.monetization.ads.type}',
      ),
    );
  }
  _scanForbiddenMonetizationKeys(json['monetization'], 'monetization', issues);
  final AdThemeSpec theme = design.monetization.ads.theme;
  if (token_rules.hexColorPattern.hasMatch(theme.buttonBackground) &&
      token_rules.hexColorPattern.hasMatch(theme.buttonForeground) &&
      token_rules.contrastRatio(
            theme.buttonForeground,
            theme.buttonBackground,
          ) <
          token_rules.minContrastRatio) {
    issues.add(
      const ValidationIssue(
        'monetization.ads.theme.buttonForeground',
        'texto/botón del anuncio por debajo de 4.5:1',
      ),
    );
  }
}

void _scanForbiddenMonetizationKeys(
  Object? value,
  String path,
  List<ValidationIssue> issues,
) {
  if (value is Map<String, Object?>) {
    for (final MapEntry<String, Object?> entry in value.entries) {
      if (forbiddenMonetizationKeys.contains(entry.key)) {
        issues.add(
          ValidationIssue(
            '$path.${entry.key}',
            'precios y entitlements no se declaran en el diseño',
          ),
        );
        continue;
      }
      _scanForbiddenMonetizationKeys(entry.value, '$path.${entry.key}', issues);
    }
    return;
  }
  if (value is List<Object?>) {
    for (int i = 0; i < value.length; i++) {
      _scanForbiddenMonetizationKeys(value[i], '$path[$i]', issues);
    }
  }
}

void _validatePublishing(DesignSeed design, List<ValidationIssue> issues) {
  if (!designChannels.contains(design.publishing.channel)) {
    issues.add(
      ValidationIssue(
        'publishing.channel',
        'canal desconocido: ${design.publishing.channel}',
      ),
    );
  }
}

void _validateArbKeys(
  DesignSeed design,
  Directory projectRoot,
  List<ValidationIssue> issues,
) {
  final Map<String, Set<String>> keysByFile = <String, Set<String>>{};
  for (final String file in arbFiles) {
    final File arb = File(
      '${projectRoot.path}${Platform.pathSeparator}lib'
      '${Platform.pathSeparator}l10n${Platform.pathSeparator}$file',
    );
    if (!arb.existsSync()) {
      issues.add(ValidationIssue('lib/l10n/$file', 'ARB no encontrado'));
      continue;
    }
    final Object? decoded = jsonDecode(arb.readAsStringSync());
    if (decoded is! Map<String, Object?>) {
      issues.add(ValidationIssue('lib/l10n/$file', 'ARB no válido'));
      continue;
    }
    keysByFile[file] = decoded.keys.toSet();
  }

  final List<_ArbReference> references = <_ArbReference>[
    for (int i = 0; i < design.skins.length; i++)
      _ArbReference('skins[$i].nameKey', design.skins[i].nameKey),
    for (int i = 0; i < design.profiles.length; i++)
      _ArbReference('profiles[$i].labelKey', design.profiles[i].labelKey),
    _ArbReference(
      'monetization.ads.theme.copyKey',
      design.monetization.ads.theme.copyKey,
    ),
    for (final MapEntry<String, String> entry
        in design.monetization.catalog.priceCopyKeys.entries)
      _ArbReference(
        'monetization.catalog.priceCopyKeys.${entry.key}',
        entry.value,
      ),
  ];
  for (final MapEntry<String, Map<String, List<DesignNode>>> screen
      in design.screens.entries) {
    for (final MapEntry<String, List<DesignNode>> breakpoint
        in screen.value.entries) {
      for (int i = 0; i < breakpoint.value.length; i++) {
        _collectNodeArbKeys(
          breakpoint.value[i],
          'screens.${screen.key}.${breakpoint.key}[$i]',
          references,
        );
      }
    }
  }

  for (final _ArbReference reference in references) {
    for (final MapEntry<String, Set<String>> file in keysByFile.entries) {
      if (!file.value.contains(reference.key)) {
        issues.add(
          ValidationIssue(
            reference.path,
            'clave ARB "${reference.key}" ausente en ${file.key}',
          ),
        );
      }
    }
  }
}

void _collectNodeArbKeys(
  DesignNode node,
  String path,
  List<_ArbReference> references,
) {
  if (node.titleKey != null) {
    references.add(_ArbReference('$path.titleKey', node.titleKey!));
  }
  if (node.child != null) {
    _collectNodeArbKeys(node.child!, '$path.child', references);
  }
  if (node.children != null) {
    for (int i = 0; i < node.children!.length; i++) {
      _collectNodeArbKeys(node.children![i], '$path.children[$i]', references);
    }
  }
}

void main(List<String> args) {
  if (args.length > 1) {
    stderr.writeln('Uso: dart run tool/design/validate.dart [archivo]');
    exitCode = 64;
    return;
  }
  final File file = File(args.isEmpty ? 'design/app.design.json' : args.first);
  final List<ValidationIssue> issues = validateFile(file);
  if (issues.isEmpty) {
    stdout.writeln('✓ válido');
    return;
  }
  for (int i = 0; i < issues.length; i++) {
    stderr.writeln('${i + 1}. ${issues[i]}');
  }
  exitCode = 1;
}
