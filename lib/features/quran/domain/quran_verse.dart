class QuranVerse {
  final int verseNumber;
  final String verseKey;
  final String arabicText;
  final String translationText;
  final String tafsirText;

  const QuranVerse({
    required this.verseNumber,
    required this.verseKey,
    required this.arabicText,
    required this.translationText,
    required this.tafsirText,
  });

  factory QuranVerse.fromJson(Map<String, dynamic> json) {
    final text =
        (json['text_uthmani'] as String?)?.trim() ??
        (json['text_imlaei'] as String?)?.trim() ??
        (json['text_indopak'] as String?)?.trim() ??
        (json['text_simple'] as String?)?.trim() ??
        '';

    final translations = (json['translations'] as List<dynamic>? ?? const []);
    final translation = translations.isEmpty
        ? const <String, dynamic>{}
        : (translations.first as Map<String, dynamic>);

    final tafsirs = (json['tafsirs'] as List<dynamic>? ?? const []);
    final tafsir = tafsirs.isEmpty
        ? const <String, dynamic>{}
        : (tafsirs.first as Map<String, dynamic>);

    return QuranVerse(
      verseNumber: (json['verse_number'] as num?)?.toInt() ?? 0,
      verseKey: (json['verse_key'] as String? ?? '').trim(),
      arabicText: text,
      translationText: _sanitizeText((translation['text'] as String?) ?? ''),
      tafsirText: _sanitizeText((tafsir['text'] as String?) ?? ''),
    );
  }

  static String _sanitizeText(String raw) {
    final noHtml = raw.replaceAll(RegExp(r'<[^>]*>'), ' ');
    return noHtml.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
