import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong2.dart';

class NearbyGaragesScreen extends StatefulWidget {
  const NearbyGaragesScreen({super.key});

  @override
  State<NearbyGaragesScreen> createState() => _NearbyGaragesScreenState();
}

class _NearbyGaragesScreenState extends State<NearbyGaragesScreen> {

  final LatLng _initialLocation = const LatLng(6.9271, 79.8612);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Find a Garage",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextField(
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
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _initialLocation,
                    initialZoom: 13.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    // Marker (ගරාජ් පිහිටීම)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _initialLocation,
                          width: 80,
                          height: 80,
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                      ],
                    ),
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
              child: ListView(
                children: [
                  _buildGarageItem("City Auto Care", "0.5 km", 4.8),
                  _buildGarageItem("Lanka Hybrid Motors", "0.7 km", 4.5),
                  _buildGarageItem("Express Service Hub", "1.2 km", 4.2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarageItem(String name, String distance, double rating) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // මෙහිද withValues භාවිතා විය
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("$distance | ⭐ $rating", style: const TextStyle(color: Colors.white54)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.green, size: 15),
        onTap: () {},
      ),
    );
  }
}