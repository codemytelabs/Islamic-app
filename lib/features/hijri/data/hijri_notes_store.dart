import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/hijri_note.dart';

class HijriNotesStore {
  static const String _notesKey = 'hijri_notes';

  static Future<List<HijriNote>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notesKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => HijriNote.fromJson(item as Map<String, dynamic>))
        .toList(growable: true);
  }

  static Future<void> save(List<HijriNote> notes) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(notes.map((n) => n.toJson()).toList(growable: false));
    await prefs.setString(_notesKey, raw);
  }
}
