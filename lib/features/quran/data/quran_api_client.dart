import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/quran_chapter.dart';
import '../domain/quran_verse.dart';

class QuranApiClient {
  QuranApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final Uri _chaptersUri = Uri.parse(
    'https://api.quran.com/api/v4/chapters',
  );

  Future<List<QuranChapter>> fetchChapters() async {
    final response = await _client
        .get(_chaptersUri)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load chapters (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = (decoded['chapters'] as List<dynamic>? ?? const []);

    return raw
        .map((item) => QuranChapter.fromJson(item as Map<String, dynamic>))
        .where((chapter) => chapter.id > 0)
        .toList(growable: false);
  }

  Future<List<QuranVerse>> fetchVersesByChapter(int chapterId) async {
    final uri = Uri.parse(
      'https://api.quran.com/api/v4/verses/by_chapter/$chapterId?language=en&words=false&per_page=300&translations=131&tafsirs=169&fields=text_uthmani,verse_key,verse_number',
    );

    final response = await _client.get(uri).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to load verses (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = (decoded['verses'] as List<dynamic>? ?? const []);

    return raw
        .map((item) => QuranVerse.fromJson(item as Map<String, dynamic>))
        .where((verse) => verse.arabicText.isNotEmpty)
        .toList(growable: false);
  }
}
