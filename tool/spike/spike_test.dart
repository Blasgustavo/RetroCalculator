// Verificación headless del spike de fluttercanvas. Se ejecuta con:
// flutter test tool/spike/spike_test.dart
// No entra en la suite principal (test/), que debe seguir en 44/44.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttercanvas/fluttercanvas.dart';

import '../design/adapters/fluttercanvas_to_design.dart';

WidgetNode _node(
  String id,
  String type,
  Map<String, Object?> props, [
  List<WidgetNode> children = const <WidgetNode>[],
]) {
  return WidgetNode(
    id: id,
    type: type,
    props: <String, Object?>{...WidgetCatalog.defaultsFor(type), ...props},
    children: children,
  );
}

BuilderController _controller() => BuilderController(
  project: CanvasProject(screens: <CanvasDocument>[CanvasDocument.blank()]),
);

void main() {
  group('fluttercanvas API observada en v0.3.0', () {
    test('arrastrar desde la paleta inserta un nodo', () {
      final controller = _controller();
      final rootId = controller.document.root.id;

      expect(
        controller.canDrop(const NewWidgetPayload(WidgetTypes.box), rootId),
        isTrue,
      );
      controller.drop(const NewWidgetPayload(WidgetTypes.box), rootId);

      expect(controller.selectedId, isNotNull);
      expect(controller.document.root.children, hasLength(1));
      expect(controller.document.root.children.single.type, WidgetTypes.box);
    });

    test('mover y redimensionar agrupan cada gesto en un undo', () {
      final controller = _controller();
      final rootId = controller.document.root.id;
      controller.drop(const NewWidgetPayload(WidgetTypes.box), rootId);
      final id = controller.selectedId!;
      final original = controller.document.root.find(id)!;

      controller.updateProps(id, <String, Object?>{
        'x': 24,
        'y': 48,
      }, mergeKey: 'move:$id');
      controller.updateProps(id, <String, Object?>{
        'x': 40,
        'y': 60,
      }, mergeKey: 'move:$id');
      controller.endGesture();
      controller.updateProps(id, <String, Object?>{
        'width': 120,
        'height': 48,
      }, mergeKey: 'resize:$id');
      controller.endGesture();

      final moved = controller.document.root.find(id)!;
      expect(moved.number('x'), 40);
      expect(moved.number('height'), 48);

      controller.undo();
      expect(
        controller.document.root.find(id)!.number('width'),
        original.number('width'),
      );
      controller.undo();
      expect(
        controller.document.root.find(id)!.number('x'),
        original.number('x'),
      );
    });

    test('capas permiten reordenar hermanos', () {
      final controller = _controller();
      final rootId = controller.document.root.id;
      controller.drop(const NewWidgetPayload(WidgetTypes.box), rootId);
      final first = controller.selectedId!;
      controller.drop(const NewWidgetPayload(WidgetTypes.row), rootId);
      final second = controller.selectedId!;

      expect(
        controller.document.root.children.map((node) => node.id).toList(),
        <String>[first, second],
      );
      controller.moveSibling(second, -1);
      expect(
        controller.document.root.children.map((node) => node.id).toList(),
        <String>[second, first],
      );
      expect(controller.document.root.parentOf(second)!.id, rootId);
    });

    test('undo y redo restauran el documento completo', () {
      final controller = _controller();
      final before = controller.exportJson();
      controller.drop(
        const NewWidgetPayload(WidgetTypes.box),
        controller.document.root.id,
      );
      final after = controller.exportJson();

      expect(controller.canUndo, isTrue);
      controller.undo();
      expect(controller.exportJson(), before);
      expect(controller.canRedo, isTrue);
      controller.redo();
      expect(controller.exportJson(), after);
    });

    test('la serialización JSON es estable al recargarla', () {
      final controller = _controller();
      controller.drop(
        const NewWidgetPayload(WidgetTypes.image),
        controller.document.root.id,
      );
      final json = controller.exportJson();

      final reloaded = BuilderController(
        project: CanvasProject.fromJsonString(json),
      );
      expect(reloaded.exportJson(), json);
      expect(CanvasProject.schemaVersion, 2);
    });

    testWidgets('el builder del paquete se construye en modo headless', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: FlutterCanvasBuilder(title: 'Spike fluttercanvas'),
        ),
      );
      await tester.pump();

      expect(find.byType(FlutterCanvasBuilder), findsOneWidget);
      expect(find.text('Spike fluttercanvas'), findsOneWidget);
      expect(find.text('Insert'), findsOneWidget);
      expect(find.text('Layers'), findsOneWidget);
    });
  });

  group('adaptador a esquema v2', () {
    test('el resultado coincide con el fixture de la whitelist', () {
      final document = CanvasDocument(
        name: 'normal',
        title: 'normal',
        root: _node(
          'root',
          WidgetTypes.column,
          <String, Object?>{},
          <WidgetNode>[
            _node(
              'p1',
              WidgetTypes.box,
              <String, Object?>{'designType': 'padding', 'padding': 12},
              <WidgetNode>[
                _node('d1', WidgetTypes.box, <String, Object?>{
                  'designType': 'display',
                  'designKey': 'calc.display',
                }),
              ],
            ),
            _node('e1', WidgetTypes.box, <String, Object?>{
              'designType': 'errorText',
              'when': 'hasError',
            }),
            _node(
              'r1',
              WidgetTypes.row,
              <String, Object?>{'alignment': 'center', 'when': 'isScientific'},
              <WidgetNode>[
                _node('a1', WidgetTypes.box, <String, Object?>{
                  'designType': 'angleChip',
                  'designKey': 'calc.toggle.angle',
                }),
              ],
            ),
            _node(
              's1',
              WidgetTypes.box,
              <String, Object?>{'designType': 'sizedBox', 'height': 380},
              <WidgetNode>[
                _node('k1', WidgetTypes.box, <String, Object?>{
                  'designType': 'keyboard',
                  'designKey': 'calc.keyboard',
                }),
              ],
            ),
            _node('h1', WidgetTypes.box, <String, Object?>{
              'designType': 'history',
              'titleKey': 'historyTitle',
            }),
            _node('sk1', WidgetTypes.box, <String, Object?>{
              'designType': 'skinSelector',
            }),
          ],
        ),
      );

      final expected =
          jsonDecode(
                File(
                  'tool/design/adapters/fixtures/screen_spec_v2_mobile.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      expect(canvasDocumentToScreenSpec(document), equals(expected));
    });

    test('rechaza tipos fuera de la whitelist y nodos con código', () {
      expect(
        () => canvasNodeToDesignNode(
          _node('x1', WidgetTypes.customCode, const <String, Object?>{}),
        ),
        throwsA(isA<DesignAdapterException>()),
      );
      expect(
        () => canvasNodeToDesignNode(
          _node('x2', WidgetTypes.box, <String, Object?>{
            'designType': 'script',
          }),
        ),
        throwsA(isA<DesignAdapterException>()),
      );
      expect(designNodeWhitelist, contains('angleChip'));
    });
  });
}
