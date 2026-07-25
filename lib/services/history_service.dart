import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_entry.dart';

class HistoryService {
  static const _maxEntries = 100;

  static String _key(String uid) => 'scan_history_$uid';

  Future<List<HistoryEntry>> getHistory(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key(uid)) ?? [];
    final entries = <HistoryEntry>[];
    for (final s in jsonList) {
      try {
        entries.add(HistoryEntry.fromJson(jsonDecode(s)));
      } catch (_) {}
    }
    return entries.reversed.toList();
  }

  Future<void> addEntry(HistoryEntry entry, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key(uid)) ?? [];
    jsonList.add(jsonEncode(entry.toJson()));
    if (jsonList.length > _maxEntries) jsonList.removeAt(0);
    await prefs.setStringList(_key(uid), jsonList);
  }

  Future<void> deleteById(String id, String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_key(uid)) ?? [];
    jsonList.removeWhere((s) {
      try {
        final map = jsonDecode(s) as Map<String, dynamic>;
        return map['id'] == id;
      } catch (_) {
        return false;
      }
    });
    await prefs.setStringList(_key(uid), jsonList);
  }

  Future<void> clearAll(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(uid));
  }
}
