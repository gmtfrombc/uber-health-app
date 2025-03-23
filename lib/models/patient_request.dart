// patient_request.dart
import 'package:flutter/foundation.dart';

enum RequestType { consult, medicalQuestion }

enum ProviderType { medicalProvider, physicalTherapist }

class PatientRequest {
  final String patientId;
  final RequestType requestType;
  final String urgency;
  final String category;
  final ProviderType providerType;
  final DateTime timestamp;

  PatientRequest({
    required this.patientId,
    required this.requestType,
    required this.urgency,
    required this.category,
    this.providerType = ProviderType.medicalProvider,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now() {
    if (patientId.isEmpty) {
      debugPrint('WARNING: Creating PatientRequest with empty patientId');
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'requestType': requestType.name,
      'urgency': urgency,
      'category': category,
      'providerType': providerType.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory PatientRequest.fromMap(Map<String, dynamic> map) {
    return PatientRequest(
      patientId: map['patientId'] ?? '',
      requestType: _parseRequestType(map['requestType']),
      urgency: map['urgency'] ?? 'Routine',
      category: map['category'] ?? 'General',
      providerType: _parseProviderType(map['providerType']),
      timestamp:
          map['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
              : DateTime.now(),
    );
  }

  static RequestType _parseRequestType(dynamic value) {
    if (value == null) return RequestType.medicalQuestion;

    if (value is RequestType) return value;

    final String strValue = value.toString().toLowerCase();

    if (strValue.contains('consult')) return RequestType.consult;
    return RequestType.medicalQuestion;
  }

  static ProviderType _parseProviderType(dynamic value) {
    if (value == null) return ProviderType.medicalProvider;

    if (value is ProviderType) return value;

    final String strValue = value.toString().toLowerCase();

    if (strValue.contains('physical')) return ProviderType.physicalTherapist;
    return ProviderType.medicalProvider;
  }
}
