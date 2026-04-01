import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/library_entry.dart';

class LibraryStore {
  static const _bookmarkIdsKey = 'ujikom_bookmark_ids';
  static const _historyKey = 'ujikom_history_entries';

  Future<Set<int>> loadBookmarkIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_bookmarkIdsKey) ?? const <String>[];
    return raw.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> toggleBookmark(int workId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = await loadBookmarkIds();
    if (ids.contains(workId)) {
      ids.remove(workId);
    } else {
      ids.add(workId);
    }
    await prefs.setStringList(
      _bookmarkIdsKey,
      ids.map((id) => id.toString()).toList(),
    );
  }

  Future<List<ReadingHistoryEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? const <String>[];
    return raw
        .map((item) => jsonDecode(item))
        .whereType<Map<String, dynamic>>()
        .map(ReadingHistoryEntry.fromJson)
        .toList()
      ..sort((a, b) => b.readAt.compareTo(a.readAt));
  }

  Future<void> addHistoryEntry(ReadingHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await loadHistory();

    history.removeWhere(
      (item) =>
          item.workId == entry.workId && item.chapterId == entry.chapterId,
    );
    history.insert(0, entry);

    final trimmed =
        history.take(50).map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_historyKey, trimmed);
  }
}
