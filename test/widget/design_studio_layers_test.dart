// Tests de widget del panel de capas del RetroDesign Studio (T24, plan V4).
//
// Ocultar quita la caja del canvas pero no la fila del árbol ni el nodo del
// spec; bloquear deshabilita gestos y botones; subir/bajar reordena el spec.

import 'dart:convert';

import 'package:flutter/material.dart';
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

const Key _layersKey = Key('studio.layers');
const Key _inspectorKey = Key('studio.inspector');

IconData _iconOf(WidgetTester tester, Key key) {
  final IconButton button = tester.widget<IconButton>(find.byKey(key));
  return (button.icon as Icon).icon!;
}

String? _tooltipOf(WidgetTester tester, Key key) =>
    tester.widget<IconButton>(find.byKey(key)).tooltip;

bool _enabled(WidgetTester tester, Key key) =>
    tester.widget<IconButton>(find.byKey(key)).onPressed != null;

/// Todas las manillas de resize de una ruta, no solo una de las ocho.
Finder _handlesFor(String path) => find.byWidgetPredicate((Widget widget) {
  final Key? key = widget.key;
  return key is ValueKey<String> &&
      key.value.startsWith('studio.handle.$path.');
});

Future<void> _pumpStudio(
  WidgetTester tester,
  StudioController controller,
) async {
  await tester.pumpWidget(StudioApp(document: _seed(), controller: controller));
}

