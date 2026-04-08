import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DamageReportScreen extends StatefulWidget {
  @override
  _DamageReportScreenState createState() => _DamageReportScreenState();
}

class _DamageReportScreenState extends State<DamageReportScreen> {
  File? _image;
  final picker = ImagePicker();
  final TextEditingController _descController = TextEditingController();

  Future pickImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future uploadData() async {
    if (_image == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Select an image first")));
      return;
    }

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();

    Reference ref = FirebaseStorage.instance
        .ref()
        .child("damage_images")
        .child(fileName);

    await ref.putFile(_image!);
    String imageUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection("damage_reports").add({
      "description": _descController.text,
      "image": imageUrl,
      "date": DateTime.now(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Report Uploaded")));

    setState(() {
      _image = null;
      _descController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("Report Vehicle Damage",
            style: TextStyle(color: Colors.greenAccent)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _image != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_image!, height: 180),
            )
                : Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text("No Image Selected",
                    style: TextStyle(color: Colors.white54)),
              ),
            ),

            SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow),
                  onPressed: () => pickImage(ImageSource.camera),
                  child: Text("Camera", style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => pickImage(ImageSource.gallery),
                  child: Text("Gallery"),
                ),
              ],
            ),

            SizedBox(height: 20),

            TextField(
              controller: _descController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Describe Damage",
                labelStyle: TextStyle(color: Colors.green),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green),
                ),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: uploadData,
              child: Text("UPLOAD REPORT"),
            )
          ],
        ),
      ),
    );
  }
}