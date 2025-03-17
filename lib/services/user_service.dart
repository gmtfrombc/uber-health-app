// lib/services/user_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a new user profile to Firestore (creates/overwrites the document).
  Future<void> saveUserProfile(UserModel user) async {
    try {
      final userMap = user.toMap();
      await _firestore.collection('users').doc(user.uid).set(userMap);
    } catch (error) {
      debugPrint("Error saving user profile: $error");
      rethrow;
    }
  }

  // Retrieve a user profile by uid.
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        return null;
      }
    } catch (error) {
      debugPrint("Error retrieving user profile: $error");
      rethrow;
    }
  }

  // Update an existing user profile.
  Future<void> updateUserProfile(UserModel user) async {
    try {
      final userMap = user.toMap();
      await _firestore.collection('users').doc(user.uid).update(userMap);
    } catch (error) {
      debugPrint("Error updating user profile: $error");
      rethrow;
    }
  }
}
