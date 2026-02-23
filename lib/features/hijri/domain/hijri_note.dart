class HijriNote {
  final String id;
  final int hYear;
  final int hMonth;
  final int hDay;
  final DateTime gDate;
  final String content;
  final DateTime createdAt;

  const HijriNote({
    required this.id,
    required this.hYear,
    required this.hMonth,
    required this.hDay,
    required this.gDate,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hYear': hYear,
      'hMonth': hMonth,
      'hDay': hDay,
      'gDate': gDate.toIso8601String(),
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory HijriNote.fromJson(Map<String, dynamic> json) {
    return HijriNote(
      id: json['id'] as String,
      hYear: json['hYear'] as int,
      hMonth: json['hMonth'] as int,
      hDay: json['hDay'] as int,
      gDate: DateTime.parse(json['gDate'] as String),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
