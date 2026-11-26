// Tests de widget de move/resize del RetroDesign Studio (T23, plan V4).
//
// El canvas envuelve cada nodo con una caja interactiva y sus manillas sin
// tocar `SpecRenderer`: el renderer sigue dibujando el mismo JSON del spec.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/widgets/spec_renderer.dart';

import '../../tool/design/schema.dart';
import '../../tool/design/studio/studio_app.dart';
import '../../tool/design/studio/studio_controller.dart';
import '../../tool/design/studio/studio_geometry.dart';

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

const Key _canvasKey = Key('studio.canvas');
const Key _node0 = Key('studio.node.0');
const Key _node1 = Key('studio.node.1');

Key _handle(String path, String name) => Key('studio.handle.$path.$name');

void main() {
  testWidgets('seleccionar un nodo muestra sus manillas sin romper el render', (
    WidgetTester tester,
  ) async {
    final DesignSeed document = _seed();
    final StudioController controller = StudioController(document: document);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      StudioApp(document: document, controller: controller),
    );

    expect(controller.selectedNodePath, isEmpty);
    expect(find.byKey(_handle('0', 'bottomRight')), findsNothing);
    expect(find.byType(SpecRenderer), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(_canvasKey),
        matching: find.text('capa.mobile'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(_node0));
    await tester.pump();

    expect(controller.selectedNodePath, '0');
    expect(find.byKey(_handle('0', 'bottomRight')), findsOneWidget);
    expect(find.byKey(_handle('0', 'topLeft')), findsOneWidget);
  });

  testWidgets('arrastrar un nodo mueve sus coordenadas x/y', (
    WidgetTester tester,
  ) async {
    final DesignSeed document = _seed();
    final StudioController controller = StudioController(document: document);
    addTearDown(controller.dispose);
    controller.addNode('display');
    await tester.pumpWidget(
      StudioApp(document: document, controller: controller),
    );
    final StudioGeometry before = controller.geometryOf('1')!;

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_node1)),
    );
    await gesture.moveBy(const Offset(24, 16));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final StudioGeometry after = controller.geometryOf('1')!;
    expect(after.x, closeTo(before.x + 24, 1e-6));
    expect(after.y, closeTo(before.y + 16, 1e-6));
  });

  testWidgets('arrastrar la manilla inferior derecha cambia width/height', (
    WidgetTester tester,
  ) async {
    final DesignSeed document = _seed();
    final StudioController controller = StudioController(document: document);
    addTearDown(controller.dispose);
    controller.addNode('key');
    await tester.pumpWidget(
      StudioApp(document: document, controller: controller),
    );
    final StudioGeometry before = controller.geometryOf('1')!;

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_handle('1', 'bottomRight'))),
    );
    await gesture.moveBy(const Offset(30, 24));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final StudioGeometry after = controller.geometryOf('1')!;
    expect(after.width, closeTo(before.width + 30, 1e-6));
    expect(after.height, closeTo(before.height + 24, 1e-6));
  });

  testWidgets('la manilla nunca reduce una key por debajo de 48 dp', (
    WidgetTester tester,
  ) async {
    final DesignSeed document = _seed();
    final StudioController controller = StudioController(document: document);
    addTearDown(controller.dispose);
    controller.addNode('key');
    await tester.pumpWidget(
      StudioApp(document: document, controller: controller),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_handle('1', 'bottomRight'))),
    );
    await gesture.moveBy(const Offset(-100, -40));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final StudioGeometry after = controller.geometryOf('1')!;
    expect(after.width, greaterThanOrEqualTo(seedMinTouchTarget));
    expect(after.height, greaterThanOrEqualTo(seedMinTouchTarget));
  });
}
