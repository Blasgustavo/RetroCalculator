import 'package:flutter/material.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/app.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';
import 'package:retro_calculator/features/calculator/presentation/calculator_page.dart';

void main() {
  testWidgets('la app arranca y muestra la calculadora', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      RetroCalculatorApp(
        historyStore: InMemoryHistoryStore(),
        counters: LocalCounters(),
      ),
    );

    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CalculatorPage)),
    )!;
    expect(find.text(l10n.calculatorTitle), findsOneWidget);
    expect(find.byKey(const Key('calc.key.7')), findsOneWidget);
  });
}
