// lib/services/user_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a new user profile to Firestore (creates/overwrites the document).
  Future<void> saveUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
      debugPrint("User profile saved successfully for uid: ${user.uid}");
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
        print("No user profile found for uid: $uid");
        return null;
      }
    } catch (error) {
      print("Error getting user profile: $error");
      rethrow;
    }
  }

  // Update an existing user profile.
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).update(user.toMap());
      debugPrint("User profile updated successfully for uid: ${user.uid}");
    } catch (error) {
      debugPrint("Error updating user profile: $error");
      rethrow;
    }
  }
}
