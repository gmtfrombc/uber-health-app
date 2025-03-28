// lib/screens/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import 'onboarding_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // Additional patient info fields
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ethnicityController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

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
        // Debug: Print values from controllers.
        debugPrint('First Name: ${_firstNameController.text}');
        debugPrint('Last Name: ${_lastNameController.text}');
        debugPrint('Email: ${_emailController.text}');
        debugPrint('DOB: ${_dobController.text}');
        debugPrint('Gender: ${_genderController.text}');
        debugPrint('Ethnicity: ${_ethnicityController.text}');

        // Create a new user profile with firstname and lastname.
        UserModel newUser = UserModel(
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
        // Save the user profile using the UserProvider.
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.saveUser(newUser);
        // Navigate to OnboardingScreen on successful sign-up.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    _ethnicityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: "First Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dobController,
              decoration: const InputDecoration(
                labelText: "Date of Birth (YYYY-MM-DD)",
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _genderController,
              decoration: const InputDecoration(labelText: "Gender"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ethnicityController,
              decoration: const InputDecoration(labelText: "Ethnicity"),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                  onPressed: _signUp,
                  child: const Text("Sign Up"),
                ),
          ],
        ),
      ),
    );
  }
}
