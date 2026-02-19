import 'package:flutter/material.dart';
import '../shared/widgets/nafas_bottom_nav_bar.dart';
import '../shared/widgets/app_side_menu_drawer.dart';
import '../shared/widgets/home_hijri_location_card.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const List<NafasNavItem> _tabs = [
    NafasNavItem(label: 'Home', icon: Icons.home_rounded),
    NafasNavItem(label: 'Prayers', icon: Icons.mosque_rounded),
    NafasNavItem(label: 'Quran', icon: Icons.menu_book_rounded),
    NafasNavItem(label: 'Guidance', icon: Icons.tips_and_updates_rounded),
    NafasNavItem(label: 'Tools', icon: Icons.widgets_rounded),
  ];

  static const List<Widget> _pages = [
    _HomeTab(),
    _SectionPage(
      entries: [
        _EntryData(
          'Prayer Times',
          'View daily prayer schedule',
          Icons.schedule_rounded,
        ),
        _EntryData('Qibla', 'Find the Qibla direction', Icons.explore_rounded),
      ],
      topWidget: HomeHijriLocationCard(),
    ),
    _SectionPage(
      entries: [
        _EntryData(
          'Read Quran',
          'Continue from your last ayah',
          Icons.menu_book_rounded,
        ),
        _EntryData(
          'Bookmarks',
          'Quick access to saved surahs',
          Icons.bookmarks_rounded,
        ),
        _EntryData(
          'Tafsir',
          'Understand verses with explanations',
          Icons.chrome_reader_mode_rounded,
        ),
        _EntryData(
          'Audio Recitation',
          'Listen by your preferred reciter',
          Icons.graphic_eq_rounded,
        ),
      ],
    ),
    _SectionPage(
      entries: [
        _EntryData('Duas', 'Curated daily duas', Icons.favorite_rounded),
        _EntryData(
          'Adhkar',
          'Morning and evening adhkar',
          Icons.menu_book_rounded,
        ),
        _EntryData(
          'Tasbih',
          'Digital tasbih counter',
          Icons.radio_button_checked_rounded,
        ),
        _EntryData('Fasting', 'Track fasting days', Icons.nights_stay_rounded),
        _EntryData(
          'Sadaqah',
          'Manage charity intentions',
          Icons.volunteer_activism_rounded,
        ),
        _EntryData(
          'Reflections',
          'Short spiritual reflections',
          Icons.lightbulb_rounded,
        ),
        _EntryData(
          'Learning',
          'Bite-sized Islamic lessons',
          Icons.school_rounded,
        ),
      ],
    ),
    _SectionPage(
      entries: [
        _EntryData(
          'Zakat Calculator',
          'Estimate zakat quickly',
          Icons.calculate_rounded,
        ),
        _EntryData(
          'Hijri Calendar',
          'Check Hijri dates',
          Icons.calendar_month_rounded,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppSideMenuDrawer(
        onItemSelected: (itemTitle) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$itemTitle coming soon')));
        },
      ),
      appBar: AppBar(
        title: Text(_tabs[_selectedIndex].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile coming soon')),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NafasBottomNavBar(
        selectedIndex: _selectedIndex,
        items: _tabs,
        onDestinationSelected: (int index) =>
            setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    return const _SectionPage(
      entries: [
        _EntryData(
          'Next Prayer',
          'Dhuhr in 01:42',
          Icons.access_time_filled_rounded,
        ),
        _EntryData(
          'Streak',
          '7 days consistency',
          Icons.local_fire_department_rounded,
        ),
        _EntryData(
          'Reminders',
          '2 active reminders',
          Icons.notifications_active_rounded,
        ),
      ],
      topWidget: HomeHijriLocationCard(),
    );
  }
}

class _SectionPage extends StatelessWidget {
  final List<_EntryData> entries;
  final Widget? topWidget;

  const _SectionPage({required this.entries, this.topWidget});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (topWidget != null) const SizedBox(height: 2),
        if (topWidget != null) topWidget!,
        ...entries.map((entry) {
          final iconBackground = colors.tertiaryContainer;
          final iconColor = colors.onTertiaryContainer;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: colors.outlineVariant),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: iconBackground,
                child: Icon(entry.icon, color: iconColor),
              ),
              title: Text(entry.title),
              subtitle: Text(entry.subtitle),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colors.secondary,
              ),
              onTap: () {},
            ),
          );
        }),
      ],
    );
  }
}

class _EntryData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EntryData(this.title, this.subtitle, this.icon);
}
