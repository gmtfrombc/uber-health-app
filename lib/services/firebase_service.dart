// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/patient_request.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Creates a new conversation document and returns its ID.
  Future<String?> savePatientRequest(
    PatientRequest request,
    List<Message> conversation, {
    String status = "pending",
    String? aiTriageSummary,
    String? providerResponse,
    String? providerInstructions,
  }) async {
    try {
      debugPrint(
        'Attempting to save conversation for patient: ${request.patientId}',
      );
      debugPrint(
        'Messages count: ${conversation.length}, Has summary: ${aiTriageSummary != null}',
      );

      // Check for valid patient ID
      if (request.patientId.isEmpty) {
        debugPrint('ERROR: Cannot save request - patient ID is empty');
        return null;
      }

      Map<String, dynamic> data = {
        'patientId': request.patientId,
        'requestType': request.requestType.name,
        'urgency': request.urgency,
        'category': request.category,
        'providerType': request.providerType.name,
        'status': status,
        'messages': conversation.map((msg) => msg.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add non-null fields
      if (aiTriageSummary != null) {
        data['aiTriageSummary'] = aiTriageSummary;
      }

      if (providerResponse != null) {
        data['providerResponse'] = providerResponse;
      }

      if (providerInstructions != null) {
        data['providerInstructions'] = providerInstructions;
      }

      debugPrint('Adding document to conversations collection...');
      DocumentReference docRef = await _firestore
          .collection('conversations')
          .add(data);

      debugPrint('Document successfully added with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('ERROR saving patient request: $e');
      return null;
    }
  }

  // Updates an existing conversation document.
  Future<bool> updatePatientRequest(
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      debugPrint('Updating conversation document: $docId');
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore.collection('conversations').doc(docId).update(data);
      debugPrint('Document successfully updated');
      return true;
    } catch (e) {
      debugPrint('ERROR updating patient request: $e');
      return false;
    }
  }

  // Deletes a conversation document.
  Future<void> deleteConversation(String docId) async {
    await _firestore.collection('conversations').doc(docId).delete();
  }

  // Updates the user's medical information in the 'users' collection.
  Future<void> updateUserMedicalInfo(UserModel user) async {
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(user.toMap(), SetOptions(merge: true));
  }

  // Fetches the user medical information from the 'users' collection.
  Future<UserModel> getUserMedicalInfo(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    } else {
      throw Exception("User document not found for UID: $uid");
    }
  }
}
