import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/widgets/calculator_keyboard.dart';
import 'package:retro_calculator/core/widgets/seven_segment_display.dart';
import 'package:retro_calculator/core/widgets/spec_renderer.dart';

SpecRenderContext _context({
  String? errorLabel,
  bool isScientific = false,
  bool angleSelected = false,
  double? keyboardHeight,
  List<String>? tappedKey,
  List<bool>? toggledAngle,
}) {
  return SpecRenderContext(
    keyboardHeight: keyboardHeight,
    displayText: '42',
    errorLabel: errorLabel,
    rows: const <List<String>>[
      <String>['7', '8', '9'],
      <String>['C', '0', '='],
    ],
    labels: const <String, String>{'custom': 'Siete'},
    onKeyTap: (String key) => tappedKey?.add(key),
    isScientific: isScientific,
    angleSelected: angleSelected,
    onAngleToggle: (bool selected) => toggledAngle?.add(selected),
    strings: const <String, String>{
      'angleDeg': 'DEG',
      'angleRad': 'RAD',
      'historyTitle': 'Historial',
    },
    historyBuilder: (BuildContext context, String? titleKey) =>
        Text('history:$titleKey'),
    selectorBuilder: (BuildContext context) => const Text('selector'),
  );
}

Future<void> _pumpSpec(
  WidgetTester tester,
  List<Object?> nodes,
  SpecRenderContext context,
) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SpecRenderer(nodes: nodes, renderContext: context),
        ),
      ),
    ),
  );
}

void main() {
  test('la whitelist contiene exactamente los 12 tipos canónicos', () {
    expect(specNodeTypes, <String>{
      'padding',
      'display',
      'errorText',
      'row',
      'column',
      'sizedBox',
      'keyboard',
      'key',
      'image',
      'history',
      'skinSelector',
      'angleChip',
    });
  });

  testWidgets('renderiza los 12 tipos, props y nodos hijos', (
    WidgetTester tester,
  ) async {
    final List<String> tappedKey = <String>[];
    final List<bool> toggledAngle = <bool>[];
    await _pumpSpec(
      tester,
      <Object?>[
        <String, Object?>{
          'type': 'padding',
          'value': 8,
          'child': <String, Object?>{'type': 'display', 'key': 'calc.display'},
        },
        <String, Object?>{'type': 'errorText', 'when': 'hasError'},
        <String, Object?>{
          'type': 'row',
          'alignment': 'center',
          'children': <Object?>[
            <String, Object?>{'type': 'angleChip', 'key': 'calc.toggle.angle'},
          ],
        },
        <String, Object?>{
          'type': 'column',
          'children': <Object?>[
            <String, Object?>{
              'type': 'key',
              'key': 'calc.key.custom',
              'value': 'custom',
            },
          ],
        },
        <String, Object?>{
          'type': 'sizedBox',
          'height': 120,
          'child': <String, Object?>{
            'type': 'keyboard',
            'key': 'calc.keyboard',
          },
        },
        <String, Object?>{'type': 'image', 'key': 'spec.image'},
        <String, Object?>{'type': 'history', 'titleKey': 'historyTitle'},
        <String, Object?>{'type': 'skinSelector'},
      ],
      _context(
        errorLabel: 'División entre cero',
        isScientific: true,
        angleSelected: true,
        tappedKey: tappedKey,
        toggledAngle: toggledAngle,
      ),
    );

    expect(
      tester
          .widget<SevenSegmentDisplay>(find.byKey(const Key('calc.display')))
          .text,
      '42',
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('calc.display')),
        matching: find.byWidgetPredicate(
          (Widget widget) =>
              widget is Padding && widget.padding == EdgeInsets.all(8),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('División entre cero'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (Widget widget) =>
            widget is Row &&
            widget.mainAxisAlignment == MainAxisAlignment.center,
      ),
      findsOneWidget,
    );
    expect(find.byType(Column), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is SizedBox && widget.height == 120,
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('calc.keyboard')), findsOneWidget);
    expect(find.byType(CalculatorKeyboard), findsOneWidget);
    expect(find.byKey(const Key('calc.key.7')), findsOneWidget);
    expect(find.byKey(const Key('calc.key.custom')), findsOneWidget);
    expect(find.text('Siete'), findsOneWidget);
    expect(find.byIcon(Icons.image), findsOneWidget);
    expect(find.byKey(const Key('spec.image')), findsOneWidget);
    expect(find.text('history:historyTitle'), findsOneWidget);
    expect(find.text('selector'), findsOneWidget);

    final ChoiceChip chip = tester.widget<ChoiceChip>(
      find.byKey(const Key('calc.toggle.angle')),
    );
    expect(chip.selected, isTrue);
    expect(find.text('RAD'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calc.toggle.angle')));
    expect(toggledAngle, <bool>[false]);
    await tester.tap(find.byKey(const Key('calc.key.custom')));
    expect(tappedKey, <String>['custom']);
  });

  testWidgets('el contexto fija la altura heredada del teclado', (
    WidgetTester tester,
  ) async {
    await _pumpSpec(tester, <Object?>[
      <String, Object?>{
        'type': 'sizedBox',
        'height': 420,
        'child': <String, Object?>{'type': 'keyboard'},
      },
    ], _context(keyboardHeight: 380));

    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is SizedBox && widget.height == 380,
      ),
      findsOneWidget,
    );
  });

  testWidgets('hasError controla el nodo errorText sin ejecutar código', (
    WidgetTester tester,
  ) async {
    final List<Object?> nodes = <Object?>[
      <String, Object?>{'type': 'errorText', 'when': 'hasError'},
    ];
    await _pumpSpec(tester, nodes, _context());
    expect(find.byType(Text), findsNothing);

    await _pumpSpec(tester, nodes, _context(errorLabel: 'Error localizado'));
    expect(find.text('Error localizado'), findsOneWidget);
  });

  testWidgets('isScientific controla el nodo angleChip sin ejecutar código', (
    WidgetTester tester,
  ) async {
    final List<Object?> nodes = <Object?>[
      <String, Object?>{
        'type': 'row',
        'when': 'isScientific',
        'children': <Object?>[
          <String, Object?>{'type': 'angleChip', 'key': 'calc.toggle.angle'},
        ],
      },
    ];
    await _pumpSpec(tester, nodes, _context());
    expect(find.byKey(const Key('calc.toggle.angle')), findsNothing);

    await _pumpSpec(tester, nodes, _context(isScientific: true));
    expect(find.byKey(const Key('calc.toggle.angle')), findsOneWidget);
  });

  testWidgets('rechaza un tipo desconocido con un error legible', (
    WidgetTester tester,
  ) async {
    await _pumpSpec(tester, <Object?>[
      <String, Object?>{'type': 'script', 'value': 'print(1)'},
    ], _context());

    expect(
      tester.takeException(),
      isA<SpecRenderException>().having(
        (SpecRenderException error) => error.message,
        'message',
        contains('script'),
      ),
    );
  });

  testWidgets('rechaza una condición desconocida con un error legible', (
    WidgetTester tester,
  ) async {
    await _pumpSpec(tester, <Object?>[
      <String, Object?>{'type': 'display', 'when': 'eval("x")'},
    ], _context());

    expect(
      tester.takeException(),
      isA<SpecRenderException>().having(
        (SpecRenderException error) => error.message,
        'message',
        contains('eval("x")'),
      ),
    );
  });
}
