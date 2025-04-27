// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String role; // "patient" or "provider"
  final String firstname;
  final String lastname;
  final String email;

  // Provider-specific fields
  final String? credentials; // MD, DO, NP, PA
  final String? specialty;
  final String? bio;
  final List<String>? languages;
  final String? profileImageUrl;
  final bool isAvailable;
  final int? maxPatients;

  // Patient-specific fields
  final String? dob;
  final String? gender;
  final String? ethnicity;
  final List<String>? medications;
  final List<String>? allergies;
  final List<String>? conditions;

  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.role,
    required this.firstname,
    required this.lastname,
    required this.email,
    // Provider fields
    this.credentials,
    this.specialty,
    this.bio,
    this.languages,
    this.profileImageUrl,
    this.isAvailable = true,
    this.maxPatients,
    // Patient fields
    this.dob,
    this.gender,
    this.ethnicity,
    this.medications,
    this.allergies,
    this.conditions,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'firstname': firstname,
      'lastname': lastname,
      'email': email,
      // Provider fields
      'credentials': credentials,
      'specialty': specialty,
      'bio': bio,
      'languages': languages,
      'profileImageUrl': profileImageUrl,
      'isAvailable': isAvailable,
      'maxPatients': maxPatients,
      // Patient fields
      'dob': dob,
      'gender': gender,
      'ethnicity': ethnicity,
      'medications': medications,
      'allergies': allergies,
      'conditions': conditions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      role: map['role'] as String,
      firstname: map['firstname'] as String? ?? "",
      lastname: map['lastname'] as String? ?? "",
      email: map['email'] as String,
      // Provider fields
      credentials: map['credentials'] as String?,
      specialty: map['specialty'] as String?,
      bio: map['bio'] as String?,
      languages:
          map['languages'] != null ? List<String>.from(map['languages']) : null,
      profileImageUrl: map['profileImageUrl'] as String?,
      isAvailable: map['isAvailable'] as bool? ?? true,
      maxPatients: map['maxPatients'] as int?,
      // Patient fields
      dob: map['dob'] as String?,
      gender: map['gender'] as String?,
      ethnicity: map['ethnicity'] as String?,
      medications:
          map['medications'] != null
              ? List<String>.from(map['medications'])
              : null,
      allergies:
          map['allergies'] != null ? List<String>.from(map['allergies']) : null,
      conditions:
          map['conditions'] != null
              ? List<String>.from(map['conditions'])
              : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'] as String)
              : null,
    );
  }

  /// Computed property: consider the user onboarded if at least one health info field has been filled.
  bool get onboarded {
    if (role == 'provider') {
      return true; // Providers are considered onboarded by default
    }
    return (medications != null && medications!.isNotEmpty) ||
        (allergies != null && allergies!.isNotEmpty) ||
        (conditions != null && conditions!.isNotEmpty);
  }
}
