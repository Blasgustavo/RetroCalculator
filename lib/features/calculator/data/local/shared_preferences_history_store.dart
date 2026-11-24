import 'dart:convert';

import '../../../../platform/preferences/key_value_store.dart';
import '../models/history_entry.dart';
import 'history_store.dart';
import 'in_memory_history_store.dart';

class SharedPreferencesHistoryStore implements HistoryStore {
  SharedPreferencesHistoryStore(this._store);

  static const String storageKey = 'calculator.history.v1';

  final KeyValueStore _store;

  @override
  Future<List<HistoryEntry>> load() async {
    final String? raw = await _store.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return <HistoryEntry>[];
    }
    final Object? decoded = jsonDecode(raw);
    if (decoded is! List<Object?>) {
      return <HistoryEntry>[];
    }
    return decoded
        .whereType<Map<String, Object?>>()
        .map(HistoryEntry.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> append(HistoryEntry entry) async {
    final List<HistoryEntry> entries = <HistoryEntry>[entry, ...await load()];
    final List<Map<String, Object?>> serializable = entries
        .take(InMemoryHistoryStore.maxEntries)
        .map((HistoryEntry item) => item.toJson())
        .toList(growable: false);
    await _store.setString(storageKey, jsonEncode(serializable));
  }
}
