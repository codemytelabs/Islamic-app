import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';

import '../services/location_cache_service.dart';

class HomeHijriLocationCard extends StatefulWidget {
  const HomeHijriLocationCard({super.key});

  @override
  State<HomeHijriLocationCard> createState() => _HomeHijriLocationCardState();
}

class _HomeHijriLocationCardState extends State<HomeHijriLocationCard> {
  final LocationCacheService _locationService = LocationCacheService.instance;

  @override
  void initState() {
    super.initState();
    _locationService.addListener(_onLocationStateChanged);
    _locationService.warmUp();
  }

  void _onLocationStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onLocationPressed() async {
    await _locationService.refreshByUser();
    if (!mounted) return;

    if (!_locationService.needsLocationEnable) {
      return;
    }

    if (_locationService.needsLocationEnable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Enable location from settings to fetch location',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () async {
              final serviceEnabled =
                  await Geolocator.isLocationServiceEnabled();
              if (!serviceEnabled) {
                await Geolocator.openLocationSettings();
              } else {
                await Geolocator.openAppSettings();
              }
            },
          ),
        ),
      );
      return;
    }
  }

  @override
  void dispose() {
    _locationService.removeListener(_onLocationStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    HijriCalendar.setLocal('en');
    final hijri = HijriCalendar.now();
    final hijriDayMonth = hijri.toFormat('dd MMMM');
    final hijriYear = '${hijri.hYear} AH';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [colors.onPrimaryContainer, colors.primary],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hijriDayMonth,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  hijriYear,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Material(
                color: colors.primaryContainer.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _onLocationPressed,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: colors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _locationService.isFetching
                                ? 'Fetching location...'
                              : _locationService.locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
