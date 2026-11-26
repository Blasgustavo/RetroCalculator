// Tests unitarios de capas del RetroDesign Studio (T24, plan V4).
//
// Visibilidad y bloqueo son estado de edición indexado por ruta (ADR-0015):
// no se serializan en el spec. El reordenamiento sí muta el documento y debe
// remapear geometría, flags y selección para que sigan apuntando al mismo nodo.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/design/artifacts.dart' show designNodeToJson;
import '../../../tool/design/schema.dart';
import '../../../tool/design/studio/studio_controller.dart';
import '../../../tool/design/studio/studio_geometry.dart';

const String _seedJson = r'''
{
  "schemaVersion": 2,
  "version": 1,
  "channels": ["prod"],
  "skins": [],
  "images": [],
  "screens": {
    "normal": {
      "mobile": [
        {"type": "history", "titleKey": "capa.mobile"},
        {"type": "display", "key": "calc.display"},
        {"type": "padding", "titleKey": "panel", "children": [
          {"type": "key", "key": "calc.key.1"},
          {"type": "key", "key": "calc.key.2"}
        ]}
      ],
      "tablet": [{"type": "history", "titleKey": "capa.tablet"}],
      "desktop": [{"type": "history", "titleKey": "capa.desktop"}]
    }
  },
  "profiles": [],
  "dimensions": {
    "minTouchTarget": 48,
    "breakpoints": {"mobile": 0, "tablet": 600, "desktop": 1024}
  },
  "sounds": {"enabled": false, "events": {}},
  "monetization": {
    "ads": {
      "type": "rewarded",
      "enabled": false,
      "theme": {
        "buttonBackground": "#102030",
        "buttonForeground": "#FFFFFF",
        "copyKey": "ad.rewarded.copy"
      }
    },
    "catalog": {"productIds": {}, "priceCopyKeys": {}}
  },
  "publishing": {
    "channel": "prod",
    "baseUrl": "https://example.invalid",
    "publicKey": ""
  }
}
''';

DesignSeed _seed() => DesignSeed.fromJson(jsonDecode(_seedJson));

