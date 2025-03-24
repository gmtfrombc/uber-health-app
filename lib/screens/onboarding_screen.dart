// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;

  // Controllers for text inputs.
  final TextEditingController _medicationsController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _conditionsController = TextEditingController();

  // Lists to store multiple entries.
  final List<String> _medications = [];
  final List<String> _allergies = [];
  final List<String> _conditions = [];

  // Flags for 'None' options.
  bool _medicationsNone = false;
  bool _allergiesNone = false;
  bool _conditionsNone = false;

  // Store the existing user profile from sign-up.
  UserModel? _user;
  bool _isLoading = true;

  Future<void> _fetchUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? "";
    if (uid.isEmpty) return;
    try {
      UserModel user = await FirebaseService().getUserMedicalInfo(uid);
      debugPrint("Fetched user data: ${user.toMap()}");
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Step> _buildSteps() {
    return [
      // Step 0: Welcome Screen.
      Step(
        title: const Text('Welcome'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Welcome to Uber Health!\n\nWe'll gather some basic medical information to personalize your care. You can update or correct this information later.",
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.editing,
      ),
      // Step 1: Prescription Medications.
      Step(
        title: const Text('Medications'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _medicationsNone,
                  onChanged: (value) {
                    setState(() {
                      _medicationsNone = value ?? false;
                      if (_medicationsNone) {
                        _medications.clear();
                      }
                    });
                  },
                ),
                const Text('None'),
              ],
            ),
            if (!_medicationsNone)
              TextFormField(
                controller: _medicationsController,
                decoration: const InputDecoration(
                  labelText: 'Enter a medication',
                  hintText: 'e.g., Lisinopril',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
            const SizedBox(height: 8),
            if (!_medicationsNone)
              ElevatedButton(
                onPressed: () {
                  if (_medicationsController.text.trim().isNotEmpty) {
                    setState(() {
                      _medications.add(_medicationsController.text.trim());
                      _medicationsController.clear();
                    });
                  }
                },
                child: const Text('Add Medication'),
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
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.editing,
      ),
      // Step 2: Drug Allergies.
      Step(
        title: const Text('Drug Allergies'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _allergiesNone,
                  onChanged: (value) {
                    setState(() {
                      _allergiesNone = value ?? false;
                      if (_allergiesNone) {
                        _allergies.clear();
                      }
                    });
                  },
                ),
                const Text('None'),
              ],
            ),
            if (!_allergiesNone)
              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(
                  labelText: 'Enter a drug allergy',
                  hintText: 'e.g., Penicillin',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
            const SizedBox(height: 8),
            if (!_allergiesNone)
              ElevatedButton(
                onPressed: () {
                  if (_allergiesController.text.trim().isNotEmpty) {
                    setState(() {
                      _allergies.add(_allergiesController.text.trim());
                      _allergiesController.clear();
                    });
                  }
                },
                child: const Text('Add Allergy'),
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
        isActive: _currentStep >= 2,
        state: _currentStep > 2 ? StepState.complete : StepState.editing,
      ),
      // Step 3: Active Medical Conditions.
      Step(
        title: const Text('Active Conditions'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: _conditionsNone,
                  onChanged: (value) {
                    setState(() {
                      _conditionsNone = value ?? false;
                      if (_conditionsNone) {
                        _conditions.clear();
                      }
                    });
                  },
                ),
                const Text('None'),
              ],
            ),
            if (!_conditionsNone)
              TextFormField(
                controller: _conditionsController,
                decoration: const InputDecoration(
                  labelText: 'Enter an active condition',
                  hintText: 'e.g., Hypertension',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
              ),
            const SizedBox(height: 8),
            if (!_conditionsNone)
              ElevatedButton(
                onPressed: () {
                  if (_conditionsController.text.trim().isNotEmpty) {
                    setState(() {
                      _conditions.add(_conditionsController.text.trim());
                      _conditionsController.clear();
                    });
                  }
                },
                child: const Text('Add Condition'),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children:
                  _conditions
                      .map(
                        (condition) => Chip(
                          label: Text(condition),
                          onDeleted: () {
                            setState(() {
                              _conditions.remove(condition);
                            });
                          },
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
        isActive: _currentStep >= 3,
        state: _currentStep > 3 ? StepState.complete : StepState.editing,
      ),
      // Step 4: Summary and Review.
      Step(
        title: const Text('Review Your Information'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Please review your information. If changes are needed, tap on a step above to edit it.",
            ),
            const SizedBox(height: 10),
            const Text(
              "Medications:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_medications.isEmpty ? "None" : _medications.join(', ')),
            const SizedBox(height: 10),
            const Text(
              "Drug Allergies:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_allergies.isEmpty ? "None" : _allergies.join(', ')),
            const SizedBox(height: 10),
            const Text(
              "Active Conditions:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_conditions.isEmpty ? "None" : _conditions.join(', ')),
          ],
        ),
        isActive: _currentStep >= 4,
        state: _currentStep == 4 ? StepState.editing : StepState.complete,
      ),
    ];
  }

  void _onStepContinue() async {
    if (_currentStep < _buildSteps().length - 1) {
      setState(() {
        _currentStep += 1;
      });
    } else {
      // On final step, update the user data in Firebase and navigate to HomeScreen.
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      // Build updated user using existing sign-up data for non-health fields.
      final updatedUser = UserModel(
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
      await FirebaseService().updateUserMedicalInfo(updatedUser);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Onboarding complete!")));
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    // Use _isLoading to show a loader during Firebase interactions.
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Onboarding")),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text("Onboarding")),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (BuildContext context, ControlsDetails details) {
          return Row(
            children: <Widget>[
              ElevatedButton(
                onPressed: details.onStepContinue,
                child: const Text('Continue'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: details.onStepCancel,
                child: const Text('Go Back'),
              ),
            ],
          );
        },
        steps: _buildSteps(),
      ),
    );
  }
}
