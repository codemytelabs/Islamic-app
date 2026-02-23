import '../domain/quran_chapter.dart';
import '../domain/quran_verse.dart';
import 'quran_api_client.dart';

class QuranRepository {
  QuranRepository({QuranApiClient? apiClient})
    : _apiClient = apiClient ?? QuranApiClient();

  static final QuranRepository instance = QuranRepository();

  final QuranApiClient _apiClient;

  List<QuranChapter>? _chaptersCache;
  final Map<int, List<QuranVerse>> _versesByChapterCache = {};

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
    final cache = _versesByChapterCache[chapterId];
    if (cache != null && cache.isNotEmpty) {
      return cache;
    }

    final verses = await _apiClient.fetchVersesByChapter(chapterId);
    _versesByChapterCache[chapterId] = verses;
    return verses;
  }
}
