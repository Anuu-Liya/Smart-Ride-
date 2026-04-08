import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final nameController = TextEditingController();
  final numberController = TextEditingController();

  void saveVehicle() async {
    await FirebaseFirestore.instance.collection('vehicles').add({
      'name': nameController.text,
      'number': numberController.text,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Vehicle Name"),
            ),
            TextField(
              controller: numberController,
              decoration: const InputDecoration(labelText: "Vehicle Number"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveVehicle,
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }
}
