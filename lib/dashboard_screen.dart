import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import Screens
import 'booking_screen.dart';
import 'review_screen.dart';
import 'add_fuel_screen.dart';
import 'add_vehicle.dart';
import 'add_service.dart';
import 'service_history.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'maintenance_tips_screen.dart';
import 'find_a_garage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? user = FirebaseAuth.instance.currentUser;

  // Logout Options Menu
  void _showLogoutOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAccountOption(
                icon: Icons.exit_to_app,
                title: "Logout",
                color: Colors.redAccent,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
              _buildAccountOption(
                icon: Icons.switch_account,
                title: "Login Another Account",
                color: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  _showAnotherLoginForm(context);
                },
              ),
              _buildAccountOption(
                icon: Icons.person_add_alt,
                title: "Add Account",
                color: Colors.white,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const SignUpScreen()));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAnotherLoginForm(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Login Another Account",
            style: TextStyle(color: Colors.green, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Email",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Password",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signInWithEmailAndPassword(
                  email: emailController.text.trim(),
                  password: passwordController.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}")));
              }
            },
            child: const Text("Login"),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountOption(
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title,
          style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          String vehicleName = userData['vehicleModel'] ?? "Toyota Vitz";
          String plateNo = userData['vehicleNumber'] ?? "NW CAD 8855";
          String vehicleType = userData['vehicleType'] ?? "Petrol";
          double monthlyCost = (userData['monthly_spend'] ?? 0.0).toDouble();

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Smart Ride Dashboard",
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_pin,
                              color: Colors.green, size: 28),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ProfileScreen())),
                        ),
                        const SizedBox(width: 5),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.yellow),
                          onPressed: () => _showLogoutOptions(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text("Hello, ${userData['firstName'] ?? 'User'}!",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),

                const SizedBox(height: 20),

                // Vehicle Info Card
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_car,
                          size: 40, color: Colors.yellow),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(vehicleName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(plateNo,
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 14)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- අලුත් Daily Maintenance Tip Card එක ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "Daily Maintenance Tip",
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        vehicleType == "Petrol"
                            ? "Regularly check your spark plugs for better fuel efficiency."
                            : "Monitor your battery health and charging ports frequently.",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15, height: 1.4),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Monthly Fuel Cost
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              color: Colors.pink, size: 20),
                          SizedBox(width: 10),
                          Text("Monthly Fuel Cost",
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      Text("${monthlyCost.toStringAsFixed(0)} LKR",
                          style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Text("Quick Actions",
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),

                _buildActionItem(
                    "Book a Service",
                    Icons.calendar_today,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BookingFuelScreen()))),
                _buildActionItem(
                    "Add Vehicle",
                    Icons.directions_car,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddVehiclePage()))),
                _buildActionItem(
                    "Add Service",
                    Icons.engineering,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddServicePage()))),
                _buildActionItem(
                    "Review Bookings",
                    Icons.calendar_today,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const ReviewScreen(
                                garageId: 'default_garage')))),
                _buildActionItem(
                    "Add Fuel Record",
                    Icons.add_circle_outline,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const AddFuelScreen()))),
                _buildActionItem(
                    "Service History",
                    Icons.history,
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ServiceHistoryScreen()))),

                _buildActionItem("Maintenance Tips", Icons.lightbulb_outline,
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MaintenanceTipsScreen(vehicleType: vehicleType),
                      ));
                }),

                _buildActionItem("Find Nearby Mechanic", Icons.map_outlined,
                    () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NearbyGaragesScreen()));
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionItem(String title, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: Colors.green),
          title: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          trailing: const Icon(Icons.arrow_forward_ios,
              color: Colors.white24, size: 15),
        ),
      ),
    );
  }
}
