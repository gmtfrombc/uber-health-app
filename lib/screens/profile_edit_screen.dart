// lib/screens/profile_edit_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'home_screen.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for text input.
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();

  // Lists to store entries.
  List<String> _medications = [];
  List<String> _allergies = [];
  List<String> _conditions = [];

  // Fetched user data.
  UserModel? _user;
  bool _isLoading = true;

  Future<void> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) return;
    try {
      UserModel user = await FirebaseService().getUserMedicalInfo(uid);
      debugPrint(
        "Fetched user data: medications: ${user.medications}, allergies: ${user.allergies}, conditions: ${user.conditions}",
      );
      setState(() {
        _user = user;
        _medications = user.medications ?? [];
        _allergies = user.allergies ?? [];
        _conditions = user.conditions ?? [];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    UserModel updatedUser = UserModel(
      uid: uid,
      role: _user?.role ?? "patient",
      // Use the new fields: firstname and lastname.
      firstname: _user?.firstname ?? "",
      lastname: _user?.lastname ?? "",
      email: _user?.email ?? "",
      dob: _user?.dob,
      gender: _user?.gender,
      ethnicity: _user?.ethnicity,
      specialty: _user?.specialty,
      bio: _user?.bio,
      medications: _medications,
      allergies: _allergies,
      conditions: _conditions,
      createdAt: _user?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await FirebaseService().updateUserMedicalInfo(updatedUser);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile updated successfully.")),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _medicationsController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  // Build the Medications section as a Card with an ExpansionTile.
  Widget _buildMedicationsCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: const Text("Medications"),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _medicationsController,
                        decoration: const InputDecoration(
                          labelText: 'Add Medication',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 1,
                        onFieldSubmitted: (_) {
                          if (_medicationsController.text.trim().isNotEmpty) {
                            setState(() {
                              _medications.add(
                                _medicationsController.text.trim(),
                              );
                              _medicationsController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_medicationsController.text.trim().isNotEmpty) {
                          setState(() {
                            _medications.add(
                              _medicationsController.text.trim(),
                            );
                            _medicationsController.clear();
                          });
                        }
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children:
                      _medications
                          .map(
                            (med) => Chip(
                              label: Text(med),
                              onDeleted: () {
                                setState(() {
                                  _medications.remove(med);
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the Drug Allergies section as a Card with an ExpansionTile.
  Widget _buildAllergiesCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: const Text("Drug Allergies"),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _allergiesController,
                        decoration: const InputDecoration(
                          labelText: 'Add Allergy',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 1,
                        onFieldSubmitted: (_) {
                          if (_allergiesController.text.trim().isNotEmpty) {
                            setState(() {
                              _allergies.add(_allergiesController.text.trim());
                              _allergiesController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_allergiesController.text.trim().isNotEmpty) {
                          setState(() {
                            _allergies.add(_allergiesController.text.trim());
                            _allergiesController.clear();
                          });
                        }
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children:
                      _allergies
                          .map(
                            (allergy) => Chip(
                              label: Text(allergy),
                              onDeleted: () {
                                setState(() {
                                  _allergies.remove(allergy);
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the Active Conditions section as a Card with an ExpansionTile.
  Widget _buildConditionsCard() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ExpansionTile(
        title: const Text("Active Conditions"),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _conditionsController,
                        decoration: const InputDecoration(
                          labelText: 'Add Condition',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 1,
                        onFieldSubmitted: (_) {
                          if (_conditionsController.text.trim().isNotEmpty) {
                            setState(() {
                              _conditions.add(
                                _conditionsController.text.trim(),
                              );
                              _conditionsController.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_conditionsController.text.trim().isNotEmpty) {
                          setState(() {
                            _conditions.add(_conditionsController.text.trim());
                            _conditionsController.clear();
                          });
                        }
                      },
                      child: const Text("Add"),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children:
                      _conditions
                          .map(
                            (cond) => Chip(
                              label: Text(cond),
                              onDeleted: () {
                                setState(() {
                                  _conditions.remove(cond);
                                });
                              },
                            ),
                          )
                          .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: "Save Profile",
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildListDelegate([
                        _buildMedicationsCard(),
                        _buildAllergiesCard(),
                        _buildConditionsCard(),
                        const SizedBox(height: 16),
                      ]),
                    ),
                  ],
                ),
              ),
    );
  }
}
