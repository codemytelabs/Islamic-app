import 'package:flutter/material.dart';

class CharmItemData {
  final String title;
  final String subtitle;
  final IconData icon;

  const CharmItemData(this.title, this.subtitle, this.icon);
}

class CharmSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<CharmItemData> items;

  const CharmSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _CharmCard(item: item)),
      ],
    );
  }
}

class _CharmCard extends StatelessWidget {
  final CharmItemData item;

  const _CharmCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.primary,
          child: Icon(item.icon),
        ),
        title: Text(item.title),
        subtitle: Text(item.subtitle),
        trailing: Icon(Icons.chevron_right_rounded, color: colors.primary),
      ),
    );
  }
}
