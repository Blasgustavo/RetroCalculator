// Tests de widget de undo/redo del RetroDesign Studio (T26, plan V4).
//
// Cubren los botones con keys deterministas, los atajos de teclado propios y
// la agrupación de una sesión de edición del inspector en una sola entrada.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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
      "mobile": [{"type": "display", "key": "calc.display"}],
      "tablet": [{"type": "display", "key": "calc.display"}],
      "desktop": [{"type": "display", "key": "calc.display"}]
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

Future<void> _pump(WidgetTester tester, StudioController controller) =>
    tester.pumpWidget(StudioApp(document: _seed(), controller: controller));

const Key _undoKey = Key('studio.undo');
const Key _redoKey = Key('studio.redo');

void main() {
  group('undo/redo en el shell del Studio (T26)', () {
    testWidgets('los botones se habilitan y deshacer/restaurar funciona', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      await _pump(tester, controller);

      expect(find.byKey(_undoKey), findsOneWidget);
      expect(find.byKey(_redoKey), findsOneWidget);
      expect(tester.widget<IconButton>(find.byKey(_undoKey)).onPressed, isNull);
      expect(tester.widget<IconButton>(find.byKey(_redoKey)).onPressed, isNull);

      controller.setNodeProperty('0', 'key', 'calc.display.new');
      await tester.pump();
      expect(
        tester.widget<IconButton>(find.byKey(_undoKey)).onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(_undoKey));
      await tester.pump();
      expect(controller.currentNodes.first.key, 'calc.display');
      expect(
        tester.widget<IconButton>(find.byKey(_redoKey)).onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(_redoKey));
      await tester.pump();
      expect(controller.currentNodes.first.key, 'calc.display.new');
    });

    testWidgets('Ctrl+Z deshace y Ctrl+Shift+Z rehace', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      await _pump(tester, controller);
      controller.setNodeProperty('0', 'key', 'calc.display.new');
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect(controller.currentNodes.first.key, 'calc.display');

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect(controller.currentNodes.first.key, 'calc.display.new');
    });

    testWidgets('Ctrl+Y rehace', (WidgetTester tester) async {
      final StudioController controller = _controller();
      await _pump(tester, controller);
      controller.setNodeProperty('0', 'key', 'nueva');
      controller.undo();
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyY);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect(controller.currentNodes.first.key, 'nueva');
    });

    testWidgets('arrastrar un nodo con varios eventos crea un solo undo', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      controller.addNode('display');
      await _pump(tester, controller);
      final StudioGeometry before = controller.geometryOf('1')!;

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('studio.node.1'))),
      );
      await gesture.moveBy(const Offset(8, 4));
      await tester.pump();
      await gesture.moveBy(const Offset(8, 4));
      await tester.pump();
      await gesture.moveBy(const Offset(8, 4));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(controller.geometryOf('1')!.x, closeTo(before.x + 24, 1e-6));
      controller.undo();
      expect(controller.geometryOf('1'), before);
    });

    testWidgets('editar un campo del inspector agrupa toda la sesión', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      controller.selectNode('0');
      await _pump(tester, controller);

      final Finder field = find.byKey(const Key('studio.inspector.node.key'));
      tester.widget<TextField>(field).focusNode!.requestFocus();
      await tester.pump();

      await tester.enterText(field, 'a');
      await tester.enterText(field, 'ab');
      await tester.enterText(field, 'abc');
      await tester.pump();
      expect(controller.currentNodes.first.key, 'abc');

      tester.widget<TextField>(field).focusNode!.unfocus();
      await tester.pump();

      controller.undo();
      expect(controller.currentNodes.first.key, 'calc.display');
      expect(controller.canUndo, isFalse);
    });
  });
}
