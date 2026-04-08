import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddServicePage extends StatefulWidget {
  final String vehicleId;

  const AddServicePage({super.key, required this.vehicleId});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final typeController = TextEditingController();
  final dateController = TextEditingController();
  final costController = TextEditingController();

  void saveService() async {
    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(widget.vehicleId)
        .collection('services')
        .add({
      'type': typeController.text,
      'date': dateController.text,
      'cost': costController.text,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Service")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: typeController,
              decoration: const InputDecoration(labelText: "Service Type"),
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: "Date"),
            ),
            TextField(
              controller: costController,
              decoration: const InputDecoration(labelText: "Cost"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveService,
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
