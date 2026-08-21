import 'parent_role.dart';

/// The family's child, as returned nested on `UserProfile`. Mirrors the
/// backend's `ChildResponse` schema (`backend/docs/openapi.yaml`).
class ChildInfo {
  const ChildInfo({required this.name, required this.dateOfBirth});

  final String name;
  final DateTime dateOfBirth;

  factory ChildInfo.fromJson(Map<String, dynamic> json) {
    return ChildInfo(name: json['name'] as String, dateOfBirth: DateTime.parse(json['dob'] as String));
  }
}

/// The signed-in user's own account info. Mirrors the backend's
/// `MeResponse` schema, as returned by `GET /me`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.role,
    required this.familyId,
    required this.createdAt,
    this.child,
  });

  final String id;
  final String email;
  final ParentRole role;
  final String familyId;
  final DateTime createdAt;

  /// The family's child, if one exists on file.
  final ChildInfo? child;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      role: ParentRole.fromApiValue(json['role'] as String),
      familyId: json['familyId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      child: json['child'] == null ? null : ChildInfo.fromJson(json['child'] as Map<String, dynamic>),
    );
  }
}
