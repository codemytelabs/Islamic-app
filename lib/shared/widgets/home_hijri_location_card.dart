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
      final normalizedCached = _normalizeCachedLocation(cachedLocation);
      setState(() => _locationText = normalizedCached);

      if (normalizedCached != cachedLocation) {
        await prefs.setString(_cachedLocationKey, normalizedCached);
      }
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
          _isFetchingLocation = false;
          _needsLocationEnable = false;
          _locationText =
              '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
        });
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedLocationKey, _locationText);
        return;
      }

      final place = places.first;
      final resolvedLocation = _formatCityCountryLocation(place);

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

  String _formatCityCountryLocation(Placemark place) {
    final cityCandidates = [
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ];

    String? city;
    for (final candidate in cityCandidates) {
      final parsed = _extractCityFromRaw(candidate);
      if (parsed != null) {
        city = parsed;
        break;
      }
    }

    final country = _extractCountryFromRaw(
      place.country,
      fallbackRawValues: cityCandidates,
    );

    if (city != null && country != null) {
      if (city.toLowerCase() == country.toLowerCase()) {
        return city;
      }
      return '$city, $country';
    }

    if (city != null) return city;
    if (country != null) return country;

    return 'Current Location';
  }

  String _normalizeCachedLocation(String rawLocation) {
    return _cityCountryFromRaw(rawLocation);
  }

  String _cityCountryFromRaw(String rawLocation) {
    final parts = rawLocation
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (parts.isEmpty) {
      return 'Current Location';
    }

    if (parts.length == 1) {
      return parts.first;
    }

    final city = parts.first;
    final country = parts.last;

    if (city.toLowerCase() == country.toLowerCase()) {
      return city;
    }

    return '$city, $country';
  }

  String? _extractCityFromRaw(String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) {
      return null;
    }

    final segments = rawValue
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    if (segments.isEmpty) {
      return null;
    }

    for (final segment in segments) {
      if (!_looksAdministrative(segment)) {
        return segment;
      }
    }

    return segments.first;
  }

  String? _extractCountryFromRaw(
    String? rawCountry, {
    required List<String?> fallbackRawValues,
  }) {
    if (rawCountry != null && rawCountry.trim().isNotEmpty) {
      final segments = rawCountry
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
      if (segments.isNotEmpty) {
        return segments.last;
      }
    }

    for (final rawValue in fallbackRawValues) {
      if (rawValue == null || rawValue.trim().isEmpty) {
        continue;
      }
      final segments = rawValue
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(growable: false);
      if (segments.length > 1) {
        return segments.last;
      }
    }

    return null;
  }

  bool _looksAdministrative(String text) {
    final value = text.toLowerCase();
    return value.contains('province') ||
        value.contains('district') ||
        value.contains('state') ||
        value.contains('region');
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
                            _isFetchingLocation
                                ? 'Fetching location...'
                                : _locationText,
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
