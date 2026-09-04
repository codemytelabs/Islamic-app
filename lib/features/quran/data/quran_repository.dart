import '../domain/quran_chapter.dart';
import '../domain/quran_verse.dart';
import 'quran_api_client.dart';

class QuranRepository {
  QuranRepository({QuranApiClient? apiClient})
    : _apiClient = apiClient ?? QuranApiClient();

  static final QuranRepository instance = QuranRepository();

  final QuranApiClient _apiClient;

  List<QuranChapter>? _chaptersCache;
  final Map<String, List<QuranVerse>> _versesCache = {};

  Future<List<QuranChapter>> getChapters() async {
    final cache = _chaptersCache;
    if (cache != null && cache.isNotEmpty) {
      return cache;
    }

    final chapters = await _apiClient.fetchChapters();
    _chaptersCache = chapters;
    return chapters;
  }

  Future<List<QuranVerse>> getVersesByChapter(int chapterId) async {
    final cacheKey = 'chapter:$chapterId';
    final cache = _versesCache[cacheKey];
    if (cache != null && cache.isNotEmpty) {
      return cache;
    }

    final verses = await _apiClient.fetchVersesByChapter(chapterId);
    _versesCache[cacheKey] = verses;
    return verses;
  }

  Future<List<QuranVerse>> getVersesByChapterPages(QuranChapter chapter) async {
    final cacheKey = 'pages:${chapter.id}:${chapter.startPage}-${chapter.endPage}';
    final cache = _versesCache[cacheKey];
    if (cache != null && cache.isNotEmpty) {
      return cache;
    }

    final collected = <QuranVerse>[];
    final seen = <String>{};

    for (var page = chapter.startPage; page <= chapter.endPage; page++) {
      final pageVerses = await _apiClient.fetchVersesByPage(page);
      for (final verse in pageVerses) {
        if (!_isVerseInChapter(verse, chapter.id)) continue;
        if (seen.contains(verse.verseKey)) continue;
        seen.add(verse.verseKey);
        collected.add(verse);
      }
    }

    _versesCache[cacheKey] = collected;
    return collected;
  }

  bool _isVerseInChapter(QuranVerse verse, int chapterId) {
    final key = verse.verseKey;
    if (key.isEmpty) return false;
    final parts = key.split(':');
    if (parts.length != 2) return false;
    final parsedChapter = int.tryParse(parts.first);
    return parsedChapter == chapterId;
  }
}
