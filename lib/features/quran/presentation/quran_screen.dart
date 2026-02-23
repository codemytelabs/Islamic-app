import 'package:flutter/material.dart';

import '../data/quran_repository.dart';
import '../domain/quran_chapter.dart';
import '../domain/quran_verse.dart';
import 'widgets/quran_top_tabs.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final QuranRepository _repository = QuranRepository.instance;

  QuranViewTab _selectedTab = QuranViewTab.chapters;
  List<QuranChapter> _chapters = const [];
  List<QuranVerse> _verses = const [];
  QuranChapter? _selectedChapter;
  bool _isLoadingChapters = true;
  bool _isLoadingVerses = false;
  String? _error;
  bool _showTranslationForAll = false;
  bool _showTafsirForAll = false;
  final Set<String> _expandedTranslationVerses = <String>{};
  final Set<String> _expandedTafsirVerses = <String>{};
  final Set<String> _bookmarkedVerses = <String>{};

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoadingChapters = true;
      _error = null;
    });

    try {
      final chapters = await _repository.getChapters();
      if (!mounted) return;

      setState(() {
        _chapters = chapters;
        _selectedChapter = chapters.isNotEmpty ? chapters.first : null;
        _isLoadingChapters = false;
      });

      if (_selectedChapter != null) {
        await _loadVerses(_selectedChapter!.id);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load chapters right now';
        _isLoadingChapters = false;
      });
    }
  }

  Future<void> _loadVerses(int chapterId) async {
    setState(() {
      _isLoadingVerses = true;
      _error = null;
      _expandedTranslationVerses.clear();
      _expandedTafsirVerses.clear();
      _showTranslationForAll = false;
      _showTafsirForAll = false;
    });

    try {
      final verses = await _repository.getVersesByChapter(chapterId);
      if (!mounted) return;
      setState(() {
        _verses = verses;
        _isLoadingVerses = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load verses right now';
        _isLoadingVerses = false;
      });
    }
  }

  void _onTabSelected(QuranViewTab tab) {
    setState(() => _selectedTab = tab);
    if (tab == QuranViewTab.chapters) {
      _openChapterDrawer();
    }
  }

  void _openChapterDrawer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = _scaffoldKey.currentState;
      if (state != null && !state.isDrawerOpen) {
        state.openDrawer();
      }
    });
  }

  void _onSelectChapter(QuranChapter chapter) {
    setState(() {
      _selectedChapter = chapter;
    });
    Navigator.of(context).pop();
    _loadVerses(chapter.id);
  }

  Widget _buildChapterDrawer(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chapters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _chapters.isEmpty
                  ? const Center(child: Text('No chapters found'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _chapters.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        thickness: 0.8,
                        color: colors.outlineVariant.withValues(alpha: 0.45),
                      ),
                      itemBuilder: (context, index) {
                        final chapter = _chapters[index];
                        final isSelected = _selectedChapter?.id == chapter.id;

                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: colors.primaryContainer.withValues(
                            alpha: 0.45,
                          ),
                          onTap: () => _onSelectChapter(chapter),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${chapter.id}. ${chapter.englishName}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  chapter.arabicName,
                                  textAlign: TextAlign.right,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            chapter.englishMeaning,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChaptersContent(BuildContext context) {
    if (_isLoadingChapters && _chapters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _chapters.isEmpty) {
      return Center(child: Text(_error!));
    }

    final chapterButtonLabel = _selectedChapter == null
      ? 'Select chapter'
      : '${_selectedChapter!.englishName} . ${_selectedChapter!.arabicName}';

    bool shouldShowTranslation(QuranVerse verse) {
      return _showTranslationForAll ||
          _expandedTranslationVerses.contains(verse.verseKey);
    }

    bool shouldShowTafsir(QuranVerse verse) {
      return _showTafsirForAll || _expandedTafsirVerses.contains(verse.verseKey);
    }

    void toggleVerseTranslation(QuranVerse verse) {
      setState(() {
        if (_expandedTranslationVerses.contains(verse.verseKey)) {
          _expandedTranslationVerses.remove(verse.verseKey);
        } else {
          _expandedTranslationVerses.add(verse.verseKey);
        }
      });
    }

    void toggleVerseTafsir(QuranVerse verse) {
      setState(() {
        if (_expandedTafsirVerses.contains(verse.verseKey)) {
          _expandedTafsirVerses.remove(verse.verseKey);
        } else {
          _expandedTafsirVerses.add(verse.verseKey);
        }
      });
    }

    void toggleBookmark(QuranVerse verse) {
      setState(() {
        if (_bookmarkedVerses.contains(verse.verseKey)) {
          _bookmarkedVerses.remove(verse.verseKey);
        } else {
          _bookmarkedVerses.add(verse.verseKey);
        }
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton(
              onPressed: _openChapterDrawer,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                minimumSize: const Size(190, 44),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      chapterButtonLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Spacer(),
            IconButton(
              tooltip: 'Toggle translation for all verses',
              onPressed: () {
                setState(() {
                  _showTranslationForAll = !_showTranslationForAll;
                });
              },
              icon: Icon(
                _showTranslationForAll
                    ? Icons.translate_rounded
                    : Icons.translate_outlined,
                size: 18,
              ),
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            ),
            IconButton(
              tooltip: 'Toggle tafsir for all verses',
              onPressed: () {
                setState(() {
                  _showTafsirForAll = !_showTafsirForAll;
                });
              },
              icon: Icon(
                _showTafsirForAll
                    ? Icons.menu_book_rounded
                    : Icons.menu_book_outlined,
                size: 18,
              ),
              visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isLoadingVerses
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : _verses.isEmpty
              ? const Center(child: Text('No verses found for this chapter'))
              : ListView.separated(
                  itemCount: _verses.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 0.7,
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.40),
                  ),
                  itemBuilder: (context, index) {
                    final verse = _verses[index];
                    final showTranslation = shouldShowTranslation(verse);
                    final showTafsir = shouldShowTafsir(verse);
                    final isBookmarked = _bookmarkedVerses.contains(verse.verseKey);

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(2, 10, 2, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            verse.arabicText,
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.titleLarge,
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  verse.verseKey.isNotEmpty
                                      ? verse.verseKey
                                      : 'Ayah ${verse.verseNumber}',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              IconButton(
                                onPressed: () => toggleVerseTranslation(verse),
                                icon: Icon(
                                  showTranslation
                                      ? Icons.translate_rounded
                                      : Icons.translate_outlined,
                                  size: 16,
                                ),
                                tooltip: 'Show translation',
                              ),
                              IconButton(
                                onPressed: () => toggleVerseTafsir(verse),
                                icon: Icon(
                                  showTafsir
                                      ? Icons.menu_book_rounded
                                      : Icons.menu_book_outlined,
                                  size: 16,
                                ),
                                tooltip: 'Show tafsir',
                              ),
                              IconButton(
                                onPressed: () => toggleBookmark(verse),
                                icon: Icon(
                                  isBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  size: 16,
                                ),
                                tooltip: 'Bookmark verse',
                              ),
                            ],
                          ),
                          if (showTranslation && verse.translationText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2, bottom: 6),
                              child: Text(
                                verse.translationText,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          if (showTafsir && verse.tafsirText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                verse.tafsirText,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildJuzPlaceholder(BuildContext context) {
    return const Center(child: Text('Juz list coming soon'));
  }

  Widget _buildBookmarksPlaceholder(BuildContext context) {
    return const Center(child: Text('Bookmarks coming soon'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildChapterDrawer(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            QuranTopTabs(selected: _selectedTab, onSelected: _onTabSelected),
            const SizedBox(height: 12),
            Expanded(
              child: switch (_selectedTab) {
                QuranViewTab.chapters => _buildChaptersContent(context),
                QuranViewTab.juz => _buildJuzPlaceholder(context),
                QuranViewTab.bookmarks => _buildBookmarksPlaceholder(context),
              },
            ),
          ],
        ),
      ),
    );
  }
}
