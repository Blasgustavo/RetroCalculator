// Tests unitarios del inspector del RetroDesign Studio (T25, plan V4).
//
// El inspector edita documento (tokens, propiedades y fórmulas) pero no estado
// de edición (geometría, hidden, locked, ADR-0015). Todas las reglas de tokens
// se reutilizan de `token_validation.dart`; las fórmulas se validan con el
// parser del motor, sin ejecutarlas.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/design_system/token_validation.dart';

import '../../../tool/design/schema.dart';
import '../../../tool/design/studio/studio_controller.dart';

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
    },
    {
      "id": "lcd",
      "nameKey": "skinLcdName",
      "isDefault": false,
      "tokens": {
        "segmentOn": "#B8E986",
        "displayBackground": "#1E2A1F",
        "displayBorder": "#3A3320",
        "keyBackground": "#E8F0D6",
        "keyForeground": "#1E2A1F",
        "keyBorder": "#4F6F52",
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
        {"type": "padding", "titleKey": "panel", "children": [
          {"type": "key", "key": "calc.key.1"}
        ]}
      ],
      "tablet": [{"type": "display", "key": "calc.display"}],
      "desktop": [{"type": "display", "key": "calc.display"}]
    }
  },
  "profiles": [
    {
      "id": "normal",
      "labelKey": "modeNormal",
      "capabilityId": "basic",
      "isScientific": false,
      "defaultAngleMode": "degrees",
      "decimalDigits": 8,
      "inputs": [],
      "formulas": {},
      "keyRows": []
    },
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
    },
    {
      "id": "sci",
      "labelKey": "modeSci",
      "capabilityId": "scientific",
      "isScientific": true,
      "defaultAngleMode": "degrees",
      "decimalDigits": 8,
      "inputs": ["x"],
      "formulas": {"resultado": "sin(x)"},
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

ProfileSpec _profile(StudioController controller, String id) =>
    controller.document.profiles.firstWhere((ProfileSpec p) => p.id == id);

void main() {
  group('tokens de skin del inspector (T25)', () {
    test(
      'la skin inicial es la primera y selectSkin ignora ids desconocidos',
      () {
        final StudioController controller = _controller();
        int notifications = 0;
        controller.addListener(() => notifications++);

        expect(controller.selectedSkinId, 'default');
        controller.selectSkin('lcd');
        expect(controller.selectedSkinId, 'lcd');
        controller.selectSkin('inexistente');
        expect(controller.selectedSkinId, 'lcd');
        expect(notifications, 1);
      },
    );

    test(
      'setSkinToken reutiliza validateTokens y acepta cadenas numéricas',
      () {
        final StudioController controller = _controller();
        expect(controller.validateSkinTokens('default'), isEmpty);

        controller.setSkinToken('default', 'segmentOn', '#ZZZZZZ');
        expect(
          controller.validateSkinTokens('default'),
          contains('segmentOn debe ser #RRGGBB'),
        );
        expect(
          validateTokens(controller.skinTokens('default')),
          contains('segmentOn debe ser #RRGGBB'),
        );

        controller.setSkinToken('default', 'segmentOn', '#FFB000');
        // Texto de un TextField numérico: se normaliza a num y se valida con la
        // misma regla de minValues (keyMinHeight >= 48).
        controller.setSkinToken('default', 'keyMinHeight', '40');
        expect(controller.skinTokens('default')['keyMinHeight'], 40);
        expect(
          controller.validateSkinTokens('default'),
          contains('botón por debajo de 48 dp'),
        );
        controller.setSkinToken('default', 'keyMinHeight', 48);
        expect(controller.validateSkinTokens('default'), isEmpty);
      },
    );

    test('escribir en una skin no seleccionada no cambia la selección', () {
      final StudioController controller = _controller();
      controller.selectSkin('lcd');
      controller.setSkinToken('default', 'segmentOn', '#000000');

      expect(controller.selectedSkinId, 'lcd');
      expect(controller.skinTokens('lcd')['segmentOn'], '#B8E986');
      expect(controller.skinTokens('default')['segmentOn'], '#000000');
    });

    test('skin y clave desconocidas son no-op', () {
      final StudioController controller = _controller();
      final Map<String, Object?> before = controller.skinTokens('default');
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.setSkinToken('inexistente', 'segmentOn', '#000000');
      controller.setSkinToken('default', 'noExiste', '#000000');
      controller.setSkinToken('default', 'segmentOn', '#FFB000'); // sin cambio

      expect(controller.skinTokens('default'), before);
      expect(notifications, 0);
      expect(controller.validateSkinTokens('inexistente'), isNotEmpty);
      // La copia devuelta no permite saltarse el controller.
      controller.skinTokens('default')['segmentOn'] = '#000000';
      expect(controller.skinTokens('default')['segmentOn'], '#FFB000');
    });
  });

  group('propiedades del nodo del inspector (T25)', () {
    test('las seis propiedades permitidas se escriben y llegan al spec', () {
      final StudioController controller = _controller();
      controller.selectNode('0');

      controller.setNodeProperty('0', 'key', 'calc.display.editor');
      controller.setNodeProperty('0', 'titleKey', 'displayTitle');
      controller.setNodeProperty('0', 'when', 'hasError');
      controller.setNodeProperty('0', 'value', 12);
      controller.setNodeProperty('0', 'height', 64);
      controller.setNodeProperty('0', 'alignment', 'center');

      final DesignNode node = controller.selectedNode!;
      expect(node.key, 'calc.display.editor');
      expect(node.titleKey, 'displayTitle');
      expect(node.when, 'hasError');
      expect(node.value, 12);
      expect(node.height, 64);
      expect(node.alignment, 'center');
      expect(
        controller.currentSpec[0],
        containsPair('key', 'calc.display.editor'),
      );
      expect(controller.currentSpec[0], containsPair('height', 64));
    });

    test('null borra propiedades opcionales y tipos inválidos son no-op', () {
      final StudioController controller = _controller();
      controller.selectNode('0');
      final String before = jsonEncode(controller.currentSpec);
      int notifications = 0;
      controller.addListener(() => notifications++);

      controller.setNodeProperty('0', 'key', 123);
      controller.setNodeProperty('0', 'height', 'no-numero');
      controller.setNodeProperty('1.0', 'type', 'display');
      controller.setNodeProperty('99', 'key', 'x');
      expect(jsonEncode(controller.currentSpec), before);
      expect(notifications, 0);

      controller.setNodeProperty('0', 'key', 'calc.display');
      expect(notifications, 0, reason: 'valor igual no notifica');

      controller.setNodeProperty('0', 'key', null);
      expect(controller.selectedNode!.key, isNull);
      expect(controller.currentSpec[0], isNot(containsPair('key', anything)));
    });

    test('height nunca baja de 48 dp', () {
      final StudioController controller = _controller();
      controller.selectNode('0');

      controller.setNodeProperty('0', 'height', 47);
      controller.setNodeProperty('0', 'height', 40.5);
      expect(controller.selectedNode!.height, isNull);

      controller.setNodeProperty('0', 'height', 48);
      expect(controller.selectedNode!.height, 48);
    });

    test('un nodo bloqueado o con ancestro bloqueado no se edita', () {
      final StudioController controller = _controller();
      controller.setNodeLocked('0', true);
      controller.selectNode('0');
      controller.setNodeProperty('0', 'key', 'blocked');
      expect(controller.selectedNode!.key, 'calc.display');

      controller.setNodeLocked('0', false);
      controller.setNodeProperty('0', 'key', 'editable');
      expect(controller.selectedNode!.key, 'editable');

      controller.setNodeLocked('1', true);
      controller.selectNode('1.0');
      controller.setNodeProperty('1.0', 'key', 'blocked-child');
      expect(controller.selectedNode!.key, 'calc.key.1');
    });
  });

  group('fórmulas del inspector (T25)', () {
    test(
      'el perfil inicial es el primero y selectProfile ignora desconocidos',
      () {
        final StudioController controller = _controller();

        expect(controller.selectedProfileId, 'normal');
        controller.selectProfile('igv');
        expect(controller.selectedProfileId, 'igv');
        controller.selectProfile('no-existe');
        expect(controller.selectedProfileId, 'igv');
      },
    );

    test(
      'acepta inputs declarados y constantes/funciones de la capability',
      () {
        final StudioController controller = _controller();

        expect(
          controller.validateProfileFormula(
            'igv',
            'resultado',
            'base * (1 + tasa / 100)',
          ),
          isEmpty,
        );
        expect(
          controller.validateProfileFormula('sci', 'resultado', 'sin(x) + pi'),
          isEmpty,
        );
      },
    );

    test(
      'rechaza variables no declaradas, funciones no permitidas y recursión',
      () {
        final StudioController controller = _controller();

        expect(
          controller.validateProfileFormula('igv', 'resultado', 'base * otro'),
          contains('variable no declarada: otro'),
        );
        expect(
          controller.validateProfileFormula('igv', 'resultado', 'sin(base)'),
          contains('función no permitida: sin'),
        );
        expect(
          controller.validateProfileFormula(
            'igv',
            'resultado',
            'resultado + 1',
          ),
          contains('fórmula recursiva: resultado'),
        );
        expect(
          controller.validateProfileFormula('inexistente', 'resultado', 'base'),
          isNotEmpty,
        );
      },
    );

    test('rechaza sintaxis rota, fórmula vacía y longitud excesiva', () {
      final StudioController controller = _controller();

      expect(
        controller.validateProfileFormula('igv', 'resultado', 'base * ('),
        isNotEmpty,
      );
      expect(
        controller.validateProfileFormula('igv', 'resultado', '   '),
        contains('fórmula vacía'),
      );
      expect(
        controller.validateProfileFormula('igv', 'resultado', '1' * 257),
        contains('fórmula demasiado larga'),
      );
    });

    test(
      'setProfileFormula guarda incluso la inválida hasta la barrera T27',
      () {
        final StudioController controller = _controller();
        int notifications = 0;
        controller.addListener(() => notifications++);

        controller.setProfileFormula('igv', 'resultado', 'base * (');
        expect(_profile(controller, 'igv').formulas['resultado'], 'base * (');
        expect(
          controller.validateProfileFormula(
            'igv',
            'resultado',
            _profile(controller, 'igv').formulas['resultado']!,
          ),
          isNotEmpty,
        );

        controller.setProfileFormula(
          'igv',
          'resultado',
          'base * (1 + tasa / 100)',
        );
        expect(
          controller.validateProfileFormula(
            'igv',
            'resultado',
            _profile(controller, 'igv').formulas['resultado']!,
          ),
          isEmpty,
        );
        expect(notifications, 2);
        expect(_profile(controller, 'normal').formulas, isEmpty);

        controller.setProfileFormula(
          'igv',
          'resultado',
          'base * (1 + tasa / 100)',
        );
        controller.setProfileFormula('no-existe', 'resultado', '1');
        controller.setProfileFormula('igv', 'no-existe', '1');
        expect(notifications, 2, reason: 'sin cambios y destinos desconocidos');
      },
    );
  });
}
