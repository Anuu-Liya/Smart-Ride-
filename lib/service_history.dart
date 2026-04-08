import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  final _serviceCenterController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _costController = TextEditingController();
  final _descriptionController = TextEditingController();

  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // සේවා වාර්තාවක් සුරැකීමේ Function එක
  Future<void> _saveServiceRecord() async {
    if (_serviceCenterController.text.isEmpty || _costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill main fields")),
      );
      return;
    }

    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('services')
          .add({
        'serviceCenter': _serviceCenterController.text.trim(),
        'serviceType': _serviceTypeController.text.trim(),
        'cost': _costController.text.trim(),
        'description': _descriptionController.text.trim(),
        'date': todayDate, // Dynamic date
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      _clearControllers();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  void _clearControllers() {
    _serviceCenterController.clear();
    _serviceTypeController.clear();
    _costController.clear();
    _descriptionController.clear();
  }

  // සේවා වාර්තාවක් ඇතුළත් කරන Form එක (Bottom Sheet)
  void _showAddServiceForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20, left: 20, right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Service Record", style: TextStyle(color: Colors.green, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildTextField(_serviceCenterController, "Service Center / Garage Name", Icons.store),
              _buildTextField(_serviceTypeController, "What was the service? (e.g. Oil Change)", Icons.settings),
              _buildTextField(_costController, "Total Cost (LKR)", Icons.money, isNumber: true),
              _buildTextField(_descriptionController, "Additional Notes", Icons.description),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveServiceRecord,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow),
                  child: const Text("ADD RECORD", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Service History", style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('services')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No records found.", style: TextStyle(color: Colors.white54)));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(15),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(15)),
                child: Row(
                  children: [
                    const Icon(Icons.build_circle, color: Colors.yellow, size: 40),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(doc['serviceType'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("${doc['serviceCenter']} • ${doc['date']}", style: const TextStyle(color: Colors.white60, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text("${doc['cost']} LKR", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddServiceForm,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text("ADD SERVICE RECORD", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.green),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.green), borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}