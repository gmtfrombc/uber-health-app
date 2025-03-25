class TriageSummary {
  final String id;
  final String patientId;
  final String requestId;

  // Triage content fields
  final String chiefComplaint;
  final String summary;
  final String assessment;
  final String recommendedAction;
  final String urgencyLevel; // Low, Medium, High, Emergency

  // Additional data that might be useful
  final Map<String, dynamic>? additionalData;
  final List<String>? potentialDiagnoses;
  final List<String>? recommendedTests;

  // Metadata
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? createdBy; // 'AI' or provider ID if modified

  TriageSummary({
    this.id = '',
    required this.patientId,
    required this.requestId,
    required this.chiefComplaint,
    required this.summary,
    required this.assessment,
    required this.recommendedAction,
    required this.urgencyLevel,
    this.additionalData,
    this.potentialDiagnoses,
    this.recommendedTests,
    DateTime? createdAt,
    this.updatedAt,
    this.createdBy = 'AI',
  }) : createdAt = createdAt ?? DateTime.now();

  // Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'requestId': requestId,
      'chiefComplaint': chiefComplaint,
      'summary': summary,
      'assessment': assessment,
      'recommendedAction': recommendedAction,
      'urgencyLevel': urgencyLevel,
      'additionalData': additionalData,
      'potentialDiagnoses': potentialDiagnoses,
      'recommendedTests': recommendedTests,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  // Create from Firestore
  factory TriageSummary.fromMap(Map<String, dynamic> map, {String docId = ''}) {
    return TriageSummary(
      id: docId,
      patientId: map['patientId'] as String? ?? '',
      requestId: map['requestId'] as String? ?? '',
      chiefComplaint: map['chiefComplaint'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      assessment: map['assessment'] as String? ?? '',
      recommendedAction: map['recommendedAction'] as String? ?? '',
      urgencyLevel: map['urgencyLevel'] as String? ?? 'Medium',
      additionalData: map['additionalData'] as Map<String, dynamic>?,
      potentialDiagnoses:
          map['potentialDiagnoses'] != null
              ? List<String>.from(map['potentialDiagnoses'])
              : null,
      recommendedTests:
          map['recommendedTests'] != null
              ? List<String>.from(map['recommendedTests'])
              : null,
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'] as String)
              : null,
      createdBy: map['createdBy'] as String? ?? 'AI',
    );
  }

  // Create a copy with updated fields
  TriageSummary copyWith({
    String? id,
    String? patientId,
    String? requestId,
    String? chiefComplaint,
    String? summary,
    String? assessment,
    String? recommendedAction,
    String? urgencyLevel,
    Map<String, dynamic>? additionalData,
    List<String>? potentialDiagnoses,
    List<String>? recommendedTests,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return TriageSummary(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      requestId: requestId ?? this.requestId,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      summary: summary ?? this.summary,
      assessment: assessment ?? this.assessment,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      additionalData: additionalData ?? this.additionalData,
      potentialDiagnoses: potentialDiagnoses ?? this.potentialDiagnoses,
      recommendedTests: recommendedTests ?? this.recommendedTests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // Color code based on urgency level
  String get urgencyColor {
    switch (urgencyLevel.toLowerCase()) {
      case 'low':
        return 'green';
      case 'medium':
        return 'orange';
      case 'high':
        return 'red';
      case 'emergency':
        return 'deepred';
      default:
        return 'orange';
    }
  }
}
