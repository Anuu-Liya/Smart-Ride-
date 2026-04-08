import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ServiceLogic {
  Future<void> addServiceRecord(int currentMileage, double cost, String garage) async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    int nextServiceMileage = currentMileage + 5000; // Next service calculation

    await FirebaseFirestore.instance.collection('ServiceHistory').add({
      'uid': uid,
      'date': DateTime.now(),
      'mileage': currentMileage,
      'nextService': nextServiceMileage,
      'cost': cost,
      'garage': garage,
    });

    // Update main user record for dashboard display
    await FirebaseFirestore.instance.collection('Users').doc(uid).update({
      'lastServiceMileage': currentMileage,
      'nextServiceMileage': nextServiceMileage,
    });
  }
}