// patient_request.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestType { consult, medicalQuestion }

enum ProviderType { medicalProvider, physicalTherapist }

enum RequestStatus {
  pending, // Initial state
  triaged, // AI has assessed
  assigned, // Provider assigned
  inProgress, // Provider actively working with patient
  completed, // Visit complete
  cancelled, // Request cancelled
  scheduled, // Appointment scheduled for future
  checkedIn, // Patient checked in for appointment
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
  final DateTime? scheduledDateTime; // Time when appointment is scheduled
  final String? providerId; // ID of the provider selected for this request

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
    this.scheduledDateTime,
    this.providerId,
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
      'scheduledDateTime': scheduledDateTime?.millisecondsSinceEpoch,
      'providerId': providerId,
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
      timestamp: _parseDateTime(map['timestamp']),
      status: _parseRequestStatus(map['status']),
      assignedProviderId: map['assignedProviderId'],
      triageSummaryId: map['triageSummaryId'],
      startTime: _parseDateTime(map['startTime']),
      endTime: _parseDateTime(map['endTime']),
      scheduledDateTime: _parseDateTime(map['scheduledDateTime']),
      providerId: map['providerId'],
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

  // Helper method to parse DateTime from different types
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;

    // Handle Firestore Timestamp objects
    if (value is Timestamp) {
      return value.toDate();
    }

    // Handle integer timestamps (milliseconds since epoch)
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    // Default fallback
    return null;
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
    DateTime? scheduledDateTime,
    String? providerId,
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
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      providerId: providerId ?? this.providerId,
    );
  }

  // Utility to check if request is active (not completed or cancelled)
  bool get isActive =>
      status != RequestStatus.completed && status != RequestStatus.cancelled;

  // Check if this is a scheduled appointment
  bool get isScheduled =>
      status == RequestStatus.scheduled && scheduledDateTime != null;

  // Check if appointment time is approaching (within 15 minutes)
  bool get isApproachingAppointment {
    if (!isScheduled || scheduledDateTime == null) return false;
    final now = DateTime.now();
    final difference = scheduledDateTime!.difference(now);
    return difference.inMinutes <= 15 && difference.inMinutes > 0;
  }
}
