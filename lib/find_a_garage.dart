import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum GarageFilter { all, nearby, topRated, open24 }

class Garage {
  final String id;
  final String name;
  final String locationLabel;
  final LatLng location;
  final double rating;
  final bool open24;
  final String imageUrl;

  const Garage({
    required this.id,
    required this.name,
    required this.locationLabel,
    required this.location,
    required this.rating,
    required this.open24,
    required this.imageUrl,
  });
}

class NearbyGaragesScreen extends StatefulWidget {
  const NearbyGaragesScreen({super.key});

  @override
  State<NearbyGaragesScreen> createState() => _NearbyGaragesScreenState();
}

class _NearbyGaragesScreenState extends State<NearbyGaragesScreen> {
  final _searchController = TextEditingController();
  final MapController _mapController = MapController();

  final LatLng _fallbackLocation = const LatLng(6.9271, 79.8612);
  LatLng? _currentLatLng;

  bool _loadingLocation = true;
  String? _locationError;

  GarageFilter _filter = GarageFilter.all;

  static const double _nearbyKm = 5;
  static const double _topRatedThreshold = 4.5;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'Location services are disabled.';
          _loadingLocation = false;
        });
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _locationError = 'Location permission denied.';
          _loadingLocation = false;
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'Location permission permanently denied. Enable it in Settings.';
          _loadingLocation = false;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final next = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _currentLatLng = next;
        _loadingLocation = false;
      });

      // Center the map once location is known.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(next, 13.0);
      });
    } catch (e) {
      setState(() {
        _locationError = 'Failed to get location: $e';
        _loadingLocation = false;
      });
    }
  }

  List<Garage> _garagesNear(LatLng center) {
    return [
      Garage(
        id: 'g1',
        name: 'City Auto Care',
        locationLabel: 'Nearby',
        location: LatLng(center.latitude + 0.004, center.longitude + 0.002),
        rating: 4.8,
        open24: true,
        imageUrl: 'https://via.placeholder.com/150',
      ),
      Garage(
        id: 'g2',
        name: 'Lanka Hybrid Motors',
        locationLabel: 'Nearby',
        location: LatLng(center.latitude - 0.006, center.longitude + 0.001),
        rating: 4.5,
        open24: false,
        imageUrl: 'https://via.placeholder.com/150',
      ),
      Garage(
        id: 'g3',
        name: 'Express Service Hub',
        locationLabel: 'Nearby',
        location: LatLng(center.latitude + 0.010, center.longitude - 0.008),
        rating: 4.2,
        open24: true,
        imageUrl: 'https://via.placeholder.com/150',
      ),
      Garage(
        id: 'g4',
        name: 'Smart Wheels Garage',
        locationLabel: 'Nearby',
        location: LatLng(center.latitude - 0.012, center.longitude - 0.010),
        rating: 4.7,
        open24: false,
        imageUrl: 'https://via.placeholder.com/150',
      ),
    ];
  }

  double _distanceKm(LatLng from, LatLng to) {
    final meters = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
    return meters / 1000;
  }

  List<Garage> _applyFilters(List<Garage> garages) {
    final q = _searchController.text.trim().toLowerCase();
    Iterable<Garage> filtered = garages;

    if (q.isNotEmpty) {
      filtered = filtered.where(
        (g) =>
            g.name.toLowerCase().contains(q) ||
            g.locationLabel.toLowerCase().contains(q),
      );
    }

    if (_currentLatLng != null) {
      switch (_filter) {
        case GarageFilter.all:
          break;
        case GarageFilter.nearby:
          filtered = filtered.where((g) {
            final d = _distanceKm(_currentLatLng!, g.location);
            return d <= _nearbyKm;
          });
          break;
        case GarageFilter.topRated:
          filtered = filtered.where((g) => g.rating >= _topRatedThreshold);
          break;
        case GarageFilter.open24:
          filtered = filtered.where((g) => g.open24);
          break;
      }
    }

    return filtered.toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _currentLatLng != null;
    final center = _currentLatLng ?? _fallbackLocation;
    final garages = hasLocation ? _garagesNear(center) : const <Garage>[];
    final visibleGarages = _applyFilters(garages);

    final markers = <Marker>[
      if (hasLocation)
        Marker(
          point: _currentLatLng!,
          width: 80,
          height: 80,
          child:
              const Icon(Icons.my_location, color: Colors.blue, size: 28),
        ),
      for (final garage in visibleGarages)
        Marker(
          point: garage.location,
          width: 80,
          height: 80,
          child:
              const Icon(Icons.location_on, color: Colors.red, size: 40),
        ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Find a Garage",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
        actions: [
          IconButton(
            onPressed: _initLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Refresh location',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by location or name...",
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.green),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                _buildFilterChip(
                  'All',
                  selected: _filter == GarageFilter.all,
                  onTap: () => _setFilter(GarageFilter.all),
                ),
                _buildFilterChip(
                  'Nearby',
                  selected: _filter == GarageFilter.nearby,
                  onTap: () => _setFilter(GarageFilter.nearby),
                ),
                _buildFilterChip(
                  'Top Rated',
                  selected: _filter == GarageFilter.topRated,
                  onTap: () => _setFilter(GarageFilter.topRated),
                ),
                _buildFilterChip(
                  '24 Hours',
                  selected: _filter == GarageFilter.open24,
                  onTap: () => _setFilter(GarageFilter.open24),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // සිතියම පෙන්වන කොටස (Map View)
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                // withOpacity වෙනුවට withValues භාවිතා කර ඇත
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _loadingLocation
                    ? const Center(child: CircularProgressIndicator())
                    : _locationError != null
                        ? Container(
                            color: Colors.white10,
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.center,
                            child: Text(
                              _locationError!,
                              style: const TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: center,
                              initialZoom: 13.0,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.example.app',
                              ),
                              MarkerLayer(markers: markers),
                            ],
                          ),
              ),
            ),
          ),

          // පහළ ඇති ගරාජ් ලැයිස්තුව (Garage List)
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.black,
              ),
              child: _loadingLocation
                  ? const Center(child: CircularProgressIndicator())
                  : !hasLocation
                      ? const Center(
                          child: Text(
                            'Enable location to find nearby garages on the map.',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : ListView.builder(
                          itemCount: visibleGarages.length,
                          itemBuilder: (context, index) {
                            final garage = visibleGarages[index];
                            final d =
                                _distanceKm(_currentLatLng!, garage.location);
                            return _buildGarageCard(garage, distanceKm: d);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  void _setFilter(GarageFilter next) {
    setState(() {
      _filter = next;
    });
  }

  Widget _buildFilterChip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Colors.green,
        backgroundColor: Colors.white10,
        label: Text(
          label,
          style: TextStyle(color: selected ? Colors.black : Colors.white),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildGarageCard(Garage garage, {required double distanceKm}) {
    final distanceText = '${distanceKm.toStringAsFixed(1)} km';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              garage.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 70,
                  height: 70,
                  color: Colors.white10,
                  alignment: Alignment.center,
                  child: const Icon(Icons.garage, color: Colors.green),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garage.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  garage.locationLabel,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.green, size: 14),
                    Text(
                      ' $distanceText',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.star, color: Colors.yellow, size: 14),
                    Text(
                      ' ${garage.rating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (garage.open24) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.access_time,
                          color: Colors.green, size: 14),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: Colors.green, size: 16),
        ],
      ),
    );
  }
}