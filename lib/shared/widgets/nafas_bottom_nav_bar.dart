import 'package:flutter/material.dart';

class NafasNavItem {
  final String label;
  final IconData icon;

  const NafasNavItem({required this.label, required this.icon});
}

class NafasBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final List<NafasNavItem> items;
  final ValueChanged<int> onDestinationSelected;

  const NafasBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: colors.outlineVariant),
          NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            indicatorColor: colors.primaryContainer,
            backgroundColor: colors.surface,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            destinations: items
                .map(
                  (item) => NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
