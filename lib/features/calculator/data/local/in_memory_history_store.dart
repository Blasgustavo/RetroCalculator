import '../models/history_entry.dart';
import 'history_store.dart';

class InMemoryHistoryStore implements HistoryStore {
  static const int maxEntries = 50;

  final List<HistoryEntry> _entries = <HistoryEntry>[];

  @override
  Future<List<HistoryEntry>> load() async =>
      List<HistoryEntry>.unmodifiable(_entries);

  @override
  Future<void> append(HistoryEntry entry) async {
    _entries.insert(0, entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(maxEntries, _entries.length);
    }
  }
}
