class QuranBookmark {
  final String verseKey;
  final int chapterId;
  final String chapterEnglishName;
  final String chapterArabicName;
  final int verseNumber;
  final String arabicText;
  final String translationText;
  final String note;
  final DateTime savedAt;

  const QuranBookmark({
    required this.verseKey,
    required this.chapterId,
    required this.chapterEnglishName,
    required this.chapterArabicName,
    required this.verseNumber,
    required this.arabicText,
    required this.translationText,
    required this.note,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'verseKey': verseKey,
      'chapterId': chapterId,
      'chapterEnglishName': chapterEnglishName,
      'chapterArabicName': chapterArabicName,
      'verseNumber': verseNumber,
      'arabicText': arabicText,
      'translationText': translationText,
      'note': note,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory QuranBookmark.fromJson(Map<String, dynamic> json) {
    return QuranBookmark(
      verseKey: (json['verseKey'] as String? ?? '').trim(),
      chapterId: (json['chapterId'] as num?)?.toInt() ?? 0,
      chapterEnglishName: (json['chapterEnglishName'] as String? ?? '').trim(),
      chapterArabicName: (json['chapterArabicName'] as String? ?? '').trim(),
      verseNumber: (json['verseNumber'] as num?)?.toInt() ?? 0,
      arabicText: (json['arabicText'] as String? ?? '').trim(),
      translationText: (json['translationText'] as String? ?? '').trim(),
      note: (json['note'] as String? ?? '').trim(),
      savedAt:
          DateTime.tryParse((json['savedAt'] as String? ?? '').trim()) ??
          DateTime.now(),
    );
  }
}
