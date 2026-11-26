// Test de widget del shell del RetroDesign Studio (T21, plan V4).
//
// El documento se inyecta como `DesignSeed` construido desde JSON local: el
// test no depende de red, de plugins nativos ni de entitlements.

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
const Key _layersKey = Key('studio.layers');
const Key _inspectorKey = Key('studio.inspector');

const List<String> _actions = <String>[
  'Guardar',
  'Validar',
  'Compilar',
  'Publicar',
];

void main() {
  test('el documento inicial se carga de design/app.design.json', () {
    // La app usa la ruta relativa a la raíz del proyecto; aquí no hay red.
    final DesignSeed document = loadStudioDocument();

    expect(document.screens.keys, contains('normal'));
    expect(
      document.screens['normal']!.keys,
      containsAll(<String>['mobile', 'tablet', 'desktop']),
    );
  });

  testWidgets(
    'el shell muestra paleta, canvas, capas, inspector, breakpoints y acciones',
    (WidgetTester tester) async {
      await tester.pumpWidget(StudioApp(document: _seed()));

      expect(find.byKey(_paletteKey), findsOneWidget);
      expect(find.byKey(_canvasKey), findsOneWidget);
      expect(find.byKey(_layersKey), findsOneWidget);
      expect(find.byKey(_inspectorKey), findsOneWidget);

      for (final String type in designNodeTypes) {
        expect(
          find.descendant(
            of: find.byKey(_paletteKey),
            matching: find.text(type),
          ),
          findsOneWidget,
          reason: 'falta el tipo "$type" en la paleta',
        );
      }

      for (final String breakpoint in designBreakpoints) {
        expect(
          find.widgetWithText(ChoiceChip, breakpoint),
          findsOneWidget,
          reason: 'falta el breakpoint "$breakpoint"',
        );
      }

      for (final String action in _actions) {
        expect(
          find.widgetWithText(ElevatedButton, action),
          findsOneWidget,
          reason: 'falta la acción "$action"',
        );
      }

      expect(
        find.descendant(
          of: find.byKey(_inspectorKey),
          matching: find.text('Selecciona un nodo'),
        ),
        findsOneWidget,
      );

      // Documento inicial: pantalla `normal`, breakpoint `mobile`.
      expect(
        find.descendant(
          of: find.byKey(_canvasKey),
          matching: find.text('capa.mobile'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(_layersKey),
          matching: find.text('history capa.mobile'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('cambiar de breakpoint cambia el canvas y las capas', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(StudioApp(document: _seed()));

    expect(
      find.descendant(
        of: find.byKey(_canvasKey),
        matching: find.text('capa.mobile'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'tablet'));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(_canvasKey),
        matching: find.text('capa.tablet'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_canvasKey),
        matching: find.text('capa.mobile'),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(_layersKey),
        matching: find.text('history capa.tablet'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_layersKey),
        matching: find.text('history capa.mobile'),
      ),
      findsNothing,
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'mobile'));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(_canvasKey),
        matching: find.text('capa.mobile'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_layersKey),
        matching: find.text('history capa.mobile'),
      ),
      findsOneWidget,
    );
  });
}
