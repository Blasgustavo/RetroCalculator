import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/design_system/skin_tokens.dart';
import 'package:retro_calculator/core/widgets/spec_renderer.dart';
import 'package:retro_calculator/features/skins/data/generated/screens.g.dart';

const List<String> _screens = <String>['normal', 'scientific', 'selector'];
const List<String> _breakpoints = <String>['mobile', 'tablet', 'desktop'];

SpecRenderContext _context({required bool isScientific}) {
  const SkinTokens tokens = SkinTokens.classicAmber;
  const List<List<String>> rows = <List<String>>[
    <String>['C', '7', '8', '9', '/'],
    <String>['4', '5', '6', '*', '='],
  ];
  return SpecRenderContext(
    tokens: tokens,
    keyboardHeight: tokens.keyboardHeight,
    displayText: '1234',
    errorLabel: 'Division by zero',
    rows: rows,
    labels: <String, String>{
      for (final List<String> row in rows)
        for (final String key in row) key: key,
    },
    isScientific: isScientific,
    angleSelected: false,
    strings: const <String, String>{
      'angleDeg': 'DEG',
      'angleRad': 'RAD',
      'historyTitle': 'History',
      'historyEmpty': 'No calculations yet',
    },
    historyBuilder: (BuildContext context, String? titleKey) => ListTile(
      title: Text(titleKey ?? 'history'),
      subtitle: const Text('No calculations yet'),
    ),
    selectorBuilder: (BuildContext context) =>
        const ListTile(title: Text('Skin selector')),
  );
}

Widget _goldenApp(List<Object?> nodes, SpecRenderContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(fontFamily: 'Ahem'),
    home: Scaffold(
      body: SingleChildScrollView(
        child: SpecRenderer(
          key: const Key('spec-root'),
          nodes: nodes,
          renderContext: context,
        ),
      ),
    ),
  );
}

void main() {
  for (final String screen in _screens) {
    for (final String breakpoint in _breakpoints) {
      testWidgets('golden $screen/$breakpoint', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = 1.0;
        addTearDown(() {
          tester.platformDispatcher.clearTextScaleFactorTestValue();
          tester.view.reset();
        });

        final List<Object?> nodes = screenSpecs[screen]![breakpoint]!;
        await tester.pumpWidget(
          _goldenApp(nodes, _context(isScientific: screen == 'scientific')),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const Key('spec-root')),
          matchesGoldenFile('spec_renderer_${screen}_$breakpoint.png'),
        );
      });
    }
  }
}
