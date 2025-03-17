// patient_request.dart

enum RequestType { consult, medicalQuestion }

enum ProviderType { medicalProvider, physicalTherapist }

class PatientRequest {
  final String patientId;
  final RequestType requestType;
  final String urgency;
  final String category;
  final ProviderType providerType;

  PatientRequest({
    required this.patientId,
    required this.requestType,
    required this.urgency,
    required this.category,
    required this.providerType,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'requestType': requestType.name,
      'urgency': urgency,
      'category': category,
      'providerType': providerType.name,
    };
  }

  factory PatientRequest.fromMap(Map<String, dynamic> map) {
    return PatientRequest(
      patientId: map['patientId'],
      requestType: RequestType.values.byName(
        map['requestType'].split('.').last,
      ),
      urgency: map['urgency'],
      category: map['category'],
      providerType: ProviderType.values.byName(
        map['providerType'].split('.').last,
      ),
    );
  }
}
