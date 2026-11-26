// Tests unitarios de T28: persistencia canónica del Studio. Todas las
// escrituras ocurren en un directorio temporal; el repositorio real nunca
// recibe artefactos generados por estas pruebas.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/design/artifacts.dart' show designNodeToJson;
import '../../../tool/design/schema.dart';
import '../../../tool/design/studio/studio_apply.dart' show studioSeedToJson;
import '../../../tool/design/studio/studio_controller.dart'
    show StudioController, loadStudioDocument, studioDefaultDesignPath;
import '../../../tool/design/studio/studio_persistence.dart';

String _join(Directory root, List<String> parts) =>
    <String>[root.path, ...parts].join(Platform.pathSeparator);

Directory _workspace() {
  final Directory root = Directory.systemTemp.createTempSync('retro-persist-');
  addTearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });
  return root;
}

File _designFile(Directory root) =>
    File(_join(root, studioDefaultDesignPath.split('/')));

DesignSeed _seed() => loadStudioDocument();

DesignSeed _replacementSeed() => DesignSeed.fromJson(<String, Object?>{
  'schemaVersion': 2,
  'version': 99,
  'channels': <Object?>['prod'],
  'skins': <Object?>[],
  'images': <Object?>[],
  'screens': <String, Object?>{
    'normal': <String, Object?>{
      'mobile': <Object?>[
        <String, Object?>{'type': 'history', 'titleKey': 'recargado'},
      ],
    },
  },
  'profiles': <Object?>[],
  'dimensions': <String, Object?>{
    'minTouchTarget': 48,
    'breakpoints': <String, Object?>{
      'mobile': 0,
      'tablet': 600,
      'desktop': 1024,
    },
  },
  'sounds': <String, Object?>{'enabled': false, 'events': <String, Object?>{}},
  'monetization': <String, Object?>{
    'ads': <String, Object?>{
      'type': 'rewarded',
      'enabled': false,
      'theme': <String, Object?>{
        'buttonBackground': '#102030',
        'buttonForeground': '#FFFFFF',
        'copyKey': 'ad.rewarded.copy',
      },
    },
    'catalog': <String, Object?>{
      'productIds': <String, Object?>{},
      'priceCopyKeys': <String, Object?>{},
    },
  },
  'publishing': <String, Object?>{
    'channel': 'prod',
    'baseUrl': 'https://example.invalid',
    'publicKey': '',
  },
});

