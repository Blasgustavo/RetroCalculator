// Test de widget del panel de resultados de T27. El callback es falso: la
// prueba no escribe ningún archivo en el repositorio.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/design/schema.dart';
import '../../tool/design/studio/studio_apply.dart';
import '../../tool/design/studio/studio_app.dart';
import '../../tool/design/studio/studio_controller.dart';
import '../../tool/design/validate.dart' show ValidationIssue;

const String _seedJson = r'''
{
  "schemaVersion": 2,
  "version": 1,
  "channels": ["prod"],
  "skins": [],
  "images": [],
  "screens": {
    "normal": {
      "mobile": [{"type": "history", "titleKey": "capa.mobile"}]
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

const Key _statusKey = Key('studio.apply.status');
const Key _applyKey = Key('studio.apply');

StudioController _controller(StudioApplyCallback callback) {
  final StudioController controller = StudioController(
    document: _seed(),
    applyCallback: callback,
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  testWidgets('el panel muestra "Sin resultados" antes de aplicar', (
    WidgetTester tester,
  ) async {
    final StudioController controller = _controller(
      (DesignSeed document, {required bool write}) =>
          const StudioApplyResult(issues: [], written: []),
    );
    await tester.pumpWidget(StudioApp(controller: controller));

    expect(find.byKey(_statusKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_statusKey),
        matching: find.text('Sin resultados'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Aplicar muestra éxito y los archivos escritos', (
    WidgetTester tester,
  ) async {
    bool? capturedWrite;
    final StudioController controller = _controller((
      DesignSeed document, {
      required bool write,
    }) {
      capturedWrite = write;
      return const StudioApplyResult(
        issues: <ValidationIssue>[],
        written: <String>['assets/catalog/manifest.v2.json'],
      );
    });
    await tester.pumpWidget(StudioApp(controller: controller));

    expect(find.byKey(_applyKey), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Aplicar'), findsOneWidget);

    await tester.tap(find.byKey(_applyKey));
    await tester.pump();

    expect(capturedWrite, isTrue);
    expect(
      find.descendant(
        of: find.byKey(_statusKey),
        matching: find.text('Válido'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_statusKey),
        matching: find.text('assets/catalog/manifest.v2.json'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Aplicar muestra los errores con keys deterministas', (
    WidgetTester tester,
  ) async {
    final StudioController controller = _controller(
      (DesignSeed document, {required bool write}) => const StudioApplyResult(
        issues: <ValidationIssue>[
          ValidationIssue('profiles[0].formulas.resultado', 'fórmula rota'),
        ],
        written: <String>[],
      ),
    );
    await tester.pumpWidget(StudioApp(controller: controller));

    await tester.tap(find.byKey(_applyKey));
    await tester.pump();

    expect(find.byKey(const Key('studio.apply.issue.0')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_statusKey),
        matching: find.text('profiles[0].formulas.resultado: fórmula rota'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_statusKey),
        matching: find.text('Sin resultados'),
      ),
      findsNothing,
    );
  });

  testWidgets('Validar no pide escritura y marca solo validación', (
    WidgetTester tester,
  ) async {
    bool? capturedWrite;
    final StudioController controller = _controller((
      DesignSeed document, {
      required bool write,
    }) {
      capturedWrite = write;
      return const StudioApplyResult(
        issues: <ValidationIssue>[],
        written: <String>[],
      );
    });
    await tester.pumpWidget(StudioApp(controller: controller));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Validar'));
    await tester.pump();

    expect(capturedWrite, isFalse);
    expect(
      find.descendant(
        of: find.byKey(_statusKey),
        matching: find.text('Válido'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(_statusKey),
        matching: find.text('Solo validación'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Guardar, Compilar y Publicar siguen presentes', (
    WidgetTester tester,
  ) async {
    final StudioController controller = _controller(
      (DesignSeed document, {required bool write}) =>
          const StudioApplyResult(issues: [], written: []),
    );
    await tester.pumpWidget(StudioApp(controller: controller));

    for (final String action in <String>[
      'Guardar',
      'Validar',
      'Aplicar',
      'Compilar',
      'Publicar',
    ]) {
      expect(
        find.widgetWithText(ElevatedButton, action),
        findsOneWidget,
        reason: 'falta la acción "$action"',
      );
    }
  });
}
