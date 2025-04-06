import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/debug_utils.dart';
import 'auth/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Start the animation
    _controller.forward();

    // Initialize SharedPreferences early
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    try {
      // Pre-initialize SharedPreferences
      await SharedPreferences.getInstance();
      debugPrint('SharedPreferences initialized successfully');
    } catch (e) {
      debugPrint('Error initializing SharedPreferences: $e');
    }

    // Navigate to the next screen after animation completes, even if preferences failed
    if (mounted) {
      Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: Stack(
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo or app name with animation
                      SizedBox(
                        height: 250,
                        width: 250,
                        child: Lottie.asset(
                          'assets/animations/doctor_connecting.json',
                          controller: _controller,
                          onLoaded: (composition) {
                            _controller.duration = composition.duration;
                          },
                        ),
                      ),
                      const SizedBox(height: 30),
                      // App name with large text
                      Text(
                        'XUBER HEALTH',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Tagline
                      Text(
                        'Healthcare at your fingertips',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withAlpha(204),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // Version number at the bottom
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Text(
                DebugUtils.getVersionInfo(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
