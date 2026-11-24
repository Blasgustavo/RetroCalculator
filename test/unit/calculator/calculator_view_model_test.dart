import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';
import 'package:retro_calculator/features/calculator/presentation/viewmodels/calculator_view_model.dart';

void main() {
  test('suma y guarda una entrada global', () async {
    final InMemoryHistoryStore store = InMemoryHistoryStore();
    final LocalCounters counters = LocalCounters();
    final CalculatorViewModel vm = CalculatorViewModel(store, counters);

    vm.input('2');
    vm.input('+');
    vm.input('3');
    await vm.submit();

    expect(vm.displayText, '5');
    expect((await store.load()).single.result, 5);
    expect(counters.value(LocalCounters.calculationPerformed), 1);
  });

  test('expone divisionByZero como clave de error', () async {
    final CalculatorViewModel vm = CalculatorViewModel(
      InMemoryHistoryStore(),
      LocalCounters(),
    );
    vm.input('8');
    vm.input('/');
    vm.input('0');
    await vm.submit();
    expect(vm.errorKey, 'divisionByZero');
  });

  test('el toggle científico incrementa el contador', () {
    final LocalCounters counters = LocalCounters();
    final CalculatorViewModel vm = CalculatorViewModel(
      InMemoryHistoryStore(),
      counters,
    );
    vm.toggleProfile();
    expect(vm.profile.isScientific, isTrue);
    expect(counters.value(LocalCounters.scientificModeActivated), 1);
  });
}
