import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'storage_service.dart'; // Import storage service

class EmergencyScreen extends StatelessWidget {
  final StorageService _storageService = StorageService();

  EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency"), backgroundColor: Colors.black),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("Emergency SOS", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // SOS Button
            InkWell(
              onTap: () => launchUrl(Uri.parse('tel:119')),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(child: Text("SOS", style: TextStyle(fontSize: 40, color: Colors.red, fontWeight: FontWeight.bold))),
              ),
            ),

            const SizedBox(height: 40),

            // Camera Button to upload damage
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 50)),
              onPressed: () async {
                String? url = await _storageService.uploadDamageImage();
                if (url != null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Damage Photo Uploaded!")));
                }
              },
              icon: const Icon(Icons.camera_alt),
              label: const Text("Capture & Upload Damage"),
            ),
          ],
        ),
      ),
    );
  }
}