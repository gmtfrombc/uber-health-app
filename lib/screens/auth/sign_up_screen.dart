// lib/screens/auth/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/consistent_app_bar.dart';
import 'onboarding_screen.dart';
import 'sign_in_screen.dart';
import '../../utils/app_config.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  String? _selectedGender;

  // List of gender options
  final List<String> _genders = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _selectDate(BuildContext context) async {
    final theme = Theme.of(context);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 365 * 18),
      ), // Default to 18 years ago
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: theme.colorScheme.primary,
              onPrimary: Colors.white,
              onSurface: theme.colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _dobController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  Future<void> _signUp() async {
    // Validate all fields first
    if (_formKey.currentState?.validate() != true) {
      return;
    }

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
        // Create user model (always patient for now)
        UserModel newUser = UserModel(
          uid: credential.user!.uid,
          role: RoleTypes.patient,
          firstname: _firstNameController.text.trim(),
          lastname: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          dob: _dobController.text.trim(),
          gender: _selectedGender,
          createdAt: DateTime.now(),
        );

        // Save the user profile using the UserProvider
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.saveUser(newUser);

        // Navigate to onboarding
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
              'This email is already in use. Please try another one.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign up.';
      }

      setState(() {
        _errorMessage = errorMessage;
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ConsistentAppBar(
        title: 'XUBER Health',
        automaticallyImplyLeading: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignInScreen()),
              );
            },
            child: Text(
              'SIGN IN',
              style: TextStyle(
                color: theme.appBarTheme.foregroundColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main content
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Error message
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withAlpha(26),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                        ),

                      // Sign up heading
                      Text(
                        'Create your XUBER Health account.',
                        style: theme.textTheme.displaySmall,
                      ),

                      const SizedBox(height: 32),

                      // First Name field
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: TextFormField(
                          controller: _firstNameController,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'First Name',
                            hintStyle: TextStyle(color: theme.hintColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                      ),

                      // Last Name field
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: TextFormField(
                          controller: _lastNameController,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Last Name',
                            hintStyle: TextStyle(color: theme.hintColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                      ),

                      // Email field
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Email address',
                            hintStyle: TextStyle(color: theme.hintColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }

                            // Basic email validation
                            final emailRegExp = RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            );
                            if (!emailRegExp.hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }

                            return null;
                          },
                        ),
                      ),

                      // Date of Birth field
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: TextFormField(
                          controller: _dobController,
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Date of Birth (MM/DD/YYYY)',
                            hintStyle: TextStyle(color: theme.hintColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                Icons.calendar_month,
                                color: theme.hintColor,
                              ),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Date of birth is required';
                            }

                            // Validate date format
                            try {
                              DateFormat('MM/dd/yyyy').parseStrict(value);
                            } catch (e) {
                              return 'Invalid date format. Use MM/DD/YYYY';
                            }

                            return null;
                          },
                        ),
                      ),

                      // Gender dropdown
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Theme(
                          // Apply a custom theme to the dropdown to ensure text is visible in dark mode
                          data: Theme.of(context).copyWith(
                            canvasColor:
                                isDarkMode
                                    ? theme.colorScheme.surface
                                    : Colors.white,
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            style: TextStyle(
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Select Gender',
                              hintStyle: TextStyle(color: theme.hintColor),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            items:
                                _genders
                                    .map(
                                      (gender) => DropdownMenuItem(
                                        value: gender,
                                        child: Text(gender),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedGender = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a gender';
                              }
                              return null;
                            },
                            dropdownColor:
                                isDarkMode
                                    ? theme.colorScheme.surface
                                    : Colors.white,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: theme.hintColor,
                            ),
                          ),
                        ),
                      ),

                      // Password field
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color:
                              isDarkMode
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(color: theme.hintColor),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: theme.hintColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Password is required';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),

                      // Already have an account? Sign in link
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                          ),
                          child: const Text(
                            'Already have an account? Sign In',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Sign up button at bottom
          SafeArea(
            child: Container(
              width: double.infinity,
              color:
                  isDarkMode
                      ? theme.cardTheme.color
                      : theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  disabledBackgroundColor: theme.colorScheme.primary
                      .withOpacity(0.6),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                        : const Text(
                          'SIGN UP',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dobController.dispose();
    super.dispose();
  }
}
