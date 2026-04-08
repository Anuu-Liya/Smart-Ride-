import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FuelCalculator {
  // ලංකාවේ වත්මන් පෙට්‍රල් මිල (මෙය අවශ්‍ය පරිදි වෙනස් කළ හැක)
  static const double currentPetrolPrice = 370.0;

  // 1. ඉන්ධන වියදම ගණනය කර Firebase වෙත ගබඩා කිරීමේ Function එක
  Future<void> addFuelRecord({
    required double liters,
    required BuildContext context,
  }) async {
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;

      // මුළු මුදල ගණනය කිරීම
      double totalCost = liters * currentPetrolPrice;

      // Firestore හි 'FuelRecords' collection එකට දත්ත ඇතුළත් කිරීම
      await FirebaseFirestore.instance.collection('FuelRecords').add({
        'uid': uid,
        'liters': liters,
        'unitPrice': currentPetrolPrice,
        'totalCost': totalCost,
        'timestamp': FieldValue.serverTimestamp(), // ඇතුළත් කළ වෙලාව
        'month': DateTime.now().month, // මාසික වියදම් ගණනය කිරීමට
        'year': DateTime.now().year,
      });

      // සාර්ථක පණිවිඩයක් පෙන්වීම
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Fuel record added! Total Cost: LKR ${totalCost.toStringAsFixed(2)}"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // දෝෂයක් ආවොත් පෙන්වීම
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // 2. මාසික මුළු වියදම ලබා ගැනීමේ Function එක (Dashboard එක සඳහා)
  Stream<double> getMonthlyTotalFuelCost() {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    int currentMonth = DateTime.now().month;
    int currentYear = DateTime.now().year;

    return FirebaseFirestore.instance
        .collection('FuelRecords')
        .where('uid', isEqualTo: uid)
        .where('month', isEqualTo: currentMonth)
        .where('year', isEqualTo: currentYear)
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        total += doc['totalCost'];
      }
      return total;
    });
  }
}

// 3. UI එකේ පාවිච්චි කරන ආකාරය (Example Widget)
class FuelInputWidget extends StatelessWidget {
  final TextEditingController _literController = TextEditingController();
  final FuelCalculator _calculator = FuelCalculator();

  FuelInputWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _literController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Enter Liters",
            prefixIcon: Icon(Icons.local_gas_station),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            double liters = double.tryParse(_literController.text) ?? 0.0;
            if (liters > 0) {
              _calculator.addFuelRecord(liters: liters, context: context);
              _literController.clear();
            }
          },
          child: const Text("Submit Fuel Record"),
        ),
      ],
    );
  }
}
