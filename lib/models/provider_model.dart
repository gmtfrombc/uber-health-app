// lib/models/provider_model.dart
import 'patient_request.dart'; // For ProviderType

class ProviderModel {
  final String id;
  final String uid; // Firebase auth UID
  final String firstname;
  final String lastname;
  final String email;
  final String? credentials; // MD, NP, etc.
  final String? specialty; // Primary care, cardiology, etc.
  final String? bio;
  final List<String>? languages;
  final String? profileImageUrl;
  final bool isAvailable; // Available for new patients
  final int? maxPatients; // Maximum patients allowed in queue
  final ProviderType providerType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Fields used primarily for patient selection UI
  final double? cost; // Consultation cost
  final String? waitTime; // Average wait time (e.g., "5 minutes")

  ProviderModel({
    required this.id,
    required this.uid,
    required this.firstname,
    required this.lastname,
    required this.email,
    this.credentials,
    this.specialty,
    this.bio,
    this.languages,
    this.profileImageUrl,
    this.isAvailable = true,
    this.maxPatients,
    required this.providerType,
    this.cost,
    this.waitTime,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Full name utility getter
  String get fullName =>
      '$firstname $lastname${credentials != null ? ', $credentials' : ''}';

  // Map to Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      'credentials': credentials,
      'specialty': specialty,
      'bio': bio,
      'languages': languages,
      'profileImageUrl': profileImageUrl,
      'isAvailable': isAvailable,
      'maxPatients': maxPatients,
      'providerType': providerType.name,
      'cost': cost,
      'waitTime': waitTime,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Create from Firestore
  factory ProviderModel.fromMap(Map<String, dynamic> map, {String docId = ''}) {
    ProviderType providerType = ProviderType.medicalProvider;
    if (map['providerType'] != null) {
      if (map['providerType'].toString().toLowerCase().contains('physical')) {
        providerType = ProviderType.physicalTherapist;
      }
    }

    return ProviderModel(
      id: docId,
      uid: map['uid'] as String? ?? '',
      firstname: map['firstname'] as String? ?? '',
      lastname: map['lastname'] as String? ?? '',
      email: map['email'] as String? ?? '',
      credentials: map['credentials'] as String?,
      specialty: map['specialty'] as String?,
      bio: map['bio'] as String?,
      languages:
          map['languages'] != null ? List<String>.from(map['languages']) : null,
      profileImageUrl: map['profileImageUrl'] as String?,
      isAvailable: map['isAvailable'] as bool? ?? true,
      maxPatients: map['maxPatients'] as int?,
      providerType: providerType,
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      waitTime: map['waitTime'] as String?,
      createdAt:
          map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : DateTime.now(),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'] as String)
              : null,
    );
  }

  // Create a copy with updated fields
  ProviderModel copyWith({
    String? id,
    String? uid,
    String? firstname,
    String? lastname,
    String? email,
    String? credentials,
    String? specialty,
    String? bio,
    List<String>? languages,
    String? profileImageUrl,
    bool? isAvailable,
    int? maxPatients,
    ProviderType? providerType,
    double? cost,
    String? waitTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      firstname: firstname ?? this.firstname,
      lastname: lastname ?? this.lastname,
      email: email ?? this.email,
      credentials: credentials ?? this.credentials,
      specialty: specialty ?? this.specialty,
      bio: bio ?? this.bio,
      languages: languages ?? this.languages,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      maxPatients: maxPatients ?? this.maxPatients,
      providerType: providerType ?? this.providerType,
      cost: cost ?? this.cost,
      waitTime: waitTime ?? this.waitTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
