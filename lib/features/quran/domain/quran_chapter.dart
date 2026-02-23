class QuranChapter {
  final int id;
  final String arabicName;
  final String englishName;
  final String englishMeaning;

  const QuranChapter({
    required this.id,
    required this.arabicName,
    required this.englishName,
    required this.englishMeaning,
  });

  factory QuranChapter.fromJson(Map<String, dynamic> json) {
    final translatedName =
        (json['translated_name'] as Map<String, dynamic>? ?? const {});

    return QuranChapter(
      id: (json['id'] as num?)?.toInt() ?? 0,
      arabicName: (json['name_arabic'] as String? ?? '').trim(),
      englishName: (json['name_simple'] as String? ?? '').trim(),
      englishMeaning: (translatedName['name'] as String? ?? '').trim(),
    );
  }
}