void main() {
  test('guardar escribe JSON canónico con LF y un solo salto final', () {
    final Directory root = _workspace();
    final DesignSeed seed = _seed();

    final StudioSaveResult result = saveStudioDocument(seed, projectRoot: root);

    final File file = _designFile(root);
    expect(file.existsSync(), isTrue);
    final String content = file.readAsStringSync();
    expect(content, equals(studioEncodeDocument(seed)));
    expect(content.contains('\r'), isFalse);
    expect(content.endsWith('\n'), isTrue);
    expect(content.endsWith('\n\n'), isFalse);
    expect(jsonDecode(content), equals(studioSeedToJson(seed)));
    expect(result.path, file.path);
    expect(result.bytes, utf8.encode(content).length);
    expect(result.ok, isTrue);
  });

  test('sobrescribir un archivo con CRLF lo normaliza a LF', () {
    final Directory root = _workspace();
    final DesignSeed seed = _seed();
    final File file = _designFile(root)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('{\r\n  "schemaVersion": 2\r\n}\r\n\r\n');

    final StudioSaveResult result = saveStudioDocument(seed, projectRoot: root);

    final String content = file.readAsStringSync();
    expect(content.contains('\r'), isFalse);
    expect(content.endsWith('\n\n'), isFalse);
    expect(content, equals(studioEncodeDocument(seed)));
    expect(result.bytes, utf8.encode(content).length);
  });

  test('recargar hace round-trip del documento real', () {
    final Directory root = _workspace();
    final DesignSeed seed = _seed();
    saveStudioDocument(seed, projectRoot: root);

    final DesignSeed reloaded = loadStudioDocumentFromDisk(projectRoot: root);

    expect(studioSeedToJson(reloaded), equals(studioSeedToJson(seed)));
    expect(
      reloaded.screens['normal']!['mobile']!.map(designNodeToJson).toList(),
      equals(seed.screens['normal']!['mobile']!.map(designNodeToJson).toList()),
    );
  });

  test('una ruta relativa se resuelve dentro de projectRoot', () {
    final Directory root = _workspace();
    final DesignSeed seed = _seed();

    final StudioSaveResult result = saveStudioDocument(seed, projectRoot: root);

    expect(result.path, _designFile(root).path);
    expect(_designFile(root).existsSync(), isTrue);
  });

  test('una ruta absoluta se usa tal cual, fuera de projectRoot', () {
    final Directory root = _workspace();
    final Directory other = _workspace();
    final File absolute = File(_join(other, <String>['abs.design.json']));
    final DesignSeed seed = _seed();

    final StudioSaveResult result = saveStudioDocument(
      seed,
      projectRoot: root,
      designPath: absolute.path,
    );

    expect(result.path, absolute.path);
    expect(absolute.existsSync(), isTrue);
    expect(
      jsonDecode(absolute.readAsStringSync()),
      equals(studioSeedToJson(seed)),
    );
    expect(_designFile(root).existsSync(), isFalse);
  });

  test('recargar un archivo ausente o vacío lanza StateError legible', () {
    final Directory root = _workspace();

    expect(
      () => loadStudioDocumentFromDisk(projectRoot: root),
      throwsA(
        isA<StateError>().having(
          (StateError error) => error.message,
          'message',
          contains('app.design.json'),
        ),
      ),
    );

    final File file = _designFile(root)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('   \n');
    expect(
      () => loadStudioDocumentFromDisk(projectRoot: root),
      throwsA(
        isA<StateError>().having(
          (StateError error) => error.message,
          'message',
          contains(file.path),
        ),
      ),
    );
  });

  test(
    'el controller captura guardado y recarga sin tocar el undo al guardar',
    () {
      final DesignSeed seed = _seed();
      DesignSeed? captured;
      bool loadCalled = false;
      const StudioSaveResult saved = StudioSaveResult(
        path: 'design/app.design.json',
        bytes: 1234,
      );
      final DesignSeed replacement = _replacementSeed();
      final StudioController controller = StudioController(
        document: seed,
        saveCallback: (DesignSeed document) {
          captured = document;
          return saved;
        },
        reloadCallback: () {
          loadCalled = true;
          return replacement;
        },
      );
      addTearDown(controller.dispose);

      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.addNode('display');
      expect(controller.canUndo, isTrue);
      final DesignSeed edited = controller.document;
      final int afterEdit = notifications;

      controller.saveDocument();
      expect(captured, same(edited));
      expect(controller.lastSaveResult, same(saved));
      expect(
        controller.persistenceStatus,
        'Guardado: design/app.design.json (1234 bytes)',
      );
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);
      expect(notifications, afterEdit + 1);

      controller.reloadDocument();
      expect(loadCalled, isTrue);
      expect(controller.document, same(replacement));
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
      expect(controller.persistenceStatus, 'Recargado: design/app.design.json');
      expect(notifications, afterEdit + 2);
    },
  );

  test('un fallo de carga se propaga y deja el documento intacto', () {
    final DesignSeed seed = _seed();
    final StudioController controller = StudioController(
      document: seed,
      reloadCallback: () => throw StateError('sin archivo'),
    );
    addTearDown(controller.dispose);

    expect(() => controller.reloadDocument(), throwsStateError);
    expect(controller.document, same(seed));
    expect(controller.persistenceStatus, isNull);
  });
}
