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

      // Add provider ID if available
      if (request.providerId != null && request.providerId!.isNotEmpty) {
        data['providerId'] = request.providerId;
        debugPrint('Adding providerId to request: ${request.providerId}');
      }

      // Add scheduled date/time if available
      if (request.scheduledDateTime != null) {
        data['scheduledDateTime'] = Timestamp.fromDate(
          request.scheduledDateTime!,
        );
      }

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

      // Debug log for provider ID
      if (data.containsKey('providerId')) {
        debugPrint(
          'Updating conversation with provider ID: ${data['providerId']}',
        );
      }

      await _firestore.collection('conversations').doc(docId).update(data);
      debugPrint('Document successfully updated');
      return true;
    } catch (e) {
      debugPrint('ERROR updating patient request: $e');
      return false;
    }
  }

  // Fetches upcoming appointments for a patient
  Future<List<PatientRequest>> getUpcomingAppointments(String patientId) async {
    try {
      final now = DateTime.now();

      final snapshot =
          await _firestore
              .collection('conversations')
              .where('patientId', isEqualTo: patientId)
              .where('status', isEqualTo: RequestStatus.scheduled.name)
              .where(
                'scheduledDateTime',
                isGreaterThan: Timestamp.fromDate(now),
              )
              .orderBy('scheduledDateTime')
              .get();

      return snapshot.docs.map((doc) {
        return PatientRequest.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('ERROR fetching upcoming appointments: $e');
      return [];
    }
  }

  // Check for appointments that are about to start (within 15 minutes)
  Future<List<PatientRequest>> getImmediateAppointments(
    String patientId,
  ) async {
    try {
      final now = DateTime.now();
      final cutoff = now.add(const Duration(minutes: 15));

      final snapshot =
          await _firestore
              .collection('conversations')
              .where('patientId', isEqualTo: patientId)
              .where('status', isEqualTo: RequestStatus.scheduled.name)
              .where(
                'scheduledDateTime',
                isGreaterThan: Timestamp.fromDate(now),
              )
              .where(
                'scheduledDateTime',
                isLessThanOrEqualTo: Timestamp.fromDate(cutoff),
              )
              .get();

      return snapshot.docs.map((doc) {
        return PatientRequest.fromMap(doc.data(), docId: doc.id);
      }).toList();
    } catch (e) {
      debugPrint('ERROR fetching immediate appointments: $e');
      return [];
    }
  }

  // Update appointment status
  Future<bool> updateAppointmentStatus(
    String docId,
    RequestStatus status,
  ) async {
    try {
      await _firestore.collection('conversations').doc(docId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('ERROR updating appointment status: $e');
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

  // Fetch provider details by provider ID
  Future<Map<String, dynamic>?> getProviderDetails(String providerId) async {
    try {
      if (providerId.isEmpty) return null;

      debugPrint('Fetching provider details for ID: $providerId');
      final doc =
          await _firestore.collection('providers').doc(providerId).get();

      // If not found in providers collection, try to query by id
      if (!doc.exists) {
        debugPrint(
          'Provider document not found by direct ID, trying query: $providerId',
        );
        final querySnapshot =
            await _firestore
                .collection('providers')
                .where('id', isEqualTo: providerId)
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          debugPrint('Found provider via query for ID: $providerId');
          return querySnapshot.docs.first.data();
        }

        debugPrint('Provider document not found for ID: $providerId');
        return null;
      }

      debugPrint('Provider document found for ID: $providerId');
      return doc.data();
    } catch (e) {
      debugPrint('ERROR fetching provider details: $e');
      return null;
    }
  }

  // Fetch all providers of a specific type
  Future<List<Map<String, dynamic>>> getAllProviders(
    String providerType,
  ) async {
    try {
      debugPrint('Fetching all providers of type: $providerType');
      final snapshot =
          await _firestore
              .collection('providers')
              .where('providerType', isEqualTo: providerType)
              .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No providers found of type: $providerType');
        return [];
      }

      debugPrint(
        'Found ${snapshot.docs.length} providers of type: $providerType',
      );
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Add the document ID to the data
        return {...data, 'id': doc.id};
      }).toList();
    } catch (e) {
      debugPrint('ERROR fetching providers: $e');
      return [];
    }
  }

  // Fetch a patient request by ID
  Future<PatientRequest?> getPatientRequestById(String requestId) async {
    try {
      final docSnapshot =
          await _firestore.collection('conversations').doc(requestId).get();

      if (docSnapshot.exists) {
        return PatientRequest.fromMap(
          docSnapshot.data()!,
          docId: docSnapshot.id,
        );
      }

      return null;
    } catch (e) {
      debugPrint('ERROR fetching patient request by ID: $e');
      return null;
    }
  }
}
