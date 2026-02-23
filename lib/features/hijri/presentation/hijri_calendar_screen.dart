import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../data/hijri_notes_store.dart';
import '../domain/hijri_note.dart';

class HijriCalendarScreen extends StatelessWidget {
  const HijriCalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hijri Calendar'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Calendar'),
              Tab(text: 'Converter'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_HijriCalendarTab(), _HijriConverterTab()],
        ),
      ),
    );
  }
}

class _HijriCalendarTab extends StatefulWidget {
  const _HijriCalendarTab();

  @override
  State<_HijriCalendarTab> createState() => _HijriCalendarTabState();
}

class _HijriCalendarTabState extends State<_HijriCalendarTab> {
  static const int _minYear = 1356;
  static const int _maxYear = 1500;
  static const List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = [
    'Muharram',
    'Safar',
    'Rabi I',
    'Rabi II',
    'Jumada I',
    'Jumada II',
    'Rajab',
    'Shaaban',
    'Ramadan',
    'Shawwal',
    'Dhul Qadah',
    'Dhul Hijjah',
  ];

  late final PageController _pageController;
  late int _currentPage;
  List<HijriNote> _notes = const [];

  @override
  void initState() {
    super.initState();
    HijriCalendar.setLocal('en');
    final todayHijri = HijriCalendar.now();
    _currentPage = _toPage(todayHijri.hYear, todayHijri.hMonth);
    _pageController = PageController(initialPage: _currentPage);
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await HijriNotesStore.load();
    if (!mounted) return;
    setState(() => _notes = notes);
  }

  int _toPage(int year, int month) => ((year - _minYear) * 12) + (month - 1);

