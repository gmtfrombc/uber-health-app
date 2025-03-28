// lib/screens/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'provider_dashboard_screen.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // When auth state is active:
        if (snapshot.connectionState == ConnectionState.active) {
          final firebaseUser = snapshot.data;
          if (firebaseUser == null) {
            return const SignInScreen();
          }
          // If user is signed in, fetch full profile.
          return FutureBuilder<UserModel>(
            future: FirebaseService().getUserMedicalInfo(firebaseUser.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (userSnapshot.hasData) {
                final userModel = userSnapshot.data!;

                // Route based on user role
                if (userModel.role == 'provider') {
                  // Providers go to their dashboard
                  return const ProviderDashboardScreen();
                } else {
                  // Patients go to home or onboarding depending on status
                  return userModel.onboarded
                      ? const HomeScreen()
                      : const OnboardingScreen();
                }
              }
              // If no profile data exists, sign out and return SignInScreen.
              FirebaseAuth.instance.signOut();
              return const SignInScreen();
            },
          );
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
