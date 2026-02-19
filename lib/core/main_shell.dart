import 'package:flutter/material.dart';
import '../shared/widgets/charm_section.dart';
import '../shared/widgets/nafas_bottom_nav_bar.dart';

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
    NafasNavItem(label: 'Tools', icon: Icons.handyman_rounded),
    NafasNavItem(label: 'Guidance', icon: Icons.tips_and_updates_rounded),
  ];

  static const List<Widget> _pages = [
    _HomeTab(),
    _PrayersTab(),
    _QuranTab(),
    _ToolsTab(),
    _GuidanceTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tabs[_selectedIndex].label)),
      body: IndexedStack(index: _selectedIndex, children: _pages),
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
    return const CharmSection(
      title: 'Today Overview',
      subtitle: 'Your spiritual day at a glance',
      items: [
        CharmItemData(
          'Next Prayer',
          'Dhuhr in 01:42',
          Icons.access_time_filled_rounded,
        ),
        CharmItemData(
          'Streak',
          '7 days consistency',
          Icons.local_fire_department_rounded,
        ),
        CharmItemData(
          'Reminders',
          '2 active reminders',
          Icons.notifications_active_rounded,
        ),
      ],
    );
  }
}

class _PrayersTab extends StatelessWidget {
  const _PrayersTab();

  @override
  Widget build(BuildContext context) {
    return const CharmSection(
      title: 'Prayers',
      subtitle: 'Stay aligned with time and direction',
      items: [
        CharmItemData(
          'Prayer Times',
          'View daily prayer schedule',
          Icons.schedule_rounded,
        ),
        CharmItemData(
          'Qibla',
          'Find the Qibla direction',
          Icons.explore_rounded,
        ),
      ],
    );
  }
}

class _QuranTab extends StatelessWidget {
  const _QuranTab();

  @override
  Widget build(BuildContext context) {
    return const CharmSection(
      title: 'Quran',
      subtitle: 'Read, reflect, and stay connected',
      items: [
        CharmItemData(
          'Read Quran',
          'Continue from your last ayah',
          Icons.menu_book_rounded,
        ),
        CharmItemData(
          'Bookmarks',
          'Quick access to saved surahs',
          Icons.bookmarks_rounded,
        ),
        CharmItemData(
          'Tafsir',
          'Understand verses with explanations',
          Icons.chrome_reader_mode_rounded,
        ),
        CharmItemData(
          'Audio Recitation',
          'Listen by your preferred reciter',
          Icons.graphic_eq_rounded,
        ),
      ],
    );
  }
}

class _ToolsTab extends StatelessWidget {
  const _ToolsTab();

  @override
  Widget build(BuildContext context) {
    return const CharmSection(
      title: 'Tools',
      subtitle: 'Practical Islamic tools',
      items: [
        CharmItemData(
          'Zakat Calculator',
          'Estimate zakat quickly',
          Icons.calculate_rounded,
        ),
        CharmItemData(
          'Hijri Calendar',
          'Check Hijri dates',
          Icons.calendar_month_rounded,
        ),
      ],
    );
  }
}

class _GuidanceTab extends StatelessWidget {
  const _GuidanceTab();

  @override
  Widget build(BuildContext context) {
    return const CharmSection(
      title: 'Guidance',
      subtitle: 'Learn and reflect every day',
      items: [
        CharmItemData('Duas', 'Curated daily duas', Icons.favorite_rounded),
        CharmItemData(
          'Adhkar',
          'Morning and evening adhkar',
          Icons.menu_book_rounded,
        ),
        CharmItemData(
          'Tasbih',
          'Digital tasbih counter',
          Icons.radio_button_checked_rounded,
        ),
        CharmItemData(
          'Fasting',
          'Track fasting days',
          Icons.nights_stay_rounded,
        ),
        CharmItemData(
          'Sadaqah',
          'Manage charity intentions',
          Icons.volunteer_activism_rounded,
        ),
        CharmItemData(
          'Reflections',
          'Short spiritual reflections',
          Icons.lightbulb_rounded,
        ),
        CharmItemData(
          'Learning',
          'Bite-sized Islamic lessons',
          Icons.school_rounded,
        ),
      ],
    );
  }
}
