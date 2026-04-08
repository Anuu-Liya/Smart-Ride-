import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GarageLocationScreen extends StatefulWidget {
  const GarageLocationScreen({super.key});

  @override
  State<GarageLocationScreen> createState() => _GarageLocationScreenState();
}

class _GarageLocationScreenState extends State<GarageLocationScreen> {
  late GoogleMapController mapController;

  // ಉದಾಹರಣೆಗೆ ಹತ್ತಿರದ ಗ್ಯಾರೇಜ್‌ಗಳ ಡೇಟಾ (ನಿಜವಾದ ಆಪ್‌ನಲ್ಲಿ ಇದು API ಮೂಲಕ ಬರಬೇಕು)
  final List<Map<String, dynamic>> garages = [
    {
      "name": "Yasuki Garage",
      "address": "Kurunegala, Sri Lanka",
      "rating": 5.0,
      "review": "Excellent service and friendly staff!",
      "lat": 7.4692, "lng": 80.5179
    },
    {
      "name": "Garage Nishantha",
      "address": "Ridigama",
      "rating": 4.5,
      "review": "Very quick repair, highly recommended.",
      "lat": 7.4741, "lng": 80.5161
    },
  ];

  final LatLng _initialPosition = const LatLng(7.4692, 80.5179);
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    setState(() {
      _markers = garages.map((garage) {
        return Marker(
          markerId: MarkerId(garage['name']),
          position: LatLng(garage['lat'], garage['lng']),
          infoWindow: InfoWindow(title: garage['name'], snippet: garage['address']),
        );
      }).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Nearby Garages", style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.green),
      ),
      body: Column(
        children: [
          // 1. ಮ್ಯಾಪ್ ಪ್ರದರ್ಶನ
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
                markers: _markers,
                onMapCreated: (controller) => mapController = controller,
              ),
            ),
          ),

          // 2. ಗ್ಯಾರೇಜ್ ವಿಮರ್ಶೆಗಳ ಲಿಸ್ಟ್
          Expanded(
            flex: 2,
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: garages.length,
              itemBuilder: (context, index) {
                final garage = garages[index];
                return _buildGarageCard(garage);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarageCard(Map<String, dynamic> garage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(garage['name'], style: const TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  Text(" ${garage['rating']}", style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(garage['address'], style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const Divider(color: Colors.white10),
          const Text("Recent Review:", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
          Text("\"${garage['review']}\"", style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontSize: 13)),
        ],
      ),
    );
  }
}