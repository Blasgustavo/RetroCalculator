// Tests de widget del inspector del RetroDesign Studio (T25, plan V4).
//
// Los campos se generan desde las listas declaradas (propiedades del nodo,
// colorKeys y minValues), escriben en el controller y muestran errores en vivo
// sin ejecutar fórmulas ni tocar la geometría del canvas.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/design_system/token_validation.dart';

import '../../tool/design/schema.dart';
import '../../tool/design/studio/studio_app.dart';
import '../../tool/design/studio/studio_controller.dart';

const String _seedJson = r'''
{
  "schemaVersion": 2,
  "version": 1,
  "channels": ["prod"],
  "skins": [
    {
      "id": "default",
      "nameKey": "skinDefaultName",
      "isDefault": true,
      "tokens": {
        "segmentOn": "#FFB000",
        "displayBackground": "#1E1B12",
        "displayBorder": "#3A3320",
        "keyBackground": "#E8D9A0",
        "keyForeground": "#1E1B12",
        "keyBorder": "#3A3320",
        "displayRadius": 8,
        "displayPaddingHorizontal": 16,
        "displayPaddingVertical": 12,
        "digitWidth": 26,
        "digitHeight": 48,
        "keyRadius": 6,
        "keyPadding": 3,
        "keyMinHeight": 48,
        "screenPadding": 12,
        "keyboardHeight": 380
      },
      "images": []
    }
  ],
  "images": [],
  "screens": {
    "normal": {
      "mobile": [
        {"type": "display", "key": "calc.display"},
        {"type": "padding", "children": [
          {"type": "key", "key": "calc.key.1"}
        ]}
      ],
      "tablet": [{"type": "display", "key": "calc.display"}],
      "desktop": [{"type": "display", "key": "calc.display"}]
    }
  },
  "profiles": [
    {
      "id": "igv",
      "labelKey": "modeIgv",
      "capabilityId": "basic",
      "isScientific": false,
      "defaultAngleMode": "degrees",
      "decimalDigits": 2,
      "inputs": ["base", "tasa"],
      "formulas": {"resultado": "base * (1 + tasa / 100)"},
      "keyRows": []
    }
  ],
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

const Key _inspectorKey = Key('studio.inspector');

DesignSeed _seed() => DesignSeed.fromJson(jsonDecode(_seedJson));

StudioController _controller() {
  final StudioController controller = StudioController(document: _seed());
  addTearDown(controller.dispose);
  return controller;
}

Future<void> _pump(WidgetTester tester, StudioController controller) =>
    tester.pumpWidget(StudioApp(document: _seed(), controller: controller));

void main() {
  group('inspector del Studio (T25)', () {
    testWidgets('genera campos para propiedades, tokens y fórmula', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      controller.selectNode('0');
      await _pump(tester, controller);

      for (final String property in studioEditableNodeProperties) {
        expect(
          find.byKey(Key('studio.inspector.node.$property')),
          findsOneWidget,
          reason: 'falta el campo $property',
        );
      }
      for (final String key in <String>[...colorKeys, ...minValues.keys]) {
        expect(
          find.byKey(Key('studio.inspector.token.$key')),
          findsOneWidget,
          reason: 'falta el token $key',
        );
      }
      expect(find.byKey(const Key('studio.inspector.formula')), findsOneWidget);
      expect(find.byKey(const Key('studio.inspector.profile')), findsOneWidget);
      expect(
        find.byKey(const Key('studio.inspector.formulaName')),
        findsOneWidget,
      );
    });

    testWidgets(
      'editar una propiedad actualiza el documento y valida en vivo',
      (WidgetTester tester) async {
        final StudioController controller = _controller();
        controller.selectNode('0');
        await _pump(tester, controller);

        await tester.enterText(
          find.byKey(const Key('studio.inspector.node.key')),
          'calc.display.new',
        );
        await tester.pump();
        expect(controller.selectedNode!.key, 'calc.display.new');
        expect(
          find.descendant(
            of: find.byKey(_inspectorKey),
            matching: find.text('Key: calc.display.new'),
          ),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('studio.inspector.node.height')),
          '40',
        );
        await tester.pump();
        expect(controller.selectedNode!.height, isNull);
        expect(find.text('La altura mínima es 48 dp'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('studio.inspector.node.height')),
          '64',
        );
        await tester.pump();
        expect(controller.selectedNode!.height, 64);
        expect(find.text('La altura mínima es 48 dp'), findsNothing);
      },
    );

    testWidgets(
      'los campos de tokens escriben y muestran errores y contraste',
      (WidgetTester tester) async {
        final StudioController controller = _controller();
        await _pump(tester, controller);

        expect(
          find.textContaining('Contraste segmento/display'),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('studio.inspector.token.segmentOn')),
          '#ZZZZZZ',
        );
        await tester.pump();
        expect(controller.skinTokens('default')['segmentOn'], '#ZZZZZZ');
        expect(find.text('segmentOn debe ser #RRGGBB'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('studio.inspector.token.keyMinHeight')),
          '40',
        );
        await tester.pump();
        expect(controller.skinTokens('default')['keyMinHeight'], 40);
        expect(find.text('botón por debajo de 48 dp'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('studio.inspector.token.segmentOn')),
          '#FFB000',
        );
        await tester.enterText(
          find.byKey(const Key('studio.inspector.token.keyMinHeight')),
          '48',
        );
        await tester.pump();
        expect(controller.validateSkinTokens('default'), isEmpty);
        expect(find.text('segmentOn debe ser #RRGGBB'), findsNothing);
        expect(find.text('botón por debajo de 48 dp'), findsNothing);
      },
    );

    testWidgets('un nodo bloqueado no se edita; al desbloquear se restaura', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      controller.selectNode('0');
      await _pump(tester, controller);

      controller.setNodeLocked('0', true);
      await tester.pump();

      final TextField field = tester.widget<TextField>(
        find.byKey(const Key('studio.inspector.node.key')),
      );
      expect(field.enabled, isFalse);
      // El campo no acepta interacción y el controller también rechaza la
      // escritura (T24); no se simula texto en un widget deshabilitado.
      controller.setNodeProperty('0', 'key', 'bloqueado');
      expect(controller.selectedNode!.key, 'calc.display');

      controller.setNodeLocked('0', false);
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('studio.inspector.node.key')),
            )
            .enabled,
        isTrue,
      );
      await tester.enterText(
        find.byKey(const Key('studio.inspector.node.key')),
        'editable',
      );
      await tester.pump();
      expect(controller.selectedNode!.key, 'editable');
    });

    testWidgets('la fórmula valida en vivo y se guarda en el documento', (
      WidgetTester tester,
    ) async {
      final StudioController controller = _controller();
      await _pump(tester, controller);

      final TextField formula = tester.widget<TextField>(
        find.byKey(const Key('studio.inspector.formula')),
      );
      expect(formula.controller!.text, 'base * (1 + tasa / 100)');

      await tester.enterText(
        find.byKey(const Key('studio.inspector.formula')),
        'base * otro',
      );
      await tester.pump();
      expect(
        controller.document.profiles.single.formulas['resultado'],
        'base * otro',
      );
      expect(find.text('variable no declarada: otro'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('studio.inspector.formula')),
        'base * (1 + tasa / 100)',
      );
      await tester.pump();
      expect(find.text('variable no declarada: otro'), findsNothing);
      expect(
        controller.validateProfileFormula(
          'igv',
          'resultado',
          controller.document.profiles.single.formulas['resultado']!,
        ),
        isEmpty,
      );
    });
  });
}
