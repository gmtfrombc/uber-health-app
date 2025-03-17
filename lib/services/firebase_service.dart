// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message.dart';
import '../models/patient_request.dart';
import '../models/user_model.dart';

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
      'requestType': request.requestType.name,
      'urgency': request.urgency,
      'category': request.category,
      'providerType': request.providerType.name, // <-- Corrected here
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
    return docRef.id;
  }

  // Updates an existing conversation document.
  Future<void> updatePatientRequest(
    String docId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('conversations').doc(docId).update(data);
  }


  // Deletes a conversation document.
  Future<void> deleteConversation(String docId) async {
    await _firestore.collection('conversations').doc(docId).delete();
  }

  // Updates the user’s medical information in the 'users' collection.
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
