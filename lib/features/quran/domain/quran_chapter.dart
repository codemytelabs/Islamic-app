class QuranChapter {
  final int id;
  final String arabicName;
  final String englishName;
  final String englishMeaning;
  final bool hasBismillahPre;
  final int startPage;
  final int endPage;

  const QuranChapter({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.englishMeaning,
    required this.hasBismillahPre,
    required this.startPage,
    required this.endPage,
  });

  factory QuranChapter.fromJson(Map<String, dynamic> json) {
    final translatedName =
        (json['translated_name'] as Map<String, dynamic>? ?? const {});
    final pages = (json['pages'] as List<dynamic>? ?? const []);
    final startPage = pages.isEmpty ? 1 : (pages.first as num?)?.toInt() ?? 1;
    final endPage = pages.length < 2
        ? startPage
        : (pages[1] as num?)?.toInt() ?? startPage;

    return QuranChapter(
      id: (json['id'] as num?)?.toInt() ?? 0,
      arabicName: (json['name_arabic'] as String? ?? '').trim(),
      englishName: (json['name_simple'] as String? ?? '').trim(),
      englishMeaning: (translatedName['name'] as String? ?? '').trim(),
      hasBismillahPre: json['bismillah_pre'] == true,
      startPage: startPage,
      endPage: endPage,
    );
  }
}
