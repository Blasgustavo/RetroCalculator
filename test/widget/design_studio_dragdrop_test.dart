// Tests de drag & drop del RetroDesign Studio (T22, plan V4).
//
// El arranque se simula con un puntero sintético sobre la entrada de la paleta
// y el soltado sobre el canvas; el documento se inyecta como `DesignSeed`
// construido desde JSON local, sin red, plugins nativos ni entitlements.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/design/schema.dart';
import '../../tool/design/studio/studio_app.dart';
import '../../tool/design/studio/studio_controller.dart';

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
    },
    "scientific": {
      "mobile": [{"type": "history", "titleKey": "cientifica.mobile"}]
    }
  },
  "profiles": [],
  "dimensions": {
    "minTouchTarget": 48,
    "breakpoints": {"mobile": 0, "tablet": 600, "desktop": 900}
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

const Key _paletteKey = Key('studio.palette');
const Key _canvasKey = Key('studio.canvas');
const Key _dropZoneKey = Key('studio.canvas.dropZone');
const Key _layersKey = Key('studio.layers');
const Key _inspectorKey = Key('studio.inspector');

BoxDecoration _canvasDecoration(WidgetTester tester, Finder dropZone) {
  final DecoratedBox box = tester.widget<DecoratedBox>(dropZone);
  return box.decoration as BoxDecoration;
}

void main() {
  test('addNode añade el nodo al final, lo selecciona y devuelve su ruta', () {
    final DesignSeed document = _seed();
    final StudioController controller = StudioController(document: document);
    addTearDown(controller.dispose);

    final String? path = controller.addNode('display');

    expect(path, '1');
    expect(controller.currentNodes.length, 2);
    expect(controller.currentNodes.last.type, 'display');
    expect(controller.selectedNodePath, path);
    expect(controller.selectedNode?.type, 'display');
  });

  test('addNode con un tipo fuera de la whitelist no muta el documento', () {
    final DesignSeed document = _seed();
    final StudioController controller = StudioController(document: document);
    addTearDown(controller.dispose);
    final int before = document.screens['normal']!['mobile']!.length;

    final String? path = controller.addNode('customCode');

    expect(path, isNull);
    expect(document.screens['normal']!['mobile']!.length, before);
    expect(controller.currentNodes.length, before);
    expect(controller.selectedNodePath, isEmpty);
    expect(controller.selectedNode, isNull);
  });

  testWidgets(
    'arrastrar una entrada de la paleta al canvas añade un nodo válido',
    (WidgetTester tester) async {
      final DesignSeed document = _seed();
      final List<DesignNode> nodes = document.screens['normal']!['mobile']!;
      final int initialCount = nodes.length;

      await tester.pumpWidget(StudioApp(document: document));

      final Finder paletteEntry = find.descendant(
        of: find.byKey(_paletteKey),
        matching: find.text('padding'),
      );
      final Finder canvas = find.byKey(_canvasKey);
      final Finder dropZone = find.descendant(
        of: canvas,
        matching: find.byKey(_dropZoneKey),
      );
      final BoxDecoration resting = _canvasDecoration(tester, dropZone);

      // Arranque sobre la paleta y soltado sobre el centro del canvas.
      final Offset start = tester.getCenter(paletteEntry);
      final TestGesture gesture = await tester.startGesture(start);
      await tester.pump();

      await gesture.moveTo(tester.getCenter(canvas));
      await tester.pump();

      // Feedback visual durante el drag: nodo fantasma en el overlay y
      // resaltado del canvas mientras el tipo está encima.
      expect(find.text('padding'), findsNWidgets(2));
      final BoxDecoration hovering = _canvasDecoration(tester, dropZone);
      expect(
        hovering,
        isNot(resting),
        reason: 'el canvas debe resaltarse con el drag encima',
      );

      await gesture.up();
      await tester.pump();

      // El breakpoint gana un nodo y su tipo pertenece a la whitelist.
      expect(nodes.length, initialCount + 1);
      expect(nodes.last.type, 'padding');
      expect(designNodeTypes.contains(nodes.last.type), isTrue);

      // El nodo nuevo aparece en capas y queda seleccionado en el inspector.
      expect(
        find.descendant(
          of: find.byKey(_layersKey),
          matching: find.text('padding'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(_inspectorKey),
          matching: find.text('Tipo: padding'),
        ),
        findsOneWidget,
      );
      expect(
        _canvasDecoration(tester, dropZone),
        resting,
        reason: 'al soltar vuelve el aspecto en reposo del canvas',
      );
    },
  );
}
