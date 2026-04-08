import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dashboard_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _vPrefixController = TextEditingController();
  final _vNumberController = TextEditingController();

  final _vehicleModelController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  String _capitalize(String value) {
    if (value.isEmpty) return "";
    return value[0].toUpperCase() + value.substring(1);
  }

  Future<void> _registerUser() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final vPrefix = _vPrefixController.text.trim();
    final vNumber = _vNumberController.text.trim();

    bool isEmailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);

    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty || vPrefix.isEmpty || vNumber.isEmpty) {
      _showSnackBar("Please fill all required fields", Colors.orange);
      return;
    }

    if (!isEmailValid) {
      _showSnackBar("Please enter a valid email", Colors.redAccent);
      return;
    }

    if (phone.length != 10 || !phone.startsWith('0')) {
      _showSnackBar("Phone number must be 10 digits starting with '0'", Colors.redAccent);
      return;
    }

    if (vPrefix.length < 2 || vPrefix.length > 3) {
      _showSnackBar("Vehicle letters must be 2 or 3", Colors.redAccent);
      return;
    }
    if (vNumber.length != 4) {
      _showSnackBar("Vehicle number must be exactly 4 digits", Colors.redAccent);
      return;
    }

    if (password.length < 6) {
      _showSnackBar("Password must be at least 6 characters", Colors.redAccent);
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // QR දත්ත ලෙස භාවිතා කිරීමට User UID එක ලබා ගැනීම
      String userId = userCredential.user!.uid;
      String baseName = email.split('@')[0];
      String uniqueUsername = "${baseName}_${userId.substring(0, 4)}";

      // Firestore වෙත දත්ත ඇතුළත් කිරීම
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': email,
        'phone': phone,
        'vehicleNumber': "$vPrefix $vNumber",
        'vehicleModel': _vehicleModelController.text.trim(),
        'username': uniqueUsername,
        'monthly_spend': 0.0, // Dashboard එකේ පෙන්වීමට මුල් අගය 0 ලෙස
        'qrData': userId,     // QR එක සඳහා Unique දත්තය
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const DashboardScreen()), (route) => false);
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Create Account", style: TextStyle(color: Colors.green, fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildField(_firstNameController, "First Name", Icons.person, onChanged: (val) {
                    _firstNameController.value = _firstNameController.value.copyWith(
                      text: _capitalize(val),
                      selection: TextSelection.collapsed(offset: _capitalize(val).length),
                    );
                  }),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildField(_lastNameController, "Last Name", Icons.person, onChanged: (val) {
                    _lastNameController.value = _lastNameController.value.copyWith(
                      text: _capitalize(val),
                      selection: TextSelection.collapsed(offset: _capitalize(val).length),
                    );
                  }),
                ),
              ],
            ),

            _buildField(_emailController, "Email Address", Icons.email, keyboardType: TextInputType.emailAddress),
            _buildField(_phoneController, "Phone Number", Icons.phone, keyboardType: TextInputType.phone, maxLength: 10),

            const Padding(
              padding: EdgeInsets.only(bottom: 8.0, left: 5),
              child: Text("Vehicle Number (Letters 2-3, Numbers 4)", style: TextStyle(color: Colors.green, fontSize: 13)),
            ),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildField(_vPrefixController, "Letters", Icons.abc,
                      textCapitalization: TextCapitalization.characters, maxLength: 3),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: _buildField(_vNumberController, "Digits", Icons.numbers,
                      keyboardType: TextInputType.number, maxLength: 4),
                ),
              ],
            ),

            _buildField(_vehicleModelController, "Vehicle Model", Icons.car_repair),
            _buildField(_passwordController, "Password (Min 6 chars)", Icons.lock, isPassword: true),

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.yellow, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text("REGISTER", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint, IconData icon, {
    bool isPassword = false,
    TextInputType? keyboardType,
    int? maxLength,
    Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        maxLength: maxLength,
        onChanged: onChanged,
        textCapitalization: textCapitalization,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          counterText: "",
          prefixIcon: Icon(icon, color: Colors.green),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
          enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.green), borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white), borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}