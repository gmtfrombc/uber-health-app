// lib/models/patient_request.dart
enum RequestType { consult, medicalQuestion }

class PatientRequest {
  final String patientId; // The Firebase Auth UID of the patient
  final RequestType requestType;
  final String urgency; // "Quick", "Routine", or "No Rush"

  PatientRequest({
    required this.patientId,
    required this.requestType,
    required this.urgency,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'requestType':
          requestType
              .toString(), // Alternatively: requestType.name if using Dart 2.15+
      'urgency': urgency,
    };
  }
}
