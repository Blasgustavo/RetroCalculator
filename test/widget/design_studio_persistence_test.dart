// Test de widget de T28: Guardar, Recargar y «Ver en preview». Los callbacks
// son falsos: la prueba no escribe ningún archivo en el repositorio.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tool/design/schema.dart';
import '../../tool/design/studio/studio_apply.dart' show StudioApplyResult;
import '../../tool/design/studio/studio_app.dart';
import '../../tool/design/studio/studio_controller.dart';
import '../../tool/design/studio/studio_persistence.dart';
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
      "mobile": [
        {
          "type": "padding",
          "value": 12,
          "child": {"type": "history", "titleKey": "hijo.preview"}
        }
      ]
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

DesignSeed _replacementSeed() {
  final Map<String, Object?> root =
      jsonDecode(_seedJson) as Map<String, Object?>;
  final Map<String, Object?> screens = root['screens'] as Map<String, Object?>;
  final Map<String, Object?> normal = screens['normal'] as Map<String, Object?>;
  normal['mobile'] = <Object?>[
    <String, Object?>{'type': 'history', 'titleKey': 'recargado'},
  ];
  return DesignSeed.fromJson(root);
}

const Key _statusKey = Key('studio.apply.status');
const Key _persistenceKey = Key('studio.persistence.status');
const Key _previewRendererKey = Key('studio.preview.renderer');

StudioController _controller({
  StudioSaveCallback? saveCallback,
  StudioReloadCallback? reloadCallback,
}) {
  final StudioController controller = StudioController(
    document: _seed(),
    applyCallback: (DesignSeed document, {required bool write}) =>
        const StudioApplyResult(
          issues: <ValidationIssue>[],
          written: <String>[],
        ),
    saveCallback:
        saveCallback ??
        (DesignSeed document) =>
            const StudioSaveResult(path: 'design/app.design.json', bytes: 1234),
    reloadCallback: reloadCallback ?? () => _replacementSeed(),
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  testWidgets('Guardar muestra el mensaje en el panel sin "Sin resultados"', (
    WidgetTester tester,
  ) async {
    DesignSeed? saved;
    final StudioController controller = _controller(
      saveCallback: (DesignSeed document) {
        saved = document;
        return const StudioSaveResult(
          path: 'design/app.design.json',
          bytes: 1234,
        );
      },
    );
    await tester.pumpWidget(StudioApp(controller: controller));

    await tester.tap(find.byKey(const Key('studio.save')));
    await tester.pump();

    expect(saved, same(controller.document));
    expect(
      find.descendant(
        of: find.byKey(_statusKey),
        matching: find.byKey(_persistenceKey),
      ),
      findsOneWidget,
    );
    expect(
      find.text('Guardado: design/app.design.json (1234 bytes)'),
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

  testWidgets('Recargar sustituye el documento y limpia el undo', (
    WidgetTester tester,
  ) async {
    bool reloaded = false;
    final StudioController controller = _controller(
      reloadCallback: () {
        reloaded = true;
        return _replacementSeed();
      },
    );
    await tester.pumpWidget(StudioApp(controller: controller));

    controller.addNode('display');
    await tester.pump();
    expect(controller.canUndo, isTrue);

    await tester.tap(find.byKey(const Key('studio.reload')));
    await tester.pump();

    expect(reloaded, isTrue);
    expect(controller.canUndo, isFalse);
    expect(controller.canRedo, isFalse);
    expect(find.text('recargado'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(_statusKey),
        matching: find.byKey(_persistenceKey),
      ),
      findsOneWidget,
    );
    expect(find.text('Recargado: design/app.design.json'), findsOneWidget);
  });

  testWidgets(
    'Recargar descarta el feedback de Aplicar del documento anterior',
    (WidgetTester tester) async {
      const String writtenFile = 'assets/catalog/manifest.v2.json';
      final StudioController controller = StudioController(
        document: _seed(),
        applyCallback: (DesignSeed document, {required bool write}) =>
            const StudioApplyResult(
              issues: <ValidationIssue>[],
              written: <String>[writtenFile],
            ),
        saveCallback: (DesignSeed document) =>
            const StudioSaveResult(path: 'design/app.design.json', bytes: 1234),
        reloadCallback: () => _replacementSeed(),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(StudioApp(controller: controller));

      await tester.tap(find.byKey(const Key('studio.apply')));
      await tester.pump();
      expect(controller.lastApplyResult, isNotNull);
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
          matching: find.text(writtenFile),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('studio.reload')));
      await tester.pump();

      expect(controller.lastApplyResult, isNull);
      expect(
        find.descendant(
          of: find.byKey(_statusKey),
          matching: find.text('Válido'),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(_statusKey),
          matching: find.text(writtenFile),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(_statusKey),
          matching: find.byKey(_persistenceKey),
        ),
        findsOneWidget,
      );
      expect(find.text('Recargado: design/app.design.json'), findsOneWidget);
    },
  );

  testWidgets('Ver en preview renderiza el spec actual, no el filtrado', (
    WidgetTester tester,
  ) async {
    final StudioController controller = _controller();
    await tester.pumpWidget(StudioApp(controller: controller));

    // Ocultar el hijo lo quita del canvas, pero no del spec publicable (ADR-0015).
    controller.setNodeHidden('0.c', true);
    await tester.pump();
    expect(find.text('hijo.preview'), findsNothing);

    await tester.tap(find.byKey(const Key('studio.preview')));
    await tester.pumpAndSettle();

    expect(find.text('Vista previa'), findsOneWidget);
    expect(find.byKey(_previewRendererKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(_previewRendererKey),
        matching: find.text('hijo.preview'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('las acciones heredadas conservan sus keys y textos', (
    WidgetTester tester,
  ) async {
    final StudioController controller = _controller();
    await tester.pumpWidget(StudioApp(controller: controller));

    for (final String action in <String>[
      'Guardar',
      'Recargar',
      'Validar',
      'Aplicar',
      'Ver en preview',
      'Compilar',
      'Publicar',
    ]) {
      expect(
        find.widgetWithText(ElevatedButton, action),
        findsOneWidget,
        reason: 'falta la acción "$action"',
      );
    }
    expect(find.byKey(const Key('studio.save')), findsOneWidget);
    expect(find.byKey(const Key('studio.reload')), findsOneWidget);
    expect(find.byKey(const Key('studio.preview')), findsOneWidget);
    expect(find.byKey(const Key('studio.apply')), findsOneWidget);
  });
}
