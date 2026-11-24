import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/core/i18n/number_formatting.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';
import 'package:retro_calculator/features/calculator/domain/engine/calculator_engine.dart';
import 'package:retro_calculator/features/calculator/domain/profiles/profiles.dart';
import 'package:retro_calculator/features/calculator/presentation/viewmodels/calculator_view_model.dart';

void main() {
  test('historial y contadores no alteran el resultado base', () async {
    final InMemoryHistoryStore store = InMemoryHistoryStore();
    final LocalCounters counters = LocalCounters();
    final CalculatorViewModel vm = CalculatorViewModel(store, counters);

    vm.input('2');
    vm.input('+');
    vm.input('3');
    await vm.submit();

    final double direct = const CalculatorEngine().evaluate(
      '2+3',
      CalculatorProfiles.normal,
    );
    expect(
      vm.displayText,
      formatNumber(
        direct,
        separator: DecimalSeparator.comma,
        maxFractionDigits: CalculatorProfiles.normal.decimalDigits,
      ),
    );
    expect(counters.value(LocalCounters.calculationPerformed), 1);
  });
}
