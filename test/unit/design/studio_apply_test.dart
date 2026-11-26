// Tests unitarios de T27: adaptador seed → JSON, gate de validación y
// aplicación. Todas las escrituras ocurren en un directorio temporal; el
// repositorio real nunca recibe artefactos generados por estas pruebas.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/design/artifacts.dart'
    show designNodeToJson, generatedPaths, manifestV2Path;
import '../../../tool/design/compile.dart' show defaultDesignPath;
import '../../../tool/design/schema.dart';
import '../../../tool/design/studio/studio_apply.dart';
import '../../../tool/design/studio/studio_controller.dart'
    show StudioController, loadStudioDocument;
import '../../../tool/design/validate.dart' show ValidationIssue, arbFiles;

String _join(Directory root, List<String> parts) =>
    <String>[root.path, ...parts].join(Platform.pathSeparator);

/// Raíz temporal con las copias mínimas que exigen el validador y el compiler.
Directory _workspace() {
  final Directory root = Directory.systemTemp.createTempSync('retro-apply-');
  addTearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  final Directory l10n = Directory(_join(root, <String>['lib', 'l10n']))
    ..createSync(recursive: true);
  for (final String file in arbFiles) {
    File('lib/l10n/$file').copySync(_join(l10n, <String>[file]));
  }

  final Directory assets = Directory(_join(root, <String>['design', 'assets']))
    ..createSync(recursive: true);
  for (final File source in Directory(
    'design${Platform.pathSeparator}assets',
  ).listSync().whereType<File>()) {
    source.copySync(_join(assets, <String>[source.uri.pathSegments.last]));
  }

  final File definition = File(
    _join(root, <String>['tool', 'skins', 'definitions', 'lcd_classica.yaml']),
  )..parent.createSync(recursive: true);
  File('tool/skins/definitions/lcd_classica.yaml').copySync(definition.path);
  return root;
}

DesignSeed _seed() => loadStudioDocument();

DesignSeed _withBrokenToken() {
  final DesignSeed seed = _seed();
  final SkinSpec skin = seed.skins.first;
  final Map<String, Object?> tokens = Map<String, Object?>.from(skin.tokens);
  tokens['keyMinHeight'] = 44;
  final List<SkinSpec> skins = List<SkinSpec>.from(seed.skins);
  skins[0] = SkinSpec(
    id: skin.id,
    nameKey: skin.nameKey,
    isDefault: skin.isDefault,
    tokens: tokens,
    images: skin.images,
  );
  return DesignSeed(
    schemaVersion: seed.schemaVersion,
    version: seed.version,
    channels: seed.channels,
    skins: skins,
    images: seed.images,
    screens: seed.screens,
    profiles: seed.profiles,
    dimensions: seed.dimensions,
    sounds: seed.sounds,
    monetization: seed.monetization,
    publishing: seed.publishing,
  );
}

DesignSeed _withBrokenFormula() {
  final DesignSeed seed = _seed();
  final int index = seed.profiles.indexWhere(
    (ProfileSpec profile) => profile.id == 'igv',
  );
  final ProfileSpec profile = seed.profiles[index];
  final Map<String, String> formulas = Map<String, String>.from(
    profile.formulas,
  );
  formulas['resultado'] = 'base + (';
  final List<ProfileSpec> profiles = List<ProfileSpec>.from(seed.profiles);
  profiles[index] = ProfileSpec(
    id: profile.id,
    labelKey: profile.labelKey,
    capabilityId: profile.capabilityId,
    isScientific: profile.isScientific,
    defaultAngleMode: profile.defaultAngleMode,
    decimalDigits: profile.decimalDigits,
    inputs: profile.inputs,
    formulas: formulas,
    keyRows: profile.keyRows,
  );
  return DesignSeed(
    schemaVersion: seed.schemaVersion,
    version: seed.version,
    channels: seed.channels,
    skins: seed.skins,
    images: seed.images,
    screens: seed.screens,
    profiles: profiles,
    dimensions: seed.dimensions,
    sounds: seed.sounds,
    monetization: seed.monetization,
    publishing: seed.publishing,
  );
}

void _expectNothingWritten(Directory root) {
  expect(File(_join(root, defaultDesignPath.split('/'))).existsSync(), isFalse);
  for (final String path in <String>[...generatedPaths, manifestV2Path]) {
    expect(File(_join(root, path.split('/'))).existsSync(), isFalse);
  }
}

