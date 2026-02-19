import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeHijriLocationCard extends StatefulWidget {
  const HomeHijriLocationCard({super.key});

  @override
  State<HomeHijriLocationCard> createState() => _HomeHijriLocationCardState();
}

class _HomeHijriLocationCardState extends State<HomeHijriLocationCard> {
  static const String _cachedLocationKey = 'cached_location_name';

  String _locationText = 'Locating...';
  bool _needsLocationEnable = false;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    _restoreAndLoadLocation();
  }

  Future<void> _restoreAndLoadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedLocation = prefs.getString(_cachedLocationKey);

    if (!mounted) return;

    if (cachedLocation != null && cachedLocation.trim().isNotEmpty) {
      setState(() => _locationText = cachedLocation);
    }

    await _loadLocation();
  }

  Future<void> _loadLocation() async {
    if (mounted) {
      setState(() => _isFetchingLocation = true);
    }

    try {
      final locationServiceEnabled =
          await Geolocator.isLocationServiceEnabled();
      if (!locationServiceEnabled) {
        if (!mounted) return;
        setState(() {
          _isFetchingLocation = false;
          _needsLocationEnable = true;
          if (_locationText == 'Locating...') {
            _locationText = 'Enable location to fetch location';
          }
        });
        return;
      }

      final permission = await Geolocator.checkPermission();
      LocationPermission grantedPermission = permission;

      if (permission == LocationPermission.denied) {
        grantedPermission = await Geolocator.requestPermission();
      }

      if (grantedPermission == LocationPermission.denied ||
          grantedPermission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _isFetchingLocation = false;
          _needsLocationEnable = true;
          if (_locationText == 'Locating...') {
            _locationText = 'Enable location to fetch location';
          }
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      if (places.isEmpty) {
        setState(() {
          _needsLocationEnable = false;
          _locationText =
              '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedLocationKey, _locationText);
        return;
      }

      final place = places.first;
      final locality = place.locality?.trim();
      final subAdministrativeArea = place.subAdministrativeArea?.trim();
      final administrativeArea = place.administrativeArea?.trim();
      final country = place.country?.trim();
      final location = [
        if (locality != null && locality.isNotEmpty) locality,
        if (subAdministrativeArea != null && subAdministrativeArea.isNotEmpty)
          subAdministrativeArea,
        if (administrativeArea != null && administrativeArea.isNotEmpty)
          administrativeArea,
        if (country != null && country.isNotEmpty) country,
      ].join(', ');

      final resolvedLocation = location.isEmpty ? 'Current Location' : location;

      setState(() {
        _isFetchingLocation = false;
        _needsLocationEnable = false;
        _locationText = resolvedLocation;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedLocationKey, resolvedLocation);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFetchingLocation = false;
        _needsLocationEnable = true;
        if (_locationText == 'Locating...') {
          _locationText = 'Enable location to fetch location';
        }
      });
    }
  }

  Future<void> _onLocationPressed() async {
    await _loadLocation();

    if (!_needsLocationEnable) {
      return;
    }

    if (_needsLocationEnable) {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final today = DateTime.now();
    HijriCalendar.setLocal('en');
    final hijri = HijriCalendar.now();

    final englishDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(today);
    final hijriDayMonth = hijri.toFormat('dd MMMM');
    final hijriYear = '${hijri.hYear} AH';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
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
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  hijriYear,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  englishDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.8),
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
                color: colors.primary.withValues(alpha: 0.24),
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
                          color: colors.onPrimaryContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _isFetchingLocation
                                ? 'Fetching location...'
                                : _locationText,
                            maxLines: 2,
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
