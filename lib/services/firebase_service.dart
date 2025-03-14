// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/patient_request.dart';
import 'package:flutter/material.dart';
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Creates a new conversation document and returns its ID.
  Future<String> savePatientRequest(
    PatientRequest request,
    List<Message> conversation, {
    String status = "pending",
    String? aiTriageSummary,
    String? providerResponse,
    String? providerInstructions,
  }) async {
    Map<String, dynamic> data = {
      'patientId': request.patientId,
      'requestType': request.requestType.toString(),
      'urgency': request.urgency,
      'status': status,
      'messages': conversation.map((msg) => msg.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'aiTriageSummary': aiTriageSummary,
      'providerResponse': providerResponse,
      'providerInstructions': providerInstructions,
    };

    DocumentReference docRef = await _firestore
        .collection('conversations')
        .add(data);
    debugPrint("Document added with ID: ${docRef.id}");
    return docRef.id;
  }

  // Updates an existing conversation document.
  Future<void> updatePatientRequest(
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('conversations').doc(docId).update(data);
    debugPrint("Document $docId updated.");
  }
}