  (int year, int month) _fromPage(int page) {
    final year = _minYear + (page ~/ 12);
    final month = (page % 12) + 1;
    return (year, month);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (year, month) = _fromPage(_currentPage);
    final monthNotes = _notesForMonth(year, month);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: _currentPage > 0
                    ? () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      )
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_months[month - 1]} $year AH',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _currentPage < ((_maxYear - _minYear + 1) * 12) - 1
                    ? () => _pageController.nextPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      )
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: _weekDays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          flex: 3,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: (_maxYear - _minYear + 1) * 12,
            itemBuilder: (context, index) {
              final (pageYear, pageMonth) = _fromPage(index);
              final monthDaysWithNotes = _notes
                  .where((n) => n.hYear == pageYear && n.hMonth == pageMonth)
                  .map((n) => n.hDay)
                  .toSet();

              return _HijriMonthGrid(
                year: pageYear,
                month: pageMonth,
                daysWithNotes: monthDaysWithNotes,
                onDayTap: (day) =>
                    _openNoteSheet(year: pageYear, month: pageMonth, day: day),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              Text(
                'Month Notes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${monthNotes.length}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.onTertiaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_months[month - 1]} $year AH',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: monthNotes.isEmpty
              ? Center(
                  child: Text(
                    'No notes for this month yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: monthNotes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final note = monthNotes[index];
                    final isPast = _dayOnly(
                      note.gDate,
                    ).isBefore(_dayOnly(DateTime.now()));

                    return Card(
                      margin: EdgeInsets.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: colors.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${note.hDay} ${_months[note.hMonth - 1]} ${note.hYear} AH',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Edit note',
                                  onPressed: () => _openNoteSheet(
                                    year: note.hYear,
                                    month: note.hMonth,
                                    day: note.hDay,
                                    existingNote: note,
                                  ),
                                  icon: Icon(
                                    Icons.edit_rounded,
                                    size: 18,
                                    color: colors.primary,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete note',
                                  onPressed: () => _deleteNote(note),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: Color(0xFFB91C1C),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isPast
                                        ? const Color(0xFFFEE2E2)
                                        : colors.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    isPast ? 'Passed' : 'Upcoming',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isPast
                                              ? const Color(0xFF991B1B)
                                              : colors.onPrimaryContainer,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              MaterialLocalizations.of(
                                context,
                              ).formatMediumDate(note.gDate),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF6B7280)),
                            ),
                            const SizedBox(height: 6),
                            Text(note.content),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<HijriNote> _notesForMonth(int year, int month) {
    final list = _notes
        .where((n) => n.hYear == year && n.hMonth == month)
        .toList(growable: true);

    final today = _dayOnly(DateTime.now());
    list.sort((a, b) {
      final aDate = _dayOnly(a.gDate);
      final bDate = _dayOnly(b.gDate);

      final aIsFutureOrToday = !aDate.isBefore(today);
      final bIsFutureOrToday = !bDate.isBefore(today);

      if (aIsFutureOrToday != bIsFutureOrToday) {
        return aIsFutureOrToday ? -1 : 1;
      }

      if (aIsFutureOrToday) {
        return aDate.compareTo(bDate);
      }

      return bDate.compareTo(aDate);
    });

    return list;
  }

  DateTime _dayOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> _openNoteSheet({
    required int year,
    required int month,
    required int day,
    HijriNote? existingNote,
  }) async {
    final textController = TextEditingController(
      text: existingNote?.content ?? '',
    );
    final formKey = GlobalKey<FormState>();
    final gDate = HijriCalendar().hijriToGregorian(year, month, day);
    final isEditing = existingNote != null;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Note' : 'Add Note',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$day ${_months[month - 1]} $year AH • ${MaterialLocalizations.of(context).formatMediumDate(gDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: textController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Write your note or todo...',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a note';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final note = HijriNote(
                            id:
                                existingNote?.id ??
                                DateTime.now().microsecondsSinceEpoch
                                    .toString(),
                            hYear: year,
                            hMonth: month,
                            hDay: day,
                            gDate: _dayOnly(gDate),
                            content: textController.text.trim(),
                            createdAt:
                                existingNote?.createdAt ?? DateTime.now(),
                          );

                          final updatedNotes = [..._notes];
                          if (isEditing) {
                            final index = updatedNotes.indexWhere(
                              (n) => n.id == existingNote.id,
                            );
                            if (index != -1) {
                              updatedNotes[index] = note;
                            }
                          } else {
                            updatedNotes.add(note);
                          }

                          await HijriNotesStore.save(updatedNotes);

                          if (!mounted) return;
                          setState(() => _notes = updatedNotes);
                          Navigator.of(context).pop();
                        },
                        child: Text(isEditing ? 'Update' : 'Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteNote(HijriNote note) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete note?'),
          content: const Text('This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final updatedNotes = _notes.where((n) => n.id != note.id).toList();
    await HijriNotesStore.save(updatedNotes);

    if (!mounted) return;
    setState(() => _notes = updatedNotes);
  }
}

class _HijriMonthGrid extends StatelessWidget {
  final int year;
  final int month;
  final Set<int> daysWithNotes;
  final ValueChanged<int> onDayTap;

  const _HijriMonthGrid({
    required this.year,
    required this.month,
    required this.daysWithNotes,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final helper = HijriCalendar();
    final daysInMonth = helper.getDaysInMonth(year, month);
    final firstGregorian = helper.hijriToGregorian(year, month, 1);
    final leadingEmpty = firstGregorian.weekday - 1;
    final totalCells = leadingEmpty + daysInMonth;

    final today = HijriCalendar.now();
    final isCurrentMonth = today.hYear == year && today.hMonth == month;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1.05,
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        if (index < leadingEmpty) {
          return const SizedBox.shrink();
        }

        final day = (index - leadingEmpty) + 1;
        final gregorianDay = helper.hijriToGregorian(year, month, day).day;
        final isToday = isCurrentMonth && today.hDay == day;
        final hasNote = daysWithNotes.contains(day);

        return Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onDayTap(day),
            child: Container(
              width: 40,
              height: 44,
              decoration: BoxDecoration(
                color: isToday ? colors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
                      color: isToday ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                  Text(
                    '$gregorianDay',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isToday
                          ? colors.onPrimary.withValues(alpha: 0.85)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: hasNote
                          ? (isToday ? colors.onPrimary : colors.tertiary)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HijriConverterTab extends StatefulWidget {
  const _HijriConverterTab();

  @override
  State<_HijriConverterTab> createState() => _HijriConverterTabState();
}

class _HijriConverterTabState extends State<_HijriConverterTab> {
  static const List<String> _months = [
    'Muharram',
    'Safar',
    'Rabi I',
    'Rabi II',
    'Jumada I',
    'Jumada II',
    'Rajab',
    'Shaaban',
    'Ramadan',
    'Shawwal',
    'Dhul Qadah',
    'Dhul Hijjah',
  ];

  DateTime _gregorianDate = DateTime.now();

  late int _hYear;
  late int _hMonth;
  late int _hDay;

  @override
  void initState() {
    super.initState();
    HijriCalendar.setLocal('en');
    final current = HijriCalendar.now();
    _hYear = current.hYear;
    _hMonth = current.hMonth;
    _hDay = current.hDay;
  }

  int _daysInHijriMonth(int year, int month) {
    final helper = HijriCalendar();
    return helper.getDaysInMonth(year, month);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hijriFromGregorian = HijriCalendar.fromDate(_gregorianDate);
    final convertedGregorian = HijriCalendar().hijriToGregorian(
      _hYear,
      _hMonth,
      _hDay,
    );

    final maxDays = _daysInHijriMonth(_hYear, _hMonth);
    if (_hDay > maxDays) {
      _hDay = maxDays;
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          color: colors.primaryContainer.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gregorian → Hijri',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _gregorianDate,
                      firstDate: DateTime(1937, 3, 14),
                      lastDate: DateTime(2077, 11, 16),
                    );
                    if (picked == null) return;
                    setState(() => _gregorianDate = picked);
                  },
                  icon: const Icon(Icons.calendar_today_rounded),
                  label: Text(
                    MaterialLocalizations.of(
                      context,
                    ).formatMediumDate(_gregorianDate),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${hijriFromGregorian.toFormat('dd MMMM yyyy')} AH',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: colors.tertiaryContainer.withValues(alpha: 0.28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hijri → Gregorian',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _hDay,
                        decoration: const InputDecoration(labelText: 'Day'),
                        items: List.generate(maxDays, (i) => i + 1)
                            .map(
                              (value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value'),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _hDay = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: _hMonth,
                        decoration: const InputDecoration(labelText: 'Month'),
                        items: List.generate(12, (i) => i + 1)
                            .map(
                              (value) => DropdownMenuItem<int>(
                                value: value,
                                child: Text(_months[value - 1]),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _hMonth = value;
                            final newMax = _daysInHijriMonth(_hYear, _hMonth);
                            if (_hDay > newMax) _hDay = newMax;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: _hYear,
                  decoration: const InputDecoration(labelText: 'Year'),
                  items: List.generate(1500 - 1356 + 1, (i) => 1356 + i)
                      .map(
                        (value) => DropdownMenuItem<int>(
                          value: value,
                          child: Text('$value AH'),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _hYear = value;
                      final newMax = _daysInHijriMonth(_hYear, _hMonth);
                      if (_hDay > newMax) _hDay = newMax;
                    });
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatMediumDate(convertedGregorian),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
