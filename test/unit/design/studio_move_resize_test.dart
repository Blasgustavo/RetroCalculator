// Tests unitarios de move/resize del RetroDesign Studio (T23, plan V4).
//
// La geometría del canvas es estado del Studio y vive fuera del `DesignNode`
// (inmutable) y fuera de `SpecRenderer` (render puro): aquí se verifican los
// límites, el snapping configurable y la invariante de 48 dp.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/widgets/spec_renderer.dart';

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
      "mobile": [{"type": "history", "titleKey": "capa.mobile"}],
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

void main() {
  group('geometría del canvas del Studio', () {
    test('addNode crea geometría dentro del frame del breakpoint', () {
      final DesignSeed document = _seed();
      final StudioController controller = StudioController(document: document);
      addTearDown(controller.dispose);

      final String? path = controller.addNode('key');

      expect(path, '1');
      final StudioGeometry? geometry = controller.geometryOf(path!);
      expect(geometry, isNotNull);
      final Size frame = studioFrameSize(document, 'mobile');
      expect(geometry!.x, greaterThanOrEqualTo(0));
      expect(geometry.y, greaterThanOrEqualTo(0));
      expect(geometry.x + geometry.width, lessThanOrEqualTo(frame.width));
      expect(geometry.y + geometry.height, lessThanOrEqualTo(frame.height));
      expect(geometry.width, greaterThanOrEqualTo(seedMinTouchTarget));
      expect(geometry.height, greaterThanOrEqualTo(seedMinTouchTarget));
      expect(controller.selectedGeometry, geometry);
    });

    test('mover actualiza x/y y respeta los bordes del frame', () {
      final DesignSeed document = _seed();
      final StudioController controller = StudioController(document: document);
      addTearDown(controller.dispose);
      controller.addNode('display');
      final StudioGeometry before = controller.geometryOf('1')!;

      controller.moveNode('1', dx: 12.5, dy: -4.25);

      final StudioGeometry moved = controller.geometryOf('1')!;
      expect(moved.x, closeTo(before.x + 12.5, 1e-9));
      expect(moved.y, closeTo(before.y - 4.25, 1e-9));

      controller.moveNode('1', dx: -10000, dy: 10000);
      final StudioGeometry clamped = controller.geometryOf('1')!;
      final Size frame = studioFrameSize(document, 'mobile');
      expect(clamped.x, 0);
      expect(clamped.y + clamped.height, closeTo(frame.height, 1e-9));
    });

    test('el snapping es configurable y sin él se conserva la precisión', () {
      final StudioController controller = StudioController(document: _seed());
      addTearDown(controller.dispose);
      controller.addNode('display');
      final StudioGeometry initial = controller.geometryOf('1')!;

      expect(controller.snappingEnabled, isFalse);
      controller.moveNode('1', dx: 7.3, dy: 3.7);
      expect(
        controller.geometryOf('1')!.x,
        closeTo(initial.x + 7.3, 1e-9),
        reason: 'sin snapping se conserva la coma flotante exacta',
      );

      controller.setSnapGrid(8);
      controller.setSnapping(true);
      controller.moveNode('1', dx: 7.3, dy: 3.7);
      final StudioGeometry snapped = controller.geometryOf('1')!;
      expect(snapped.x % 8, 0);
      expect(snapped.y % 8, 0);

      controller.setSnapping(false);
      final StudioGeometry precise = controller.geometryOf('1')!;
      controller.moveNode('1', dx: 1.1, dy: 2.2);
      expect(controller.geometryOf('1')!.x, closeTo(precise.x + 1.1, 1e-9));
    });

    test('redimensionar actualiza width/height y nunca baja de 48 dp', () {
      final DesignSeed document = _seed();
      final StudioController controller = StudioController(document: document);
      addTearDown(controller.dispose);
      controller.addNode('key');
      final StudioGeometry initial = controller.geometryOf('1')!;

      controller.resizeNode(
        '1',
        StudioResizeHandle.bottomRight,
        dx: 40,
        dy: 30,
      );
      final StudioGeometry grown = controller.geometryOf('1')!;
      expect(grown.width, closeTo(initial.width + 40, 1e-9));
      expect(grown.height, closeTo(initial.height + 30, 1e-9));

      controller.resizeNode(
        '1',
        StudioResizeHandle.bottomRight,
        dx: -10000,
        dy: -10000,
      );
      final StudioGeometry tiny = controller.geometryOf('1')!;
      expect(tiny.width, greaterThanOrEqualTo(seedMinTouchTarget));
      expect(tiny.height, greaterThanOrEqualTo(seedMinTouchTarget));

      controller.resizeNode(
        '1',
        StudioResizeHandle.topLeft,
        dx: 10000,
        dy: 10000,
      );
      final StudioGeometry inverted = controller.geometryOf('1')!;
      expect(inverted.width, greaterThanOrEqualTo(seedMinTouchTarget));
      expect(inverted.height, greaterThanOrEqualTo(seedMinTouchTarget));
      final Size frame = studioFrameSize(document, 'mobile');
      expect(inverted.x, greaterThanOrEqualTo(0));
      expect(inverted.y, greaterThanOrEqualTo(0));
      expect(inverted.x + inverted.width, lessThanOrEqualTo(frame.width));
      expect(inverted.y + inverted.height, lessThanOrEqualTo(frame.height));
    });

    test('resize de una key conserva keyMinHeight y la serialización', () {
      final StudioController controller = StudioController(document: _seed());
      addTearDown(controller.dispose);
      controller.addNode('key');

      controller.resizeNode('1', StudioResizeHandle.bottom, dy: -1000);

      expect(controller.geometryOf('1')!.height, seedMinTouchTarget);
      final Map<String, Object?> layout = controller.serializeLayout();
      final Map<String, Object?> nodes =
          layout['nodes'] as Map<String, Object?>;
      final Map<String, Object?> serialized =
          nodes['1'] as Map<String, Object?>;
      expect(serialized['height'], seedMinTouchTarget);
      expect(jsonEncode(layout), isA<String>());
    });

    test('serializar fuerza la invariante incluso con geometría inválida', () {
      final StudioController controller = StudioController(document: _seed());
      addTearDown(controller.dispose);
      controller.addNode('key');

      controller.setNodeGeometry(
        '1',
        const StudioGeometry(x: -20, y: -30, width: 10, height: 12),
      );

      final StudioGeometry clamped = controller.geometryOf('1')!;
      expect(clamped.x, 0);
      expect(clamped.y, 0);
      expect(clamped.width, seedMinTouchTarget);
      expect(clamped.height, seedMinTouchTarget);

      final Map<String, Object?> layout = controller.serializeLayout();
      expect(layout['screen'], 'normal');
      expect(layout['breakpoint'], 'mobile');
      final Map<String, Object?> nodes =
          layout['nodes'] as Map<String, Object?>;
      for (final Object? value in nodes.values) {
        final Map<String, Object?> geometry = value as Map<String, Object?>;
        expect(geometry['width'], greaterThanOrEqualTo(seedMinTouchTarget));
        expect(geometry['height'], greaterThanOrEqualTo(seedMinTouchTarget));
      }
    });

    test(
      'el spec sigue siendo datos: SpecRenderer no guarda estado en el nodo',
      () {
        final StudioController controller = StudioController(document: _seed());
        addTearDown(controller.dispose);
        controller.addNode('key');
        controller.moveNode('1', dx: 10, dy: 10);

        const SpecRenderer renderer = SpecRenderer(
          nodes: <Object?>[],
          renderContext: SpecRenderContext(),
        );
        expect(renderer, isA<StatelessWidget>());

        final Map<String, Object?> json = designNodeToJson(
          const DesignNode(type: 'key', key: 'calc.key.1', value: 7),
        );
        expect(json, <String, Object?>{
          'type': 'key',
          'key': 'calc.key.1',
          'value': 7,
        }, reason: 'el nodo del spec no incorpora x/y/width/height');

        final List<Object?> spec = controller.currentSpec;
        expect(
          spec,
          controller.currentNodes.map(designNodeToJson).toList(),
          reason: 'el spec emitido sigue siendo el del compilador',
        );
        for (final Object? raw in spec) {
          final Map<String, Object?> node = raw as Map<String, Object?>;
          expect(node.containsKey('x'), isFalse);
          expect(node.containsKey('y'), isFalse);
          expect(node.containsKey('width'), isFalse);
        }
      },
    );
  });
}