StudioController _controller() {
  final StudioController controller = StudioController(document: _seed());
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('estado de capas del Studio (T24)', () {
    test(
      'visibilidad y bloqueo son false por defecto, incluso en rutas inválidas',
      () {
        final StudioController controller = _controller();

        for (final String path in <String>['0', '1', '2.1', '', '99', 'x.y']) {
          expect(
            controller.isNodeHidden(path),
            isFalse,
            reason: 'hidden $path',
          );
          expect(
            controller.isNodeLocked(path),
            isFalse,
            reason: 'locked $path',
          );
          expect(
            controller.isNodeEffectivelyLocked(path),
            isFalse,
            reason: 'effective $path',
          );
        }
      },
    );

    test('los toggles notifican y las rutas inválidas son no-op', () {
      final StudioController controller = _controller();
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.setNodeHidden('1', true);
      expect(controller.isNodeHidden('1'), isTrue);
      controller.setNodeLocked('2.0', true);
      expect(controller.isNodeLocked('2.0'), isTrue);

      controller.setNodeHidden('99', true);
      controller.setNodeLocked('', true);
      expect(controller.isNodeHidden('99'), isFalse);
      expect(controller.isNodeLocked(''), isFalse);
      expect(notifications, 2, reason: 'solo los cambios válidos notifican');

      controller.setNodeHidden('1', false);
      controller.setNodeLocked('2.0', false);
      expect(controller.isNodeHidden('1'), isFalse);
      expect(controller.isNodeLocked('2.0'), isFalse);
      expect(notifications, 4);
    });

    test('un nodo bloqueado no puede cambiar su visibilidad', () {
      final StudioController controller = _controller();
      controller.setNodeHidden('1', true);
      controller.setNodeLocked('1', true);

      controller.setNodeHidden('1', false);

      expect(controller.isNodeHidden('1'), isTrue);
      // Desbloquear sí está permitido para recuperar el control del nodo.
      controller.setNodeLocked('1', false);
      controller.setNodeHidden('1', false);
      expect(controller.isNodeHidden('1'), isFalse);
    });

    test('el bloqueo de un ancestro afecta a sus descendientes', () {
      final StudioController controller = _controller();

      controller.setNodeLocked('2', true);

      expect(controller.isNodeEffectivelyLocked('2'), isTrue);
      expect(controller.isNodeEffectivelyLocked('2.0'), isTrue);
      expect(controller.isNodeEffectivelyLocked('2.1'), isTrue);
      expect(controller.isNodeEffectivelyLocked('2.c'), isTrue);
      expect(controller.isNodeEffectivelyLocked('1'), isFalse);
      expect(
        controller.isNodeLocked('2.0'),
        isFalse,
        reason: 'el flag propio del descendiente no cambia',
      );

      final StudioGeometry before = controller.geometryOf('2.0')!;
      controller.moveNode('2.0', dx: 15, dy: 15);
      controller.resizeNode(
        '2.0',
        StudioResizeHandle.bottomRight,
        dx: 20,
        dy: 20,
      );
      controller.setNodeGeometry(
        '2.0',
        const StudioGeometry(x: 0, y: 0, width: 200, height: 200),
      );
      controller.setNodeHidden('2.0', true);

      expect(controller.geometryOf('2.0'), before);
      expect(controller.isNodeHidden('2.0'), isFalse);
      expect(controller.canMoveLayer('2.0', up: false), isFalse);
    });

    test('moveLayer respeta límites, rutas inválidas y bloqueo', () {
      final StudioController controller = _controller();

      expect(controller.canMoveLayer('0', up: true), isFalse);
      expect(controller.canMoveLayer('2', up: false), isFalse);
      expect(controller.canMoveLayer('99', up: true), isFalse);
      expect(
        controller.canMoveLayer('2.c', up: true),
        isFalse,
        reason: 'un child único no tiene hermanos',
      );
      expect(controller.canMoveLayer('2.0', up: false), isTrue);
      expect(controller.canMoveLayer('2.1', up: true), isTrue);

      final String before = jsonEncode(controller.currentSpec);
      controller.moveLayer('0', up: true);
      controller.moveLayer('2', up: false);
      controller.moveLayer('99', up: true);
      expect(jsonEncode(controller.currentSpec), before);

      controller.setNodeLocked('1', true);
      expect(controller.canMoveLayer('1', up: true), isFalse);
      controller.moveLayer('1', up: true);
      expect(jsonEncode(controller.currentSpec), before);
    });

    test(
      'moveLayer reordena el spec y remapea geometría, flags y selección',
      () {
        final StudioController controller = _controller();
        controller.setNodeGeometry(
          '0',
          const StudioGeometry(x: 10, y: 20, width: 100, height: 60),
        );
        controller.setNodeGeometry(
          '1',
          const StudioGeometry(x: 30, y: 40, width: 110, height: 70),
        );
        final StudioGeometry historyGeometry = controller.geometryOf('0')!;
        final StudioGeometry displayGeometry = controller.geometryOf('1')!;
        controller.setNodeHidden('0', true);
        controller.setNodeLocked('1', true);
        controller.selectNode('0');

        // '0' no está bloqueado: al bajar, intercambia su ruta con '1'.
        controller.moveLayer('0', up: false);

        expect(controller.currentNodes[0].type, 'display');
        expect(controller.currentNodes[1].type, 'history');
        expect(
          controller.currentSpec[0],
          designNodeToJson(controller.currentNodes[0]),
        );
        expect(controller.geometryOf('0'), displayGeometry);
        expect(controller.geometryOf('1'), historyGeometry);
        expect(controller.isNodeHidden('1'), isTrue);
        expect(controller.isNodeHidden('0'), isFalse);
        expect(controller.isNodeLocked('0'), isTrue);
        expect(controller.isNodeLocked('1'), isFalse);
        expect(controller.selectedNodePath, '1');
        expect(controller.selectedNode?.type, 'history');
      },
    );

    test('moveLayer dentro de children remapea todo el subárbol', () {
      final StudioController controller = _controller();
      controller.setNodeHidden('2.0', true);
      controller.setNodeLocked('2.1', true);
      controller.selectNode('2.0');

      controller.moveLayer('2.0', up: false);

      final List<DesignNode> children = controller.currentNodes[2].children!;
      expect(children[0].key, 'calc.key.2');
      expect(children[1].key, 'calc.key.1');
      expect(controller.isNodeHidden('2.1'), isTrue);
      expect(controller.isNodeHidden('2.0'), isFalse);
      expect(controller.isNodeLocked('2.0'), isTrue);
      expect(controller.isNodeLocked('2.1'), isFalse);
      expect(controller.selectedNodePath, '2.1');
      expect(controller.selectedNode?.key, 'calc.key.1');
    });

    test('la geometría por defecto viaja con el nodo al reordenar', () {
      final StudioController controller = _controller();
      final StudioGeometry zero = controller.geometryOf('0')!;
      final StudioGeometry one = controller.geometryOf('1')!;
      controller.selectNode('0');

      controller.moveLayer('0', up: false);

      expect(controller.geometryOf('0'), one);
      expect(controller.geometryOf('1'), zero);
      expect(controller.selectedNodePath, '1');
    });

    test('ocultar un nodo no lo elimina del spec y conserva su geometría', () {
      final StudioController controller = _controller();
      final StudioGeometry geometry = controller.geometryOf('1')!;
      final List<Object?> spec = controller.currentSpec;

      controller.setNodeHidden('1', true);

      expect(controller.currentNodes.length, 3);
      expect(controller.currentSpec, spec);
      expect(controller.currentSpec[1], <String, Object?>{
        'type': 'display',
        'key': 'calc.display',
      });
      expect(controller.geometryOf('1'), geometry);

      controller.setNodeHidden('1', false);
      expect(controller.geometryOf('1'), geometry);
    });
  });
}
