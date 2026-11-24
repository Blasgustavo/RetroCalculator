import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:retro_calculator/app.dart';
import 'package:retro_calculator/core/widgets/seven_segment_display.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';
import 'package:retro_calculator/features/calculator/presentation/calculator_page.dart';
import 'package:retro_calculator/features/calculator/presentation/viewmodels/calculator_view_model.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';

void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    InMemoryHistoryStore? historyStore,
  }) {
    return tester.pumpWidget(
      RetroCalculatorApp(
        historyStore: historyStore ?? InMemoryHistoryStore(),
        counters: LocalCounters(),
      ),
    );
  }

  testWidgets('calcula y muestra el resultado en el display', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    for (final String key in <String>['2', '+', '3', '=']) {
      await tester.tap(find.byKey(Key('calc.key.$key')));
      await tester.pumpAndSettle();
    }
    expect(
      tester
          .widget<SevenSegmentDisplay>(find.byKey(const Key('calc.display')))
          .text,
      '5',
    );
  });

  testWidgets('el toggle revela las teclas científicas y DEG/RAD', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);
    expect(find.byKey(const Key('calc.key.sin(')), findsNothing);

    await tester.tap(find.byKey(const Key('calc.toggle.mode')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calc.key.sin(')), findsOneWidget);
    await tester.tap(find.byKey(const Key('calc.toggle.angle')));
    await tester.pumpAndSettle();
    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CalculatorPage)),
    )!;
    expect(find.text(l10n.angleRad), findsOneWidget);
  });

  testWidgets('el historial es global y el error está localizado', (
    WidgetTester tester,
  ) async {
    final InMemoryHistoryStore store = InMemoryHistoryStore();
    await pumpApp(tester, historyStore: store);
    final AppLocalizations l10n = AppLocalizations.of(
      tester.element(find.byType(CalculatorPage)),
    )!;
    final CalculatorViewModel vm = Provider.of<CalculatorViewModel>(
      tester.element(find.byType(CalculatorPage)),
      listen: false,
    );

    for (final String key in <String>['1', '/', '0', '=']) {
      await tester.tap(find.byKey(Key('calc.key.$key')));
      await tester.pumpAndSettle();
    }
    expect(find.text(l10n.errorDivisionByZero), findsOneWidget);
    expect(vm.history, isEmpty);

    await tester.tap(find.byKey(const Key('calc.toggle.mode')));
    await tester.pumpAndSettle();
    for (final String key in <String>['2', '+', '3', '=']) {
      await tester.tap(find.byKey(Key('calc.key.$key')));
      await tester.pumpAndSettle();
    }
    expect(
      tester
          .widget<SevenSegmentDisplay>(find.byKey(const Key('calc.display')))
          .text,
      '5',
    );
    expect(vm.history, hasLength(1));
    expect(vm.history.single.profileId.name, 'scientific');
    expect((await store.load()).single.result, 5);

    await tester.tap(find.byKey(const Key('calc.toggle.mode')));
    await tester.pumpAndSettle();
    expect(vm.history, hasLength(1));

    await tester.tap(find.text(l10n.historyTitle));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calc.history.0')), findsOneWidget);
  });
}