StudioController _controller() {
  final StudioController controller = StudioController(document: _seed());
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('panel de capas del Studio (T24)', () {
    testWidgets(
      'cada fila expone ojo, candado, subir y bajar con keys y tooltips',
      (WidgetTester tester) async {
        final StudioController controller = _controller();
        await _pumpStudio(tester, controller);

        for (final String path in <String>['0', '1', '2', '2.0', '2.1']) {
          expect(
            find.byKey(Key('studio.layer.eye.$path')),
            findsOneWidget,
            reason: 'ojo de $path',
          );
          expect(find.byKey(Key('studio.layer.lock.$path')), findsOneWidget);
          expect(find.byKey(Key('studio.layer.up.$path')), findsOneWidget);
          expect(find.byKey(Key('studio.layer.down.$path')), findsOneWidget);
        }

        expect(
          _iconOf(tester, const Key('studio.layer.eye.0')),
          Icons.visibility,
        );
        expect(_tooltipOf(tester, const Key('studio.layer.eye.0')), 'Ocultar');
        expect(
          _iconOf(tester, const Key('studio.layer.lock.0')),
          Icons.lock_open,
        );
        expect(
          _tooltipOf(tester, const Key('studio.layer.lock.0')),
          'Bloquear',
        );
        expect(_enabled(tester, const Key('studio.layer.up.0')), isFalse);
        expect(_enabled(tester, const Key('studio.layer.down.2')), isFalse);
        expect(_enabled(tester, const Key('studio.layer.up.1')), isTrue);
      },
    );

    testWidgets('ocultar quita la caja del canvas pero conserva fila y spec', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      final StudioGeometry geometry = controller.geometryOf('0')!;
      final String spec = jsonEncode(controller.currentSpec);
      await _pumpStudio(tester, controller);

      expect(find.byKey(const Key('studio.node.0')), findsOneWidget);

      await tester.tap(find.byKey(const Key('studio.layer.eye.0')));
      await tester.pump();

      expect(find.byKey(const Key('studio.node.0')), findsNothing);
      expect(
        find.byKey(const Key('studio.handle.0.bottomRight')),
        findsNothing,
      );
      expect(
        _iconOf(tester, const Key('studio.layer.eye.0')),
        Icons.visibility_off,
      );
      expect(_tooltipOf(tester, const Key('studio.layer.eye.0')), 'Mostrar');
      expect(
        find.descendant(
          of: find.byKey(_layersKey),
          matching: find.text('history capa.mobile'),
        ),
        findsOneWidget,
      );
      expect(jsonEncode(controller.currentSpec), spec);
      expect(controller.geometryOf('0'), geometry);

      await tester.tap(find.byKey(const Key('studio.layer.eye.0')));
      await tester.pump();

      expect(find.byKey(const Key('studio.node.0')), findsOneWidget);
      expect(controller.geometryOf('0'), geometry);
    });

    testWidgets('bloquear impide arrastrar pero permite seleccionar', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      await _pumpStudio(tester, controller);
      final StudioGeometry before = controller.geometryOf('1')!;

      await tester.tap(find.byKey(const Key('studio.layer.lock.1')));
      await tester.pump();

      expect(_iconOf(tester, const Key('studio.layer.lock.1')), Icons.lock);
      expect(
        _tooltipOf(tester, const Key('studio.layer.lock.1')),
        'Desbloquear',
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('studio.node.1'))),
      );
      await gesture.moveBy(const Offset(24, 16));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(controller.geometryOf('1'), before);

      await tester.tap(find.byKey(const Key('studio.node.1')));
      await tester.pump();
      expect(controller.selectedNodePath, '1');
      expect(
        find.descendant(
          of: find.byKey(_inspectorKey),
          matching: find.text('Tipo: display'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('studio.layer.lock.1')));
      await tester.pump();
      final TestGesture unlocked = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('studio.node.1'))),
      );
      await unlocked.moveBy(const Offset(12, 8));
      await tester.pump();
      await unlocked.up();
      await tester.pump();
      expect(controller.geometryOf('1')!.x, closeTo(before.x + 12, 1e-6));
    });

    testWidgets('subir y bajar reordena el spec y sigue al nodo seleccionado', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      await _pumpStudio(tester, controller);

      await tester.tap(
        find.descendant(
          of: find.byKey(_layersKey),
          matching: find.text('display calc.display'),
        ),
      );
      await tester.pump();
      expect(controller.selectedNodePath, '1');

      await tester.tap(find.byKey(const Key('studio.layer.up.1')));
      await tester.pump();

      expect(controller.currentNodes[0].type, 'display');
      expect(controller.currentNodes[1].type, 'history');
      expect(controller.selectedNodePath, '0');
      expect(controller.selectedNode?.type, 'display');
      expect(find.byKey(const Key('studio.node.0')), findsOneWidget);
      expect(_enabled(tester, const Key('studio.layer.down.0')), isTrue);

      await tester.tap(find.byKey(const Key('studio.layer.down.0')));
      await tester.pump();

      expect(controller.currentNodes[0].type, 'history');
      expect(controller.currentNodes[1].type, 'display');
      expect(controller.selectedNodePath, '1');
    });

    testWidgets('bloquear un padre deshabilita los controles de sus hijos', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      await _pumpStudio(tester, controller);

      await tester.tap(find.byKey(const Key('studio.layer.lock.2')));
      await tester.pump();

      expect(_enabled(tester, const Key('studio.layer.eye.2.0')), isFalse);
      expect(_enabled(tester, const Key('studio.layer.up.2.0')), isFalse);
      expect(_enabled(tester, const Key('studio.layer.up.2.1')), isFalse);
      expect(_enabled(tester, const Key('studio.layer.lock.2.0')), isTrue);

      final StudioGeometry before = controller.geometryOf('2.0')!;
      controller.moveNode('2.0', dx: 12, dy: 12);
      expect(controller.geometryOf('2.0'), before);
    });

    testWidgets('un nodo bloqueado no ofrece manillas de resize', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      await _pumpStudio(tester, controller);

      // Seleccionar en capas: las manillas existen mientras el nodo es editable.
      await tester.tap(
        find.descendant(
          of: find.byKey(_layersKey),
          matching: find.text('display calc.display'),
        ),
      );
      await tester.pump();
      expect(controller.selectedNodePath, '1');
      expect(_handlesFor('1'), findsNWidgets(StudioResizeHandle.values.length));

      await tester.tap(find.byKey(const Key('studio.layer.lock.1')));
      await tester.pump();

      expect(
        _handlesFor('1'),
        findsNothing,
        reason: 'bloquear no debe dejar affordances que no hacen nada',
      );
      expect(find.byKey(const Key('studio.node.1')), findsOneWidget);
      expect(controller.selectedNodePath, '1');
      expect(
        find.descendant(
          of: find.byKey(_inspectorKey),
          matching: find.text('Tipo: display'),
        ),
        findsOneWidget,
        reason: 'bloquear no quita la selección ni el inspector',
      );

      await tester.tap(find.byKey(const Key('studio.layer.lock.1')));
      await tester.pump();
      expect(_handlesFor('1'), findsNWidgets(StudioResizeHandle.values.length));

      // El bloqueo de un ancestro también oculta las manillas del descendiente.
      await tester.tap(
        find.descendant(
          of: find.byKey(_layersKey),
          matching: find.text('key calc.key.1'),
        ),
      );
      await tester.pump();
      expect(controller.selectedNodePath, '2.0');
      expect(
        _handlesFor('2.0'),
        findsNWidgets(StudioResizeHandle.values.length),
      );

      await tester.tap(find.byKey(const Key('studio.layer.lock.2')));
      await tester.pump();

      expect(_handlesFor('2.0'), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(_inspectorKey),
          matching: find.text('Tipo: key'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('studio.layer.lock.2')));
      await tester.pump();
      expect(
        _handlesFor('2.0'),
        findsNWidgets(StudioResizeHandle.values.length),
      );
    });
  });
}
