import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationCacheService extends ChangeNotifier {
  LocationCacheService._();

  static final LocationCacheService instance = LocationCacheService._();
  static const String _cachedLocationKey = 'cached_location_name';

  String _locationText = 'Locating...';
  bool _needsLocationEnable = false;
  bool _isFetching = false;
  bool _hasFetchedThisSession = false;
  bool _isHydrated = false;
  Future<void>? _inFlight;

  String get locationText => _locationText;
  bool get needsLocationEnable => _needsLocationEnable;
  bool get isFetching => _isFetching;

  Future<void> warmUp() async {
    await _hydrateFromCache();
    await fetchIfNeeded();
  }

  Future<void> fetchIfNeeded() async {
    await _fetch(forceRefresh: false);
  }

  Future<void> refreshByUser() async {
    await _fetch(forceRefresh: true);
  }

  Future<void> _hydrateFromCache() async {
    if (_isHydrated) return;

    final prefs = await SharedPreferences.getInstance();
    final cachedLocation = prefs.getString(_cachedLocationKey);

    if (cachedLocation != null && cachedLocation.trim().isNotEmpty) {
      final normalizedCached = _normalizeCachedLocation(cachedLocation);
      _locationText = normalizedCached;
      if (normalizedCached != cachedLocation) {
        await prefs.setString(_cachedLocationKey, normalizedCached);
      }
      notifyListeners();
    }

    _isHydrated = true;
  }

  Future<void> _fetch({required bool forceRefresh}) async {
    await _hydrateFromCache();

    if (!forceRefresh && _hasFetchedThisSession) {
      return;
    }

    if (_inFlight != null) {
      await _inFlight;
      return;
    }

    _inFlight = _performFetch(forceRefresh: forceRefresh);
    try {
      await _inFlight;
    } finally {
      _inFlight = null;
    }
  }

  Future<void> _performFetch({required bool forceRefresh}) async {
    _isFetching = true;
    notifyListeners();

    try {
      final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!locationServiceEnabled) {
        _isFetching = false;
        _needsLocationEnable = true;
        if (_locationText == 'Locating...') {
          _locationText = 'Enable location to fetch location';
        }
        notifyListeners();
        return;
      }

      final permission = await Geolocator.checkPermission();
      var grantedPermission = permission;

      if (permission == LocationPermission.denied) {
        grantedPermission = await Geolocator.requestPermission();
      }

      if (grantedPermission == LocationPermission.denied ||
          grantedPermission == LocationPermission.deniedForever) {
        _isFetching = false;
        _needsLocationEnable = true;
        if (_locationText == 'Locating...') {
          _locationText = 'Enable location to fetch location';
        }
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );

      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (places.isEmpty) {
        _locationText =
            '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
      } else {
        _locationText = _formatCityCountryLocation(places.first);
      }

      _isFetching = false;
      _needsLocationEnable = false;
      _hasFetchedThisSession = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedLocationKey, _locationText);
    } catch (_) {
      _isFetching = false;
      _needsLocationEnable = true;
      if (_locationText == 'Locating...') {
        _locationText = 'Enable location to fetch location';
      }
      notifyListeners();
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
}
