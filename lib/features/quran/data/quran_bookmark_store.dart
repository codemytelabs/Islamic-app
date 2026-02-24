import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/quran_bookmark.dart';

class QuranBookmarkStore {
  QuranBookmarkStore._();

  static final QuranBookmarkStore instance = QuranBookmarkStore._();
  static const String _storageKey = 'quran_bookmarks_v1';

  Future<List<QuranBookmark>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => QuranBookmark.fromJson(item as Map<String, dynamic>))
        .where((item) => item.verseKey.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  Future<void> saveAll(List<QuranBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = bookmarks.map((item) => item.toJson()).toList(growable: false);
    await prefs.setString(_storageKey, jsonEncode(payload));
  }
}
