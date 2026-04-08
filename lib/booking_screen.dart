import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key}); 

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  final _contactController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedGarage;

  late Future<DocumentSnapshot> _userDataFuture;

  @override
  void initState() {
    super.initState();
    
    _userDataFuture = FirebaseFirestore.instance.collection('users').doc(uid).get();
  }

  Future<void> _confirmBooking(Map<String, dynamic> userData) async {
    if (_selectedGarage == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all details")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': uid,
        'userName': userData['firstName'] ?? "User",
        'vehicleInfo': "${userData['vehicleModel']} - ${userData['vehicleNumber']}",
        'garageName': _selectedGarage,
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'time': _selectedTime!.format(context),
        'contact': _contactController.text,
        'notes': _notesController.text,
        'status': 'Confirmed',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return; // Fix for async gaps

      _showSuccessDialog();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text("Booking Confirmed Successfully!",
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pop(context); // Back to Dashboard
          }, child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Book a Service", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.green),
            onPressed: () => Navigator.pop(context)
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _userDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          // Fix for "Error loading user data"
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_off, color: Colors.red, size: 60),
                    const SizedBox(height: 15),
                    const Text("User Data Not Found",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text("Please update your profile details first.",
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.white54)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Go Back", style: TextStyle(color: Colors.black)),
                    )
                  ],
                ),
              ),
            );
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          if (_contactController.text.isEmpty) {
            _contactController.text = userData['phone'] ?? "";
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("1. Choose a Nearby Garage", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildGarageSelector(),

                const SizedBox(height: 25),
                const Text("2. Vehicle Details (Auto-filled)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildDisabledField("${userData['vehicleModel'] ?? 'N/A'} - ${userData['vehicleNumber'] ?? '---'}", Icons.directions_car),

                const SizedBox(height: 25),
                const Text("3. Appointment Schedule", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildDatePicker(),
                const SizedBox(height: 10),
                _buildTimePicker(),

                const SizedBox(height: 25),
                const Text("4. Contact Information", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildTextField(_contactController, "Phone Number", Icons.phone),

                const SizedBox(height: 25),
                const Text("5. Special Notes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildTextField(_notesController, "e.g., Brake check, Oil change", Icons.edit, maxLines: 3),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () => _confirmBooking(userData),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    child: const Text("CONFIRM BOOKING",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGarageSelector() {
    List<Map<String, String>> garages = [
      {"name": "Auto Miraj - Near You", "dist": "1.2 km"},
      {"name": "Hybrid Hub", "dist": "2.5 km"},
      {"name": "Toyota Care", "dist": "4.0 km"},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: garages.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedGarage == garages[index]['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedGarage = garages[index]['name']),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 15),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                // Use withValues to fix precision loss warning
                color: isSelected ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isSelected ? Colors.green : Colors.transparent),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 20),
                  const Spacer(),
                  Text(garages[index]['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(garages[index]['dist']!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    return ListTile(
      onTap: () async {
        DateTime? picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime.now(),
            lastDate: DateTime(2027)
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      tileColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.calendar_today, color: Colors.green),
      title: Text(_selectedDate == null ? "Select Date" : DateFormat('yyyy-MM-dd').format(_selectedDate!),
          style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_drop_down, color: Colors.white54),
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      onTap: () async {
        TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
        if (picked != null) setState(() => _selectedTime = picked);
      },
      tileColor: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.access_time, color: Colors.green),
      title: Text(_selectedTime == null ? "Select Time" : _selectedTime!.format(context),
          style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_drop_down, color: Colors.white54),
    );
  }

  Widget _buildDisabledField(String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12)
      ),
      child: Row(children: [Icon(icon, color: Colors.green), const SizedBox(width: 15), Text(val, style: const TextStyle(color: Colors.white70))]),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.green),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
