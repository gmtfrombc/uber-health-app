// patient_request.dart
import 'package:flutter/foundation.dart';

enum RequestType { consult, medicalQuestion }

enum ProviderType { medicalProvider, physicalTherapist }

enum RequestStatus {
  pending, // Initial state
  triaged, // AI has assessed
  assigned, // Provider assigned
  inProgress, // Provider actively working with patient
  completed, // Visit complete
  cancelled, // Request cancelled
}

class PatientRequest {
  final String id; // Document ID for the request
  final String patientId;
  final RequestType requestType;
  final String urgency;
  final String category;
  final ProviderType providerType;
  final DateTime timestamp;
  final RequestStatus status;
  final String? assignedProviderId;
  final String? triageSummaryId;
  final DateTime? startTime;
  final DateTime? endTime;

  PatientRequest({
    this.id = '', // Allow empty string for new requests
    required this.patientId,
    required this.requestType,
    required this.urgency,
    required this.category,
    this.providerType = ProviderType.medicalProvider,
    DateTime? timestamp,
    this.status = RequestStatus.pending,
    this.assignedProviderId,
    this.triageSummaryId,
    this.startTime,
    this.endTime,
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
      'status': status.name,
      'assignedProviderId': assignedProviderId,
      'triageSummaryId': triageSummaryId,
      'startTime': startTime?.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
    };
  }

  factory PatientRequest.fromMap(
    Map<String, dynamic> map, {
    String docId = '',
  }) {
    return PatientRequest(
      id: docId,
      patientId: map['patientId'] ?? '',
      requestType: _parseRequestType(map['requestType']),
      urgency: map['urgency'] ?? 'Routine',
      category: map['category'] ?? 'General',
      providerType: _parseProviderType(map['providerType']),
      timestamp:
          map['timestamp'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'])
              : DateTime.now(),
      status: _parseRequestStatus(map['status']),
      assignedProviderId: map['assignedProviderId'],
      triageSummaryId: map['triageSummaryId'],
      startTime:
          map['startTime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['startTime'])
              : null,
      endTime:
          map['endTime'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
              : null,
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

  static RequestStatus _parseRequestStatus(dynamic value) {
    if (value == null) return RequestStatus.pending;

    if (value is RequestStatus) return value;

    final String strValue = value.toString().toLowerCase();

    for (var status in RequestStatus.values) {
      if (strValue.contains(status.name.toLowerCase())) {
        return status;
      }
    }

    return RequestStatus.pending;
  }

  // Create a copy of this request with updated fields
  PatientRequest copyWith({
    String? id,
    String? patientId,
    RequestType? requestType,
    String? urgency,
    String? category,
    ProviderType? providerType,
    DateTime? timestamp,
    RequestStatus? status,
    String? assignedProviderId,
    String? triageSummaryId,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return PatientRequest(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      requestType: requestType ?? this.requestType,
      urgency: urgency ?? this.urgency,
      category: category ?? this.category,
      providerType: providerType ?? this.providerType,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      assignedProviderId: assignedProviderId ?? this.assignedProviderId,
      triageSummaryId: triageSummaryId ?? this.triageSummaryId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  // Utility to check if request is active (not completed or cancelled)
  bool get isActive =>
      status != RequestStatus.completed && status != RequestStatus.cancelled;
}
