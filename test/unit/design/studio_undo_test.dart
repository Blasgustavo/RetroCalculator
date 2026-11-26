// Tests unitarios de undo/redo del RetroDesign Studio (T26, plan V4).
//
// El historial es estado de la herramienta, no del documento: captura las
// listas de nodos del documento y copias profundas de la geometría y de los
// flags de edición de todas las pantallas/breakpoints. Nunca se serializa.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/design/schema.dart';
import '../../../tool/design/studio/studio_controller.dart';
import '../../../tool/design/studio/studio_geometry.dart';

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
        {"type": "key", "key": "calc.key.1"},
        {"type": "padding", "titleKey": "panel", "children": [
          {"type": "key", "key": "calc.key.2"},
          {"type": "key", "key": "calc.key.3"}
        ]}
      ],
      "tablet": [{"type": "display", "key": "calc.tablet"}],
      "desktop": [{"type": "display", "key": "calc.desktop"}]
    },
    "scientific": {
      "mobile": [{"type": "display", "key": "calc.scientific"}]
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

DesignSeed _seed() => DesignSeed.fromJson(jsonDecode(_seedJson));

StudioController _controller() {
  final StudioController controller = StudioController(document: _seed());
  addTearDown(controller.dispose);
  return controller;
}

/// Semilla con una skin y un perfil alternativos para verificar `selectSkin`
/// y `selectProfile` como navegación real (no no-op).
DesignSeed _seedWithAlternatives() {
  final DesignSeed base = _seed();
  return DesignSeed(
    schemaVersion: base.schemaVersion,
    version: base.version,
    channels: base.channels,
    skins: <SkinSpec>[
      ...base.skins,
      SkinSpec(
        id: 'otra',
        nameKey: 'otra',
        isDefault: false,
        tokens: <String, Object?>{},
        images: <String>[],
      ),
    ],
    images: base.images,
    screens: base.screens,
    profiles: <ProfileSpec>[
      ...base.profiles,
      ProfileSpec(
        id: 'otro',
        labelKey: 'otro',
        capabilityId: 'basic',
        isScientific: false,
        defaultAngleMode: 'degrees',
        decimalDigits: 2,
        inputs: <String>[],
        formulas: <String, String>{'resultado': '1'},
        keyRows: <List<String>>[],
      ),
    ],
    dimensions: base.dimensions,
    sounds: base.sounds,
    monetization: base.monetization,
    publishing: base.publishing,
  );
}

void main() {
  group('historial del Studio (T26)', () {
    test('undo/redo de propiedades del nodo restaura el documento', () {
      final StudioController controller = _controller();
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);

      controller.setNodeProperty('0', 'key', 'calc.display.new');
      expect(controller.selectedNodePath, isEmpty);
      expect(controller.currentNodes.first.key, 'calc.display.new');
      expect(controller.canUndo, isTrue);
      expect(controller.canRedo, isFalse);

      controller.undo();
      expect(controller.currentNodes.first.key, 'calc.display');
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue);

      controller.redo();
      expect(controller.currentNodes.first.key, 'calc.display.new');
      expect(controller.canRedo, isFalse);
    });

    test('undo/redo de tokens de skin y fórmulas', () {
      final StudioController controller = _controller();

      controller.setSkinToken('default', 'displayRadius', 12);
      controller.setProfileFormula('igv', 'resultado', 'base + tasa');
      expect(controller.skinTokens('default')['displayRadius'], 12);
      expect(
        controller.document.profiles.single.formulas['resultado'],
        'base + tasa',
      );

      controller.undo();
      expect(controller.skinTokens('default')['displayRadius'], 12);
      expect(
        controller.document.profiles.single.formulas['resultado'],
        'base * (1 + tasa / 100)',
      );

      controller.undo();
      expect(controller.skinTokens('default')['displayRadius'], 8);
      expect(controller.canUndo, isFalse);

      controller.redo();
      controller.redo();
      expect(controller.skinTokens('default')['displayRadius'], 12);
      expect(
        controller.document.profiles.single.formulas['resultado'],
        'base + tasa',
      );
    });

    test('undo/redo de geometría, visibilidad y bloqueo', () {
      final StudioController controller = _controller();
      final StudioGeometry initial = controller.geometryOf('1')!;

      controller.moveNode('1', dx: 12, dy: 8);
      controller.setNodeHidden('0', true);
      controller.setNodeLocked('0', true);

      controller.undo();
      expect(controller.isNodeLocked('0'), isFalse);
      expect(controller.isNodeHidden('0'), isTrue);
      controller.undo();
      expect(controller.isNodeHidden('0'), isFalse);
      controller.undo();
      expect(controller.geometryOf('1'), initial);
      expect(controller.canUndo, isFalse);
    });

    test('resize agrupado y sin agrupar', () {
      final StudioController controller = _controller();
      final StudioGeometry initial = controller.geometryOf('1')!;

      controller.resizeNode(
        '1',
        StudioResizeHandle.bottomRight,
        dx: 30,
        dy: 20,
      );
      expect(controller.geometryOf('1'), isNot(initial));
      controller.undo();
      expect(controller.geometryOf('1'), initial);
    });

    test('undo/redo de reordenación remapea geometría, flags y selección', () {
      final StudioController controller = _controller();
      controller.selectNode('2.0');
      final StudioGeometry first = controller.geometryOf('2.0')!;
      controller.setNodeHidden('2.0', true);

      controller.moveLayer('2.0', up: false);
      expect(controller.selectedNodePath, '2.1');
      expect(controller.isNodeHidden('2.1'), isTrue);
      expect(controller.geometryOf('2.1'), first);

      controller.undo();
      expect(controller.currentNodes[2].children!.first.key, 'calc.key.2');
      expect(controller.selectedNodePath, '2.0');
      expect(controller.isNodeHidden('2.0'), isTrue);
      expect(controller.geometryOf('2.0'), first);

      controller.redo();
      expect(controller.selectedNodePath, '2.1');
      expect(controller.isNodeHidden('2.1'), isTrue);
    });

    test('undo de alta de nodos restaura documento y selección', () {
      final StudioController controller = _controller();
      final int count = controller.currentNodes.length;

      final String? path = controller.addNode('key');
      expect(path, '$count');
      expect(controller.selectedNodePath, path);

      controller.undo();
      expect(controller.currentNodes.length, count);
      expect(controller.selectedNodePath, isEmpty);

      controller.redo();
      expect(controller.currentNodes.length, count + 1);
      expect(controller.selectedNodePath, path);
    });

    test(
      'el estado de otras pantallas y breakpoints se restaura sin perderlo',
      () {
        final StudioController controller = _controller();
        controller.selectBreakpoint('tablet');
        final StudioGeometry tabletBefore = controller.geometryOf('0')!;
        controller.moveNode('0', dx: 24, dy: 16);
        final StudioGeometry tabletAfter = controller.geometryOf('0')!;

        controller.selectBreakpoint('mobile');
        controller.setNodeHidden('1', true);
        controller.selectScreen('scientific');
        controller.setNodeLocked('0', true);

        controller.undo(); // desbloquea scientific
        controller.undo(); // muestra mobile
        expect(controller.isNodeHidden('1'), isFalse);
        expect(controller.isNodeLocked('0'), isFalse);

        controller.selectScreen('normal');
        controller.selectBreakpoint('tablet');
        expect(
          controller.geometryOf('0'),
          tabletAfter,
          reason: 'tablet queda intacto',
        );
        controller.undo();
        expect(controller.geometryOf('0'), tabletBefore);
        expect(controller.canUndo, isFalse);
      },
    );

    test('no-op, validación fallida y nodo bloqueado no crean entrada', () {
      final StudioController controller = _controller();
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.setNodeProperty('0', 'key', 'calc.display');
      controller.setNodeProperty('0', 'height', 40);
      controller.setNodeProperty('0', 'key', 7);
      controller.setNodeProperty('99', 'key', 'x');
      controller.setSkinToken('default', 'displayRadius', 8);
      controller.setSkinToken('default', 'claveInventada', 1);
      controller.setProfileFormula(
        'igv',
        'resultado',
        'base * (1 + tasa / 100)',
      );
      controller.setProfileFormula('inexistente', 'resultado', 'otra');
      controller.setNodeHidden('0', false);
      controller.setNodeGeometry('1', controller.geometryOf('1')!);
      controller.moveNode('1', dx: 0, dy: 0);
      controller.selectNode('1');
      controller.setSnapping(true);
      controller.setSnapGrid(16);

      expect(
        notifications,
        3,
        reason: 'solo notifican la selección, el snapping y su grilla',
      );
      expect(controller.canUndo, isFalse, reason: 'sin entradas de historial');

      controller.setNodeLocked('0', true); // única entrada real
      controller.setNodeProperty('0', 'key', 'bloqueado');
      controller.setNodeHidden('0', true);
      controller.moveNode('0', dx: 10, dy: 10);
      expect(notifications, 4);

      controller.undo();
      expect(controller.isNodeLocked('0'), isFalse);
      expect(controller.canUndo, isFalse);
    });

    test('undo y redo con pila vacía no notifican', () {
      final StudioController controller = _controller();
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.undo();
      controller.redo();
      expect(notifications, 0);

      controller.setNodeProperty('0', 'key', 'nueva');
      notifications = 0;
      controller.undo();
      expect(notifications, 1, reason: 'undo notifica una sola vez');
      controller.redo();
      expect(notifications, 2, reason: 'redo notifica una sola vez');
    });

    test('una edición tras undo descarta el redo', () {
      final StudioController controller = _controller();
      controller.setNodeProperty('0', 'key', 'primera');
      controller.setNodeProperty('0', 'key', 'segunda');
      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.setNodeProperty('0', 'titleKey', 'otro');
      expect(controller.canRedo, isFalse);
      controller.undo();
      expect(controller.currentNodes.first.key, 'primera');
      expect(controller.currentNodes.first.titleKey, isNull);
    });

    test('loadDocument limpia ambas pilas', () {
      final StudioController controller = _controller();
      controller.setNodeProperty('0', 'key', 'cambio');
      controller.undo();
      expect(controller.canRedo, isTrue);

      controller.loadDocument(_seed());
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
      controller.setNodeProperty('0', 'key', 'después');
      expect(controller.canRedo, isFalse);
    });

    test('la pila de undo se limita a 50 entradas', () {
      final StudioController controller = _controller();
      for (int i = 1; i <= 55; i++) {
        controller.setNodeProperty('0', 'value', i);
      }
      for (int i = 0; i < 50; i++) {
        controller.undo();
      }
      expect(controller.currentNodes.first.value, 5);
      expect(controller.canUndo, isFalse);
      controller.redo();
      expect(controller.currentNodes.first.value, 6);
    });

    test('beginInteraction agrupa muchas mutaciones en una sola entrada', () {
      final StudioController controller = _controller();
      final StudioGeometry initial = controller.geometryOf('1')!;

      controller.beginInteraction('move:1');
      for (int i = 1; i <= 10; i++) {
        controller.moveNode('1', dx: 1, dy: 0);
      }
      controller.endInteraction();

      expect(controller.geometryOf('1')!.x, closeTo(initial.x + 10, 1e-9));
      controller.undo();
      expect(controller.geometryOf('1'), initial);
      expect(controller.canUndo, isFalse);
    });

    test('sin mutación, una interacción no crea entrada', () {
      final StudioController controller = _controller();
      controller.beginInteraction('resize:1:topLeft');
      controller.endInteraction();
      expect(controller.canUndo, isFalse);

      controller.beginInteraction('node:0:key');
      controller.setNodeProperty('0', 'key', 'primera');
      controller.setNodeProperty('0', 'key', 'segunda');
      controller.endInteraction();
      controller.beginInteraction('node:0:key');
      controller.endInteraction();
      controller.undo();
      expect(controller.currentNodes.first.key, 'calc.display');
      expect(controller.canUndo, isFalse);
    });

    test('undo cancela una interacción pendiente', () {
      final StudioController controller = _controller();
      controller.setNodeProperty('0', 'key', 'primera');
      controller.beginInteraction('node:0:key');
      controller.undo();

      controller.setNodeProperty('0', 'titleKey', 'nuevo');
      controller.undo();
      expect(controller.currentNodes.first.key, 'calc.display');
      expect(controller.currentNodes.first.titleKey, isNull);
      expect(controller.canUndo, isFalse);
    });

    test('seleccionar un nodo cancela una interacción pendiente obsoleta', () {
      final StudioController controller = _controller();

      // El snapshot pendiente se captura con selección vacía. Sin la corrección
      // se empujaría en la siguiente mutación y undo restauraría esa selección.
      controller.beginInteraction('stale:node');
      controller.selectNode('1');
      expect(
        controller.canUndo,
        isFalse,
        reason: 'seleccionar no crea entradas de historial',
      );

      controller.setNodeProperty('1', 'key', 'nueva');
      controller.undo();

      expect(controller.selectedNodePath, '1');
      expect(controller.currentNodes[1].key, 'calc.key.1');
      expect(controller.canUndo, isFalse);
    });

    test(
      'cambiar pantalla, breakpoint, selección, skin o perfil cancela la interacción',
      () {
        void check(
          String label,
          void Function(StudioController) navigate,
          void Function(StudioController) restored, {
          bool selectFirst = false,
        }) {
          final StudioController controller = StudioController(
            document: _seedWithAlternatives(),
          );
          addTearDown(controller.dispose);
          if (selectFirst) controller.selectNode('0');
          controller.beginInteraction('stale:$label');

          navigate(controller);
          expect(
            controller.canUndo,
            isFalse,
            reason: '$label: la navegación por sí sola no crea entradas',
          );

          controller.setNodeProperty('0', 'key', 'editado');
          controller.undo();

          restored(controller);
          expect(controller.currentNodes.first.key, isNot('editado'));
          expect(
            controller.canUndo,
            isFalse,
            reason: '$label: solo una entrada',
          );
        }

        check(
          'pantalla',
          (StudioController c) => c.selectScreen('scientific'),
          (StudioController c) => expect(c.screen, 'scientific'),
        );
        check(
          'breakpoint',
          (StudioController c) => c.selectBreakpoint('tablet'),
          (StudioController c) => expect(c.breakpoint, 'tablet'),
        );
        check(
          'selección',
          (StudioController c) => c.clearSelection(),
          (StudioController c) => expect(c.selectedNodePath, isEmpty),
          selectFirst: true,
        );
        check(
          'skin',
          (StudioController c) => c.selectSkin('otra'),
          (StudioController c) => expect(c.selectedSkinId, 'otra'),
        );
        check(
          'perfil',
          (StudioController c) => c.selectProfile('otro'),
          (StudioController c) => expect(c.selectedProfileId, 'otro'),
        );
      },
    );

    test('las preferencias de herramienta no forman parte del snapshot', () {
      final StudioController controller = _controller();
      controller.setNodeProperty('0', 'key', 'nueva');
      controller.setSnapping(true);
      controller.setSnapGrid(16);

      controller.undo();
      expect(controller.snappingEnabled, isTrue);
      expect(controller.snapGrid, 16);
      expect(controller.currentNodes.first.key, 'calc.display');
    });

    test('el historial no se filtra en serializeLayout', () {
      final StudioController controller = _controller();
      controller.setNodeProperty('0', 'key', 'nueva');
      final Map<String, Object?> layout = controller.serializeLayout();

      expect(layout.containsKey('undo'), isFalse);
      expect(layout.containsKey('history'), isFalse);
      expect(layout.keys, <String>{
        'screen',
        'breakpoint',
        'snapping',
        'frame',
        'nodes',
      });
    });
  });
}
