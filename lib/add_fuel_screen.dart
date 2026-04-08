import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AddFuelScreen extends StatefulWidget {
  const AddFuelScreen({super.key});

  @override
  State<AddFuelScreen> createState() => _AddFuelScreenState();
}

class _AddFuelScreenState extends State<AddFuelScreen> {
  final _amountController = TextEditingController();
  final _litersController = TextEditingController();
  final double fuelPricePerLiter = 370.00;
  String _priceNote = "Enter liters to calculate price";
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _litersController.addListener(_calculatePrice);
  }

  void _calculatePrice() {
    setState(() {
      if (_litersController.text.isNotEmpty) {
        double? liters = double.tryParse(_litersController.text);
        if (liters != null) {
          double total = liters * fuelPricePerLiter;
          _amountController.text = total.toStringAsFixed(2);
          _priceNote = "Total: LKR ${total.toStringAsFixed(2)}";
        }
      } else {
        _amountController.clear();
        _priceNote = "Enter liters to calculate price";
      }
    });
  }

  Future<void> _saveFuelRecord() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _amountController.text.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      double amountToAdd = double.parse(_amountController.text);
      DateTime now = DateTime.now();
      String currentMonth = "${now.year}-${now.month}";

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // Firestore Transaction එකක් භාවිතා කිරීම
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userDocRef);

        if (!snapshot.exists) {
          // Document එක නැතිනම් අලුතින් නිර්මාණය කිරීම
          transaction.set(userDocRef, {
            'monthly_spend': amountToAdd,
            'last_update_month': currentMonth,
          });
        } else {
          Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
          // පවතින මාසය පරීක්ෂා කිරීම (Field එක නැතිනම් හිස් අගයක් ගනී)
          String lastUpdateMonth = data.containsKey('last_update_month') ? data['last_update_month'] : "";

          if (lastUpdateMonth != currentMonth) {
            // මාසය වෙනස් වී ඇත්නම්: පැරණි අගය Rs. 0 කර අලුත් මුදල ඇතුළත් කිරීම (Reset)
            transaction.update(userDocRef, {
              'monthly_spend': amountToAdd,
              'last_update_month': currentMonth,
            });
          } else {
            // එකම මාසය නම්: දැනට ඇති අගයට අලුත් මුදල එකතු කිරීම
            transaction.update(userDocRef, {
              'monthly_spend': FieldValue.increment(amountToAdd),
              'last_update_month': currentMonth,
            });
          }
        }
      });

      // ඉන්ධන ඉතිහාසය (Fuel History) වෙනම සුරැකීම
      await FirebaseFirestore.instance.collection('fuel_records').add({
        'userId': user.uid,
        'liters': double.parse(_litersController.text),
        'amount': amountToAdd,
        'date': FieldValue.serverTimestamp(),
        'month': currentMonth,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fuel record saved successfully!"), backgroundColor: Colors.green),
      );
      Navigator.pop(context);

    } catch (e) {
      debugPrint("Detailed Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Add Fuel", style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // QR Code එක පෙන්වන කොටස
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: QrImageView(
                  data: user?.uid ?? "No User",
                  version: QrVersions.auto,
                  size: 160.0,
                ),
              ),
            ),
            const SizedBox(height: 35),

            _buildTextField("Liters", _litersController, Icons.local_gas_station, false),
            const SizedBox(height: 15),

            Text(_priceNote, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 25),

            _buildTextField("Total Price (LKR)", _amountController, Icons.payments, true),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveFuelRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  side: const BorderSide(color: Colors.green, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.green)
                    : const Text("SAVE TO HISTORY",
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, bool readOnly) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.green),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.green),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}