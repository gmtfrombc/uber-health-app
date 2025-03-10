// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/patient_request.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      'aiTriageSummary': aiTriageSummary, // initially may be null
      'providerResponse': providerResponse,
      'providerInstructions': providerInstructions,
    };

    // Save the document and return its id
    DocumentReference docRef = await _firestore
        .collection('conversations')
        .add(data);
    print("Document added with ID: ${docRef.id}");
    return docRef.id;
  }
}
