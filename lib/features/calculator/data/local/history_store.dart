import '../models/history_entry.dart';

abstract interface class HistoryStore {
  Future<List<HistoryEntry>> load();
  Future<void> append(HistoryEntry entry);
}
