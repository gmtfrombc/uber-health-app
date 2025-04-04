// lib/screens/auth/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import 'onboarding_screen.dart';
import '../provider/provider_dashboard_screen.dart';
import '../../theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Provider-specific fields
  final TextEditingController _credentialsController = TextEditingController();

  // Patient-specific fields
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ethnicityController = TextEditingController();

  // Role selection - default to patient for now
  String _selectedRole = 'patient';
  String? _selectedCredentials;

  bool _isLoading = false;
  String? _errorMessage;

  // Toggle to control if provider sign-up is enabled
  final bool _providerSignupEnabled =
      false; // Set to false to disable provider signup

  // List of available credentials
  final List<String> _credentials = ['MD', 'DO', 'NP', 'PA'];

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      if (credential.user != null) {
        // Create user model based on role
        UserModel newUser;

        // Only check role if provider signup is enabled
        if (_providerSignupEnabled && _selectedRole == 'provider') {
          newUser = UserModel(
            uid: credential.user!.uid,
            role: 'provider',
            firstname: _firstNameController.text.trim(),
            lastname: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            credentials: _selectedCredentials,
            createdAt: DateTime.now(),
          );
        } else {
          newUser = UserModel(
            uid: credential.user!.uid,
            role: 'patient',
            firstname: _firstNameController.text.trim(),
            lastname: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            dob: _dobController.text.trim(),
            gender: _genderController.text.trim(),
            ethnicity: _ethnicityController.text.trim(),
            createdAt: DateTime.now(),
          );
        }

        // Save the user profile using the UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.saveUser(newUser);

        // Navigate based on role
        if (_providerSignupEnabled && _selectedRole == 'provider') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ProviderDashboardScreen(),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred during sign up.";
      });
    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role section with patient option and disabled provider option
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Type',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Patient option - selectable
                  InkWell(
                    onTap: () {
                      setState(() {
                        _selectedRole = 'patient';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              _selectedRole == 'patient'
                                  ? AppTheme.primaryColor
                                  : Colors.grey.shade300,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Radio<String>(
                            value: 'patient',
                            groupValue: _selectedRole,
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value!;
                              });
                            },
                            activeColor: AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Patient')),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Provider option - disabled with coming soon message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: Row(
                      children: [
                        Radio<String>(
                          value: 'provider',
                          groupValue:
                              _providerSignupEnabled ? _selectedRole : null,
                          onChanged:
                              _providerSignupEnabled
                                  ? (value) {
                                    setState(() {
                                      _selectedRole = value!;
                                    });
                                  }
                                  : null, // Disabled if provider signup is not enabled
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Healthcare Provider',
                                style: TextStyle(color: Colors.grey),
                              ),
                              if (!_providerSignupEnabled)
                                Text(
                                  'Coming soon',
                                  style: TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Common fields
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),

            // Role-specific fields
            if (_providerSignupEnabled && _selectedRole == 'provider') ...[
              // Provider fields only shown when provider is selected AND provider signup is enabled
              DropdownButtonFormField<String>(
                value: _selectedCredentials,
                decoration: const InputDecoration(
                  labelText: 'Credentials',
                  border: OutlineInputBorder(),
                ),
                items:
                    _credentials.map((String credential) {
                      return DropdownMenuItem<String>(
                        value: credential,
                        child: Text(credential),
                      );
                    }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _selectedCredentials = value;
                  });
                },
              ),
            ] else ...[
              // Patient fields shown when patient is selected or provider signup is disabled
              TextField(
                controller: _dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _genderController,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _ethnicityController,
                decoration: const InputDecoration(
                  labelText: 'Ethnicity',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 24),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _credentialsController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _ethnicityController.dispose();
    super.dispose();
  }
}
