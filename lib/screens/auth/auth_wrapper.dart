// lib/screens/auth/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_screen.dart';
import '../main_screen.dart';
import 'onboarding_screen.dart';
import '../provider/provider_dashboard_screen.dart';
import '../../models/user_model.dart';
import '../../services/firebase_service.dart';

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
                  // Patients go to onboarding or MainScreen
                  return userModel.onboarded
                      ? const MainScreen()
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
