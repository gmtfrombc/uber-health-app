// lib/screens/auth/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';
import '../patient/home_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  OnboardingScreenState createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
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

  // Define step colors for better visual distinction
  late List<Color> _stepColors;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    // Initialize step colors using theme
    _stepColors = [
      theme.colorScheme.primary, // Welcome
      Colors.blue, // Medications
      Colors.orange, // Allergies
      Colors.green, // Conditions
      theme.colorScheme.primary, // Review
    ];
  }

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
        title: Text('Welcome', style: TextStyle(color: _stepColors[0])),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _stepColors[0].withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Welcome to XUBER Health!\n\nWe'll gather some basic medical information to personalize your care. You can update or correct this information later.",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.editing,
      ),
      // Step 1: Prescription Medications.
      Step(
        title: Text('Medications', style: TextStyle(color: _stepColors[1])),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _stepColors[1].withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Please list any prescription medications you are currently taking.",
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  activeColor: _stepColors[1],
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
                const Text('I don\'t take any medications'),
              ],
            ),
            if (!_medicationsNone)
              TextFormField(
                controller: _medicationsController,
                decoration: InputDecoration(
                  labelText: 'Enter a medication',
                  hintText: 'e.g., Lisinopril',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _stepColors[1], width: 2),
                  ),
                ),
                maxLines: null,
              ),
            const SizedBox(height: 8),
            if (!_medicationsNone)
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Medication'),
                onPressed: () {
                  if (_medicationsController.text.trim().isNotEmpty) {
                    setState(() {
                      _medications.add(_medicationsController.text.trim());
                      _medicationsController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _stepColors[1],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _medications
                      .map(
                        (med) => Chip(
                          label: Text(med),
                          deleteIconColor: _stepColors[1],
                          backgroundColor: _stepColors[1].withAlpha(40),
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
        title: Text('Drug Allergies', style: TextStyle(color: _stepColors[2])),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _stepColors[2].withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Please list any drug allergies you have.",
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  activeColor: _stepColors[2],
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
                const Text('I don\'t have any drug allergies'),
              ],
            ),
            if (!_allergiesNone)
              TextFormField(
                controller: _allergiesController,
                decoration: InputDecoration(
                  labelText: 'Enter a drug allergy',
                  hintText: 'e.g., Penicillin',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _stepColors[2], width: 2),
                  ),
                ),
                maxLines: null,
              ),
            const SizedBox(height: 8),
            if (!_allergiesNone)
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Allergy'),
                onPressed: () {
                  if (_allergiesController.text.trim().isNotEmpty) {
                    setState(() {
                      _allergies.add(_allergiesController.text.trim());
                      _allergiesController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _stepColors[2],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _allergies
                      .map(
                        (allergy) => Chip(
                          label: Text(allergy),
                          deleteIconColor: _stepColors[2],
                          backgroundColor: _stepColors[2].withAlpha(40),
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
        title: Text(
          'Active Conditions',
          style: TextStyle(color: _stepColors[3]),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _stepColors[3].withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Please list any active medical conditions you have.",
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  activeColor: _stepColors[3],
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
                const Text('I don\'t have any active conditions'),
              ],
            ),
            if (!_conditionsNone)
              TextFormField(
                controller: _conditionsController,
                decoration: InputDecoration(
                  labelText: 'Enter an active condition',
                  hintText: 'e.g., Hypertension',
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: _stepColors[3], width: 2),
                  ),
                ),
                maxLines: null,
              ),
            const SizedBox(height: 8),
            if (!_conditionsNone)
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Condition'),
                onPressed: () {
                  if (_conditionsController.text.trim().isNotEmpty) {
                    setState(() {
                      _conditions.add(_conditionsController.text.trim());
                      _conditionsController.clear();
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _stepColors[3],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _conditions
                      .map(
                        (condition) => Chip(
                          label: Text(condition),
                          deleteIconColor: _stepColors[3],
                          backgroundColor: _stepColors[3].withAlpha(40),
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
        title: Text(
          'Review Your Information',
          style: TextStyle(color: _stepColors[4]),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _stepColors[4].withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _stepColors[4].withAlpha(100)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Please review your information. If changes are needed, tap on a step above to edit it.",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Medications:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _stepColors[1],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _medications.isEmpty
                        ? "None"
                        : "• ${_medications.join('\n• ')}",
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Drug Allergies:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _stepColors[2],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _allergies.isEmpty
                        ? "None"
                        : "• ${_allergies.join('\n• ')}",
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Active Conditions:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _stepColors[3],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _conditions.isEmpty
                        ? "None"
                        : "• ${_conditions.join('\n• ')}",
                  ),
                ],
              ),
            ),
          ],
        ),
        isActive: _currentStep >= 4,
        state: _currentStep == 4 ? StepState.editing : StepState.complete,
      ),
    ];
  }

  Future<void> _onStepContinue() async {
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

      // Save user data and ensure context is available before using it
      try {
        setState(() {
          _isLoading = true; // Show loading indicator
        });

        await FirebaseService().updateUserMedicalInfo(updatedUser);

        // Check if widget is still mounted before using context
        if (!mounted) return;

        // Explicitly fetch and update the UserProvider before navigating
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.fetchUserProfile();

        // Check again if still mounted before navigation
        if (!mounted) return;

        // Wait for the next frame before navigating
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );

          // Show snackbar after navigation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Onboarding complete!"),
              backgroundColor: Colors.green,
            ),
          );
        });
      } catch (e) {
        // Handle errors and check if mounted
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving data: $e"),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isLoading = false;
        });
      }
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
  void dispose() {
    _medicationsController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use _isLoading to show a loader during Firebase interactions.
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Health Information"),
          centerTitle: true,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.teal),
              SizedBox(height: 16),
              Text("Loading your profile..."),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Health Information"),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: _stepColors[_currentStep]),
        ),
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () => _onStepContinue(),
          onStepCancel: _onStepCancel,
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            final isLastStep = _currentStep == _buildSteps().length - 1;

            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: details.onStepContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _stepColors[_currentStep],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        isLastStep ? 'Complete' : 'Continue',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: _stepColors[_currentStep]),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                ],
              ),
            );
          },
          steps: _buildSteps(),
        ),
      ),
    );
  }
}
