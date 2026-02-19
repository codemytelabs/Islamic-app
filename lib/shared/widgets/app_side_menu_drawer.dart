import 'package:flutter/material.dart';

class AppSideMenuDrawer extends StatelessWidget {
  final ValueChanged<String> onItemSelected;

  const AppSideMenuDrawer({super.key, required this.onItemSelected});

  static const List<_MenuItemData> _menuItems = [
    _MenuItemData('Language Setting', Icons.language_rounded),
    _MenuItemData('Preferences', Icons.tune_rounded),
    _MenuItemData('Share App', Icons.share_rounded),
    _MenuItemData('App Theme', Icons.palette_rounded),
    _MenuItemData('Privacy Policy', Icons.privacy_tip_rounded),
    _MenuItemData('Location', Icons.location_on_rounded),
    _MenuItemData('Notifications', Icons.notifications_rounded),
    _MenuItemData('Help & Support', Icons.support_agent_rounded),
    _MenuItemData('About', Icons.info_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              color: colors.primaryContainer,
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _menuItems
                    .map(
                      (item) => ListTile(
                        leading: Icon(item.icon),
                        title: Text(item.title),
                        onTap: () => onItemSelected(item.title),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemData {
  final String title;
  final IconData icon;

  const _MenuItemData(this.title, this.icon);
}
