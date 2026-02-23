import 'dart:math' as math;
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/mosque.dart';

class MosqueRepository {
  static final Uri _overpassUri = Uri.parse(
    'https://overpass-api.de/api/interpreter',
  );
  static const double _maxOverpassQueryKm = 12;

  static Future<List<MosqueDistance>> nearby({
    required double userLat,
    required double userLng,
    double maxKm = 25,
  }) async {
    final queryKm = math.min(maxKm, _maxOverpassQueryKm);
    final meters = (queryKm * 1000).round();
    final query =
        '''
[out:json][timeout:20];
(
  node["amenity"="place_of_worship"]["religion"~"^(muslim|islam)\$",i](around:$meters,$userLat,$userLng);
  way["amenity"="place_of_worship"]["religion"~"^(muslim|islam)\$",i](around:$meters,$userLat,$userLng);
  relation["amenity"="place_of_worship"]["religion"~"^(muslim|islam)\$",i](around:$meters,$userLat,$userLng);

  node["building"="mosque"](around:$meters,$userLat,$userLng);
  way["building"="mosque"](around:$meters,$userLat,$userLng);
  relation["building"="mosque"](around:$meters,$userLat,$userLng);

  node["amenity"="place_of_worship"]["name"~"mosque|masjid|jumma|jami",i](around:$meters,$userLat,$userLng);
  way["amenity"="place_of_worship"]["name"~"mosque|masjid|jumma|jami",i](around:$meters,$userLat,$userLng);
  relation["amenity"="place_of_worship"]["name"~"mosque|masjid|jumma|jami",i](around:$meters,$userLat,$userLng);
);
out center;
''';

    final response = await http.post(
      _overpassUri,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'data': query},
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Overpass request failed (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List<dynamic>? ?? const []);
    final unique = <String>{};

    final mosques = <Mosque>[];
    for (final raw in elements) {
      final element = raw as Map<String, dynamic>;
      final tags = (element['tags'] as Map<String, dynamic>? ?? const {});
      final name = (tags['name'] as String?)?.trim();
      final lat =
          (element['lat'] as num?)?.toDouble() ??
          ((element['center'] as Map<String, dynamic>?)?['lat'] as num?)
              ?.toDouble();
      final lon =
          (element['lon'] as num?)?.toDouble() ??
          ((element['center'] as Map<String, dynamic>?)?['lon'] as num?)
              ?.toDouble();

      if (lat == null || lon == null) continue;

      final resolvedName =
          (name == null || name.isEmpty) ? 'Nearby Mosque' : name;
      final key =
          '${lat.toStringAsFixed(6)}:${lon.toStringAsFixed(6)}:$resolvedName';
      if (unique.contains(key)) continue;
      unique.add(key);

      mosques.add(
        Mosque(name: resolvedName, latitude: lat, longitude: lon),
      );
    }

    return _toSortedDistances(
      source: mosques,
      userLat: userLat,
      userLng: userLng,
      maxKm: maxKm,
    );
  }

  static List<MosqueDistance> _toSortedDistances({
    required List<Mosque> source,
    required double userLat,
    required double userLng,
    required double maxKm,
  }) {
    final results = source
        .map((mosque) {
          final km = _distanceKm(
            lat1: userLat,
            lon1: userLng,
            lat2: mosque.latitude,
            lon2: mosque.longitude,
          );
          return MosqueDistance(mosque: mosque, distanceKm: km);
        })
        .where((item) => item.distanceKm <= maxKm)
        .toList(growable: true);

    results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return results;
  }

  static double _distanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const r = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  static double _toRad(double deg) => deg * math.pi / 180;
}

class MosqueDistance {
  final Mosque mosque;
  final double distanceKm;

  const MosqueDistance({required this.mosque, required this.distanceKm});
}