void main() {
  test('round-trip completo desde el documento real', () {
    final DesignSeed seed = _seed();
    final Map<String, Object?> json = studioSeedToJson(seed);

    expect(
      json.keys,
      containsAll(<String>[
        'schemaVersion',
        'version',
        'channels',
        'skins',
        'images',
        'screens',
        'profiles',
        'dimensions',
        'sounds',
        'monetization',
        'publishing',
      ]),
    );

    final DesignSeed rebuilt = DesignSeed.fromJson(
      jsonDecode(jsonEncode(json)),
    );
    expect(studioSeedToJson(rebuilt), equals(json));
    expect(
      rebuilt.screens['normal']!['mobile']!.map(designNodeToJson).toList(),
      equals(seed.screens['normal']!['mobile']!.map(designNodeToJson).toList()),
    );
  });

  test('validar un documento válido no escribe nada', () {
    final Directory root = _workspace();

    final StudioApplyResult result = applyStudioDocument(
      _seed(),
      projectRoot: root,
      write: false,
      formatOutput: false,
    );

    expect(result.ok, isTrue, reason: result.issues.toString());
    expect(result.issues, isEmpty);
    expect(result.written, isEmpty);
    _expectNothingWritten(root);
  });

  test('un token inválido bloquea diseño y artefactos', () {
    final Directory root = _workspace();

    final StudioApplyResult result = applyStudioDocument(
      _withBrokenToken(),
      projectRoot: root,
      formatOutput: false,
    );

    expect(result.ok, isFalse);
    expect(result.issues, isNotEmpty);
    expect(
      result.issues.map((ValidationIssue issue) => issue.path).join(' '),
      contains('keyMinHeight'),
    );
    expect(result.written, isEmpty);
    _expectNothingWritten(root);
  });

  test('una fórmula rota bloquea diseño y artefactos', () {
    final Directory root = _workspace();

    final StudioApplyResult result = applyStudioDocument(
      _withBrokenFormula(),
      projectRoot: root,
      formatOutput: false,
    );

    expect(result.ok, isFalse);
    expect(result.issues, isNotEmpty);
    expect(
      result.issues.map((ValidationIssue issue) => issue.path).join(' '),
      contains('profiles[2].formulas.resultado'),
    );
    expect(result.written, isEmpty);
    _expectNothingWritten(root);
  });

  test(
    'aplicar escribe JSON LF y los artefactos en el directorio temporal',
    () {
      final Directory root = _workspace();
      final DesignSeed seed = _seed();

      final StudioApplyResult result = applyStudioDocument(
        seed,
        projectRoot: root,
        formatOutput: false,
      );

      expect(result.ok, isTrue, reason: result.issues.toString());
      expect(result.written, containsAll(generatedPaths));
      expect(result.written, contains(manifestV2Path));

      final File design = File(_join(root, defaultDesignPath.split('/')));
      expect(design.existsSync(), isTrue);
      final String content = design.readAsStringSync();
      expect(content.contains('\r'), isFalse);
      expect(content.endsWith('\n'), isTrue);
      expect(content.endsWith('\n\n'), isFalse);
      expect(jsonDecode(content), equals(studioSeedToJson(seed)));
      for (final String path in <String>[...generatedPaths, manifestV2Path]) {
        expect(File(_join(root, path.split('/'))).existsSync(), isTrue);
      }
    },
  );

  test('el controller registra el flag write sin tocar el historial', () {
    bool? capturedWrite;
    final StudioController controller = StudioController(
      document: _seed(),
      applyCallback: (DesignSeed document, {required bool write}) {
        capturedWrite = write;
        return StudioApplyResult(
          issues: <ValidationIssue>[const ValidationIssue('ruta', 'mensaje')],
          written: const <String>[],
        );
      },
    );
    addTearDown(controller.dispose);

    int notifications = 0;
    controller.addListener(() => notifications++);

    final DesignSeed document = controller.document;
    expect(controller.canUndo, isFalse);
    expect(controller.applyIssues, isEmpty);
    expect(controller.appliedFiles, isEmpty);

    controller.applyDocument();
    expect(capturedWrite, isTrue);
    expect(controller.lastApplyResult, isNotNull);
    expect(controller.applyIssues.single.path, 'ruta');
    expect(controller.applyIssues.single.message, 'mensaje');
    expect(controller.appliedFiles, isEmpty);
    expect(controller.document, same(document));
    expect(controller.canUndo, isFalse);
    expect(controller.canRedo, isFalse);
    expect(notifications, 1);

    capturedWrite = null;
    controller.validateDocument();
    expect(capturedWrite, isFalse);
    expect(notifications, 2);
    expect(controller.canUndo, isFalse);
  });

  test('el controller conserva un designPath personalizado sin escribir', () {
    const String customPath = 'design/personalizado.design.json';
    final StudioController controller = StudioController(
      document: _seed(),
      designPath: customPath,
      applyCallback: (DesignSeed document, {required bool write}) =>
          const StudioApplyResult(
            issues: <ValidationIssue>[],
            written: <String>[],
          ),
    );
    addTearDown(controller.dispose);

    expect(controller.designPath, customPath);
    controller.applyDocument();
    expect(controller.appliedFiles, isEmpty);
    expect(controller.canUndo, isFalse);
  });
}
