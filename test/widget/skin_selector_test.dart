import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/app.dart';
import 'package:retro_calculator/core/widgets/calculator_keyboard.dart';
import 'package:retro_calculator/core/widgets/seven_segment_display.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';
import 'package:retro_calculator/features/calculator/presentation/calculator_page.dart';
import 'package:retro_calculator/l10n/app_localizations.dart';

void main() {
  testWidgets('aplica la LCD clásica sin alterar el cálculo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      RetroCalculatorApp(
        historyStore: InMemoryHistoryStore(),
        counters: LocalCounters(),
      ),
    );
    await tester.ensureVisible(find.byKey(const Key('skin.selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skin.selector')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('skin.option.lcd_classica')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('skin.option.lcd_classica')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SevenSegmentDisplay>(find.byKey(const Key('calc.display')))
          .tokens
          .segmentOn,
      const Color(0xFFB8E986),
    );
    expect(
      tester
          .widget<CalculatorKeyboard>(find.byType(CalculatorKeyboard))
          .tokens
          .keyMinHeight,
      greaterThanOrEqualTo(48),
    );
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

  testWidgets(
    'restablecer vuelve al tema gratuito y el historial sigue funcionando',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        RetroCalculatorApp(
          historyStore: InMemoryHistoryStore(),
          counters: LocalCounters(),
        ),
      );
      await tester.ensureVisible(find.byKey(const Key('skin.selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('skin.selector')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('skin.option.lcd_classica')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('skin.option.lcd_classica')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('skin.reset')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('skin.reset')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<SevenSegmentDisplay>(find.byKey(const Key('calc.display')))
            .tokens
            .segmentOn,
        const Color(0xFFFFB000),
      );
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
      final AppLocalizations l10n = AppLocalizations.of(
        tester.element(find.byType(CalculatorPage)),
      )!;
      expect(find.text(l10n.historyTitle), findsOneWidget);
      await tester.ensureVisible(find.text(l10n.historyTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.historyTitle));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('calc.history.0')), findsOneWidget);
    },
  );
}
