// ignore_for_file: public_member_api_docs
import 'dart:convert';

enum Gender { male, female, unknown }

class UserProfile {
  final String firstName;
  final String lastName;
  final String email;
  final Gender gender;
  final DateTime? birthDate;
  final double? heightCm;
  final double? weightKg;

  const UserProfile({
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.gender = Gender.unknown,
    this.birthDate,
    this.heightCm,
    this.weightKg,
  });

  String get fullName =>
      [lastName.trim(), firstName.trim()].where((s) => s.isNotEmpty).join(' ');

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    Gender? gender,
    DateTime? birthDate,
    double? heightCm,
    double? weightKg,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
    );
  }

  Map<String, dynamic> toMap() => {
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'gender': gender.name,
    'birthDate': birthDate?.toIso8601String(),
    'heightCm': heightCm,
    'weightKg': weightKg,
  };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    firstName: (map['firstName'] ?? '').toString(),
    lastName: (map['lastName'] ?? '').toString(),
    email: (map['email'] ?? '').toString(),
    gender: _genderFrom(map['gender']),
    birthDate: map['birthDate'] != null && map['birthDate'] != ''
        ? DateTime.tryParse(map['birthDate'])
        : null,
    heightCm: (map['heightCm'] is num) ? (map['heightCm'] as num).toDouble() : _toDouble(map['heightCm']),
    weightKg: (map['weightKg'] is num) ? (map['weightKg'] as num).toDouble() : _toDouble(map['weightKg']),
  );

  String toJson() => jsonEncode(toMap());
  factory UserProfile.fromJson(String s) => UserProfile.fromMap(jsonDecode(s));

  static Gender _genderFrom(dynamic v) {
    final s = (v ?? '').toString();
    if (s == Gender.male.name) return Gender.male;
    if (s == Gender.female.name) return Gender.female;
    return Gender.unknown;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    return double.tryParse(s.replaceAll(',', '.'));
  }
}
