import 'package:flutter/material.dart';

enum QuranViewTab { chapters, juz, bookmarks }

class QuranTopTabs extends StatelessWidget {
  final QuranViewTab selected;
  final ValueChanged<QuranViewTab> onSelected;

  const QuranTopTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Widget tabItem(QuranViewTab tab, String label) {
      final isActive = selected == tab;
      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelected(tab),
          child: Container(
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? colors.primaryContainer : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isActive
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tabItem(QuranViewTab.chapters, 'Chapters'),
          const SizedBox(width: 6),
          tabItem(QuranViewTab.juz, 'Juz'),
          const SizedBox(width: 6),
          tabItem(QuranViewTab.bookmarks, 'Bookmarks'),
        ],
      ),
    );
  }
}
