// lib/screens/home_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'request_screen.dart';
import 'profile_edit_screen.dart';
import '../widgets/app_drawer.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<UserModel?> _fetchUser() async {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) return null;
    final user = await FirebaseService().getUserMedicalInfo(uid);
    return user;
  }

  // Helper method to format a list of items with bullets.
  String _formatListWithBullets(List<String>? items) {
    if (items == null || items.isEmpty) return "None";
    return items.map((item) => "• $item").join("\n");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Uber Health'),
        backgroundColor: Colors.teal,
      ),
      endDrawer: const AppDrawer(),
      body: FutureBuilder<UserModel?>(
        future: _fetchUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("No user data available."));
          }

          final user = snapshot.data!;
          // Extract first name from user.firstname (if available) or fallback.
          final firstName =
              user.firstname.trim().isNotEmpty ? user.firstname.trim() : '';
          final greeting =
              firstName.isEmpty ? "Welcome!" : "Welcome, $firstName!";

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header image.
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.asset(
                  'assets/images/welcome.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
              ),
              const SizedBox(height: 16),
              // Greeting text, centered horizontally.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Health Information Card with edit icon.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row with title and edit icon.
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Your Health Information",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[600],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileEditScreen(),
                                    ),
                                  );
                                },
                                tooltip: "Edit Profile",
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildInfoSection("Medications:", user.medications),
                          const SizedBox(height: 16),
                          _buildInfoSection("Drug Allergies:", user.allergies),
                          const SizedBox(height: 16),
                          _buildInfoSection(
                            "Active Conditions:",
                            user.conditions,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom button.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      backgroundColor: Colors.teal,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Request a Consult',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper method to build an info section.
  Widget _buildInfoSection(String title, List<String>? items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _formatListWithBullets(items),
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
