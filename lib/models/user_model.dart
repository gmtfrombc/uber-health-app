// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String role; // "patient" or "provider"
  final String name;
  final String email;
  // Optional fields for patients:
  final String? dob;
  final String? gender;
  final String? ethnicity;
  // Optional fields for providers:
  final String? specialty;
  final String? bio;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.dob,
    this.gender,
    this.ethnicity,
    this.specialty,
    this.bio,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role,
      'name': name,
      'email': email,
      'dob': dob,
      'gender': gender,
      'ethnicity': ethnicity,
      'specialty': specialty,
      'bio': bio,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  static UserModel fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      role: map['role'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      dob: map['dob'] as String?,
      gender: map['gender'] as String?,
      ethnicity: map['ethnicity'] as String?,
      specialty: map['specialty'] as String?,
      bio: map['bio'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt:
          map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'] as String)
              : null,
    );
  }
}
