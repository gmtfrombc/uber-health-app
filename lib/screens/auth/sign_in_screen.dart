// lib/screens/sign_in_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/consistent_app_bar.dart';
import 'sign_up_screen.dart';
import 'auth_wrapper.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController(
    text: "bsmith@google.com",
  ); // Hard-coded for testing
  final TextEditingController _passwordController = TextEditingController(
    text: "password",
  ); // Hard-coded for testing

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simple retry logic
    int maxRetries = 3;
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final credential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        if (credential.user != null) {
          // Force navigation instead of relying solely on the auth state listener
          if (!mounted) return;

          // Clear any cached state
          await Future.delayed(Duration(milliseconds: 300));

          // Navigate to the AuthWrapper which will determine the correct screen
          // based on user role
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
          );
          return; // Success, exit the method
        }
      } on FirebaseAuthException catch (e) {
        // Auth-specific errors shouldn't be retried
        setState(() {
          _errorMessage = e.message;
        });
        break;
      } catch (e) {
        // For network errors, retry if not the last attempt
        if (attempt == maxRetries - 1) {
          setState(() {
            _errorMessage =
                "Network error. Please check your connection and try again.";
          });
        } else {
          // Wait before retrying with exponential backoff
          await Future.delayed(
            Duration(seconds: 1 << attempt),
          ); // 1, 2, 4 seconds
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _errorMessage = 'Apple sign-in is not implemented yet';
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Use theme colors instead of hardcoded colors
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ConsistentAppBar(
        title: 'XUBER Health',
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SignUpScreen()),
              );
            },
            child: Text(
              'SIGN UP',
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

                    // Sign in heading
                    Text(
                      'Sign in to XUBER Health.',
                      style: theme.textTheme.displaySmall,
                    ),

                    const SizedBox(height: 32),

                    // Email field
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? theme.colorScheme.surface
                                : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: TextField(
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
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Password field
                    Container(
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? theme.colorScheme.surface
                                : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: TextField(
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
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Show a simple message since password reset isn't implemented
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset coming soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Text(
                          'FORGOT YOUR PASSWORD?',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // OR divider
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: theme.dividerColor, height: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.textTheme.bodySmall?.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: theme.dividerColor, height: 1),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Sign in with Apple button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode
                                ? theme.colorScheme.surface
                                : Colors.white,
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton.icon(
                        icon: Icon(
                          Icons.apple,
                          color: isDarkMode ? Colors.white : Colors.black,
                          size: 24,
                        ),
                        label: Text(
                          'Sign in with Apple',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.white : Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: _signInWithApple,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              isDarkMode
                                  ? theme.colorScheme.surface
                                  : Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Sign in button at bottom
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(50),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'SIGN IN',
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
}
