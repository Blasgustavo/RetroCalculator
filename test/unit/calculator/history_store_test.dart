import 'package:flutter_test/flutter_test.dart';
import 'package:retro_calculator/features/calculator/data/local/history_store.dart';
import 'package:retro_calculator/features/calculator/data/local/in_memory_history_store.dart';
import 'package:retro_calculator/features/calculator/data/models/history_entry.dart';
import 'package:retro_calculator/features/calculator/domain/profiles/calculator_profile.dart';

void main() {
  test('conserva como máximo 50 entradas y la última va primero', () async {
    final HistoryStore store = InMemoryHistoryStore();
    for (int i = 0; i < 51; i++) {
      await store.append(
        HistoryEntry(
          expression: '$i',
          result: i.toDouble(),
          profileId: CalculatorProfileId.normal,
          timestamp: DateTime(2026, 11, 24, 0, i),
        ),
      );
    }
    final List<HistoryEntry> entries = await store.load();
    expect(entries, hasLength(50));
    expect(entries.first.expression, '50');
    expect(entries.last.expression, '1');
  });
}
