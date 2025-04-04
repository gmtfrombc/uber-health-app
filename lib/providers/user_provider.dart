// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/firebase_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final UserService _userService = UserService();
  final FirebaseService _firebaseService = FirebaseService();

  UserModel? _userProfile;
  bool _isLoading = false;
  String _error = '';

  // Getters
  UserModel? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String get error => _error;

  // Initialize the provider - should be called when the app starts
  Future<void> initialize() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await fetchUserProfile();
    }
  }

  // Fetch user profile from Firebase
  Future<void> fetchUserProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    // Set loading state first, then notify
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      // Get user data from Firebase
      final userData = await _firebaseService.getUserMedicalInfo(userId);

      // Update state in a separate operation after data is received
      _userProfile = userData;
      _user = userData; // Keep both in sync
      _isLoading = false;

      // Notify after all state changes are complete
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load user profile: $e';
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(UserModel updatedProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firebaseService.updateUserMedicalInfo(updatedProfile);
      _userProfile = updatedProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  // Clear user data (logout)
  void clearUserData() {
    _userProfile = null;
    _error = '';
    notifyListeners();
  }

  // Check if user profile is loaded
  bool get isProfileLoaded => _userProfile != null;

  // Format health information with bullets
  String formatListWithBullets(List<String>? items) {
    if (items == null || items.isEmpty) return "None";
    return items.map((item) => "• $item").join("\n");
  }

  // Load a user profile from Firestore.
  Future<void> loadUser(String uid) async {
    _user = await _userService.getUserProfile(uid);
    notifyListeners();
  }

  // Save a new user profile.
  Future<void> saveUser(UserModel user) async {
    await _userService.saveUserProfile(user);
    _user = user;
    notifyListeners();
  }

  // Update an existing user profile.
  Future<void> updateUser(UserModel user) async {
    await _userService.updateUserProfile(user);
    _user = user;
    notifyListeners();
  }
}
