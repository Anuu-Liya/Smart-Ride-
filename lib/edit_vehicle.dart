import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditVehiclePage extends StatefulWidget {
  final String id;
  final String name;
  final String number;

  const EditVehiclePage({
    super.key,
    required this.id,
    required this.name,
    required this.number,
  });

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  late TextEditingController nameController;
  late TextEditingController numberController;

  @override
  void initState() {
    nameController = TextEditingController(text: widget.name);
    numberController = TextEditingController(text: widget.number);
    super.initState();
  }

  void updateVehicle() async {
    await FirebaseFirestore.instance
        .collection('vehicles')
        .doc(widget.id)
        .update({
      'name': nameController.text,
      'number': numberController.text,
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Vehicle")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController),
            TextField(controller: numberController),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: updateVehicle,
              child: const Text("Update"),
            )
          ],
        ),
      ),
    );
  }
}
