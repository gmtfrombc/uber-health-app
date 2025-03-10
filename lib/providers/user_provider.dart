// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  final UserService _userService = UserService();

  UserModel? get user => _user;

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
