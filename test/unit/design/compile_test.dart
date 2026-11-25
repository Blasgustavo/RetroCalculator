import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/design_system/generated/design_tokens.dart'
    as generated;
import 'package:retro_calculator/core/design_system/token_validation.dart'
    show validateTokens;

import '../../../tool/design/artifacts.dart';
import '../../../tool/design/compile.dart';
import '../../../tool/design/validate.dart';
import '../../../tool/skins/generate.dart' as legacy;

String _join(Directory root, List<String> parts) =>
    <String>[root.path, ...parts].join(Platform.pathSeparator);

String _lf(String value) => value.replaceAll('\r\n', '\n');

Directory _workspace({required String designJson}) {
  final Directory root = Directory.systemTemp.createTempSync('retro-compile-');
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

  File(_join(root, <String>['design', 'app.design.json']))
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(designJson);
  return root;
}

String _invalidDesign() {
  final Map<String, Object?> json =
      jsonDecode(File('design/app.design.json').readAsStringSync())
          as Map<String, Object?>;
  final Map<String, Object?> screens = json['screens']! as Map<String, Object?>;
  final Map<String, Object?> normal =
      screens['normal']! as Map<String, Object?>;
  final List<Object?> mobile = normal['mobile']! as List<Object?>;
  (mobile.first as Map<String, Object?>)['type'] = 'canvas';
  return jsonEncode(json);
}

void main() {
  test('rechaza una semilla inválida sin escribir artefactos', () {
    final Directory root = _workspace(designJson: _invalidDesign());

    final CompileReport report = compileDesign(
      projectRoot: root,
      formatOutput: false,
    );

    expect(report.ok, isFalse);
    expect(report.issues, isNotEmpty);
    expect(report.written, isEmpty);
    for (final String path in generatedPaths) {
      expect(File(_join(root, path.split('/'))).existsSync(), isFalse);
    }
    expect(
      File(
        _join(root, <String>['assets', 'catalog', 'manifest.v2.json']),
      ).existsSync(),
      isFalse,
    );
  });

  test('emite cinco artefactos y el manifiesto v2 con firma pendiente', () {
    final Directory root = _workspace(
      designJson: File('design/app.design.json').readAsStringSync(),
    );

    final CompileReport report = compileDesign(
      projectRoot: root,
      formatOutput: false,
    );

    expect(report.issues, isEmpty, reason: report.issues.toString());
    expect(report.ok, isTrue);
    expect(report.written, containsAll(generatedPaths));
    expect(report.written, contains('assets/catalog/manifest.v2.json'));

    final String designTokens = File(
      _join(root, generatedPaths.first.split('/')),
    ).readAsStringSync();
    expect(
      designTokens,
      contains('GENERADO: dart run tool/design/compile.dart'),
    );
    expect(designTokens, contains('generatedDefaultKeyMinHeight = 48'));
    expect(validateTokens(generated.generatedDefaultTokenValues), isEmpty);

    final Map<String, Object?> manifest =
        jsonDecode(
              File(
                _join(root, <String>['assets', 'catalog', 'manifest.v2.json']),
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    expect(
      manifest.keys,
      containsAll(<String>[
        'version',
        'channel',
        'entries',
        'assets',
        'signature',
      ]),
    );
    expect(manifest['version'], 1);
    expect(manifest['channel'], 'prod');
    expect(manifest['signature'], isEmpty);

    final List<Object?> entries = manifest['entries']! as List<Object?>;
    expect(
      entries.map((Object? e) => (e! as Map<String, Object?>)['id']),
      <Object?>['default', 'lcd_classica'],
    );
    for (final Object? entry in entries) {
      final Map<String, Object?> map = entry! as Map<String, Object?>;
      final String path = map['definition']! as String;
      final String definition = File(
        _join(root, path.split('/')),
      ).readAsStringSync().replaceAll('\r\n', '\n');
      expect(
        map['checksum'],
        legacy.checksumOf(definition),
        reason: 'checksum debe calcularse sobre la definición LF',
      );
    }
    final Map<String, Object?> lcd = entries.last as Map<String, Object?>;
    expect(
      lcd['checksum'],
      '26d270cf605e455cbbe2f970d915dfefcd18bae6e9dc7b089220e97669bc77aa',
    );

    final Map<String, Object?> assets =
        manifest['assets']! as Map<String, Object?>;
    expect((assets['images'] as List<Object?>), hasLength(1));
    expect((assets['sounds'] as List<Object?>), hasLength(4));

    expect(
      File(
        _join(root, <String>['assets', 'catalog', 'manifest.json']),
      ).existsSync(),
      isFalse,
      reason: 'el compiler no reescribe el manifiesto v1',
    );
  });

  test('dos compilaciones consecutivas producen bytes idénticos', () {
    final Directory root = _workspace(
      designJson: File('design/app.design.json').readAsStringSync(),
    );

    compileDesign(projectRoot: root, formatOutput: false);
    final Map<String, String> first = <String, String>{
      for (final String path in <String>[...generatedPaths, manifestV2Path])
        path: File(_join(root, path.split('/'))).readAsStringSync(),
    };
    compileDesign(projectRoot: root, formatOutput: false);
    final Map<String, String> second = <String, String>{
      for (final String path in <String>[...generatedPaths, manifestV2Path])
        path: File(_join(root, path.split('/'))).readAsStringSync(),
    };

    expect(second, equals(first));
  });

  test(
    'el generador v1 conserva el contenido LF del manifiesto y los tokens',
    () {
      final legacy.LegacySkinDefinition definition = legacy
          .readLegacySkinDefinition(root: Directory.current);

      // En Windows el checkout puede materializar CRLF; el contenido canónico
      // del repositorio es LF y es lo que compara esta prueba.
      expect(
        '${jsonEncode(legacy.buildLegacyManifest(definition))}\n',
        _lf(File('assets/catalog/manifest.json').readAsStringSync()),
      );
      expect(
        legacy.renderLegacySkinTokens(definition),
        _lf(
          File(
            'lib/core/design_system/generated/skin_tokens_lcd_classica.dart',
          ).readAsStringSync(),
        ),
      );
      final Map<String, Object?> legacyManifest = legacy.buildLegacyManifest(
        definition,
      );
      final Map<String, Object?> entry =
          (legacyManifest['entries']! as List<Object?>).single
              as Map<String, Object?>;
      expect(
        entry['checksum'],
        '26d270cf605e455cbbe2f970d915dfefcd18bae6e9dc7b089220e97669bc77aa',
      );
    },
  );
}
