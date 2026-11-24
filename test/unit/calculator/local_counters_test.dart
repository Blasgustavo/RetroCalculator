import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/calculator/data/local/local_counters.dart';

void main() {
  test('cuenta operaciones sin enviar nada', () {
    final LocalCounters counters = LocalCounters();
    counters.increment(LocalCounters.calculationPerformed);
    counters.increment(LocalCounters.calculationPerformed);
    expect(counters.value(LocalCounters.calculationPerformed), 2);
    expect(counters.value(LocalCounters.scientificModeActivated), 0);
    expect(counters.snapshot(), isA<Map<String, int>>());
  });
}
