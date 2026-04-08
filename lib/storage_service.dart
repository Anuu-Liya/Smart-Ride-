import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadDamageImage() async {
    final picker = ImagePicker();


    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      File file = File(image.path);

      try {
        String fileName = 'damage_${DateTime.now().millisecondsSinceEpoch}.jpg';
        Reference ref = _storage.ref().child('damages/$fileName');


        await ref.putFile(file);


        String downloadURL = await ref.getDownloadURL();
        return downloadURL;

      } catch (e) {
        print("Error uploading: $e");
        return null;
      }
    }
    return null;
  }
}