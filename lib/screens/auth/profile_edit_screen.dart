// lib/screens/auth/profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../../providers/user_provider.dart';

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

  // Original data for checking if changes were made
  List<String> _originalMedications = [];
  List<String> _originalAllergies = [];
  List<String> _originalConditions = [];

  // Fetched user data.
  UserModel? _user;
  bool _isLoading = true;

  // Check if user has made changes
  bool get _hasChanges {
    if (_medications.length != _originalMedications.length ||
        _allergies.length != _originalAllergies.length ||
        _conditions.length != _originalConditions.length) {
      return true;
    }

    for (int i = 0; i < _medications.length; i++) {
      if (i >= _originalMedications.length ||
          _medications[i] != _originalMedications[i]) {
        return true;
      }
    }

    for (int i = 0; i < _allergies.length; i++) {
      if (i >= _originalAllergies.length ||
          _allergies[i] != _originalAllergies[i]) {
        return true;
      }
    }

    for (int i = 0; i < _conditions.length; i++) {
      if (i >= _originalConditions.length ||
          _conditions[i] != _originalConditions[i]) {
        return true;
      }
    }

    return false;
  }

  Future<void> _fetchUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // Try to use data from provider first if available
      if (userProvider.userProfile != null) {
        final user = userProvider.userProfile!;
        setState(() {
          _user = user;
          _medications = user.medications ?? [];
          _allergies = user.allergies ?? [];
          _conditions = user.conditions ?? [];

          // Store original values for comparison
          _originalMedications = List.from(user.medications ?? []);
          _originalAllergies = List.from(user.allergies ?? []);
          _originalConditions = List.from(user.conditions ?? []);

          _isLoading = false;
        });
        return;
      }

      // Otherwise fetch from Firebase
      final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
      if (uid.isEmpty) return;

      UserModel user = await FirebaseService().getUserMedicalInfo(uid);
      debugPrint(
        "Fetched user data: medications: ${user.medications}, allergies: ${user.allergies}, conditions: ${user.conditions}",
      );
      setState(() {
        _user = user;
        _medications = user.medications ?? [];
        _allergies = user.allergies ?? [];
        _conditions = user.conditions ?? [];

        // Store original values for comparison
        _originalMedications = List.from(user.medications ?? []);
        _originalAllergies = List.from(user.allergies ?? []);
        _originalConditions = List.from(user.conditions ?? []);

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
    // Store current context to avoid async gap issues
    final BuildContext currentContext = context;

    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(
      currentContext,
      listen: false,
    );
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    if (_user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text("Error: User data not available.")),
      );
      return;
    }

    UserModel updatedUser = UserModel(
      uid: uid,
      role: _user?.role ?? "patient",
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

    try {
      // Update through the UserProvider instead of directly with FirebaseService
      await userProvider.updateUserProfile(updatedUser);

      // Update original values after saving
      if (mounted) {
        setState(() {
          _originalMedications = List.from(_medications);
          _originalAllergies = List.from(_allergies);
          _originalConditions = List.from(_conditions);
        });
      }

      // Pop back to previous screen instead of creating a new instance
      if (mounted) {
        Navigator.pop(currentContext);

        // Show success message
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully.")),
        );
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          currentContext,
        ).showSnackBar(SnackBar(content: Text("Error updating profile: $e")));
      }
    }
  }

  // Function to handle back button / navigation
  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      // Store the context before the async operation
      final BuildContext currentContext = context;

      // Only proceed if still mounted
      if (!mounted) return true;

      final result = await showDialog<bool>(
        context: currentContext,
        builder:
            (dialogContext) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                'You have unsaved changes. Do you want to save them before leaving?',
              ),
              actions: [
                TextButton(
                  onPressed:
                      () => Navigator.of(
                        dialogContext,
                      ).pop(false), // Don't save and leave
                  child: const Text('Discard'),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(
                        dialogContext,
                      ).pop(true), // Save and leave
                  child: const Text('Save'),
                ),
              ],
            ),
      );

      // Check if we're still mounted after the dialog
      if (!mounted) return true;

      if (result == true) {
        // User wants to save before leaving
        await _saveProfile();
      }

      return true; // Allow navigation
    }

    return true; // No unsaved changes, allow navigation
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
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Edit Profile"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: Stack(
                    children: [
                      CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate([
                              _buildMedicationsCard(),
                              _buildAllergiesCard(),
                              _buildConditionsCard(),
                              const SizedBox(height: 100), // Space for the FAB
                            ]),
                          ),
                        ],
                      ),
                      // Positioned save button at the bottom
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'SAVE CHANGES',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
