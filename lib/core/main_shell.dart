import 'dart:async';

import 'package:flutter/material.dart';
import '../features/hijri/presentation/hijri_calendar_screen.dart';
import '../features/mosques/presentation/nearby_mosques_screen.dart';
import '../features/quran/presentation/quran_screen.dart';
import '../features/qibla/presentation/qibla_screen.dart';
import '../shared/services/location_cache_service.dart';
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

  @override
  void initState() {
    super.initState();
    unawaited(LocationCacheService.instance.warmUp());
  }

  List<Widget> _buildPages() {
    return [
      _SectionPage(
        entries: const [
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
        topWidget: const HomeHijriLocationCard(),
        onEntryTap: _onEntryTap,
      ),
      _PrayersTabContent(
        topWidget: const HomeHijriLocationCard(),
        onOpenQibla: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const QiblaScreen(
                topWidget: HomeHijriLocationCard(),
              ),
            ),
          );
        },
      ),
      const QuranScreen(),
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
          _EntryData(
            'Fasting',
            'Track fasting days',
            Icons.nights_stay_rounded,
          ),
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
        onEntryTap: _onEntryTap,
      ),
      _SectionPage(
        entries: [
          _EntryData(
            'Hijri Calendar',
            'Check Hijri dates',
            Icons.calendar_month_rounded,
            action: _EntryAction.openHijriCalendar,
          ),
          _EntryData(
            'Qibla',
            'Find the Qibla direction',
            Icons.explore_rounded,
            action: _EntryAction.openQibla,
          ),
          _EntryData(
            'Zakat Calculator',
            'Estimate zakat quickly',
            Icons.calculate_rounded,
          ),
        ],
        onEntryTap: _onEntryTap,
      ),
    ];
  }

  void _onEntryTap(_EntryData entry) {
    switch (entry.action) {
      case _EntryAction.openHijriCalendar:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const HijriCalendarScreen()),
        );
        break;
      case _EntryAction.openQibla:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const QiblaScreen(topWidget: HomeHijriLocationCard()),
          ),
        );
        break;
      case null:
        break;
    }
  }

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
      body: _buildPages()[_selectedIndex],
      bottomNavigationBar: NafasBottomNavBar(
        selectedIndex: _selectedIndex,
        items: _tabs,
        onDestinationSelected: (int index) =>
            setState(() => _selectedIndex = index),
      ),
    );
  }
}

class _PrayersTabContent extends StatelessWidget {
  final Widget? topWidget;
  final VoidCallback onOpenQibla;

  const _PrayersTabContent({this.topWidget, required this.onOpenQibla});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (topWidget case final widget?) ...[
          const SizedBox(height: 2),
          widget,
        ],
        Card(
          elevation: 0,
          color: colors.tertiaryContainer.withValues(alpha: 0.30),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: const [
                _PrayerTimeRow(name: 'Fajr', time: '05:01 AM'),
                _PrayerTimeRow(name: 'Sunrise', time: '06:12 AM'),
                _PrayerTimeRow(name: 'Dhuhr', time: '12:14 PM'),
                _PrayerTimeRow(name: 'Asr', time: '03:43 PM'),
                _PrayerTimeRow(name: 'Maghrib', time: '06:20 PM'),
                _PrayerTimeRow(name: 'Isha', time: '07:31 PM'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenQibla,
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Find Qibla'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const NearbyMosquesScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.location_city_rounded),
                label: const Text('Mosques near me'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrayerTimeRow extends StatelessWidget {
  final String name;
  final String time;

  const _PrayerTimeRow({required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPage extends StatelessWidget {
  final List<_EntryData> entries;
  final Widget? topWidget;
  final ValueChanged<_EntryData>? onEntryTap;

  const _SectionPage({required this.entries, this.topWidget, this.onEntryTap});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (topWidget case final widget?) ...[
          const SizedBox(height: 2),
          widget,
        ],
        ...entries.map((entry) {
          final iconBackground = colors.surface;
          final iconColor = colors.primaryFixed;

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            color: colors.tertiaryContainer.withValues(alpha: 0.30),
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
              onTap: () => onEntryTap?.call(entry),
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
  final _EntryAction? action;

  const _EntryData(this.title, this.subtitle, this.icon, {this.action});
}

enum _EntryAction { openHijriCalendar, openQibla }
