import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/mosque_repository.dart';

class NearbyMosquesScreen extends StatefulWidget {
  const NearbyMosquesScreen({super.key});

  @override
  State<NearbyMosquesScreen> createState() => _NearbyMosquesScreenState();
}

class _NearbyMosquesScreenState extends State<NearbyMosquesScreen> {
  LatLng? _userPoint;
  List<MosqueDistance> _nearby = const [];
  String _status = 'Loading nearby mosques...';

  @override
  void initState() {
    super.initState();
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() => _status = 'Enable location to find nearby mosques');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _status = 'Location permission is required');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final userPoint = LatLng(pos.latitude, pos.longitude);
      final nearby = await MosqueRepository.nearby(
        userLat: pos.latitude,
        userLng: pos.longitude,
        maxKm: 40,
      );

      if (!mounted) return;
      setState(() {
        _userPoint = userPoint;
        _nearby = nearby;
        _status = nearby.isEmpty
            ? 'No mosques found in 40 km from your location'
            : '${nearby.length} mosques found nearby';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _status = 'Unable to load nearby mosques right now');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mosques near me')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            color: colors.tertiaryContainer.withValues(alpha: 0.35),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadNearby,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: _userPoint == null
                ? const Center(child: CircularProgressIndicator())
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: _userPoint!,
                      initialZoom: 12.2,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.nafas',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _userPoint!,
                            width: 38,
                            height: 38,
                            child: const Icon(
                              Icons.my_location_rounded,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),
                          ..._nearby.map(
                            (item) => Marker(
                              point: LatLng(
                                item.mosque.latitude,
                                item.mosque.longitude,
                              ),
                              width: 44,
                              height: 44,
                              child: Tooltip(
                                message:
                                    '${item.mosque.name}\n${item.distanceKm.toStringAsFixed(1)} km',
                                child: const Icon(
                                  Icons.mosque_rounded,
                                  color: Colors.teal,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          if (_nearby.isNotEmpty)
            SizedBox(
              height: 160,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                itemCount: _nearby.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _nearby[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    child: ListTile(
                      leading: const Icon(Icons.mosque_rounded),
                      title: Text(item.mosque.name),
                      subtitle: Text(
                        '${item.distanceKm.toStringAsFixed(1)} km away',
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
