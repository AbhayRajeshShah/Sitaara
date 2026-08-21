import 'parent_role.dart';

/// The authenticated user's identity + JWT, produced by either
/// `POST /auth/signin` or `POST /users`, and what gets persisted locally.
class AuthSession {
  const AuthSession({
    required this.id,
    required this.email,
    required this.role,
    required this.token,
    required this.tokenExpiresAt,
    this.familyId,
  });

  final String id;
  final String email;
  final ParentRole role;
  final String token;
  final DateTime tokenExpiresAt;

  /// Only present when the session came from `POST /users` (sign up).
  final String? familyId;

  factory AuthSession.fromSignInJson(Map<String, dynamic> json) {
    return AuthSession(
      id: json['id'] as String,
      email: json['email'] as String,
      role: ParentRole.fromApiValue(json['role'] as String),
      token: json['token'] as String,
      tokenExpiresAt: DateTime.parse(json['tokenExpiresAt'] as String),
    );
  }

  factory AuthSession.fromCreateUserJson(Map<String, dynamic> json) {
    return AuthSession(
      id: json['id'] as String,
      email: json['email'] as String,
      role: ParentRole.fromApiValue(json['role'] as String),
      token: json['token'] as String,
      tokenExpiresAt: DateTime.parse(json['tokenExpiresAt'] as String),
      familyId: json['familyId'] as String?,
    );
  }

  factory AuthSession.fromStorageJson(Map<String, dynamic> json) {
    return AuthSession(
      id: json['id'] as String,
      email: json['email'] as String,
      role: ParentRole.fromApiValue(json['role'] as String),
      token: json['token'] as String,
      tokenExpiresAt: DateTime.parse(json['tokenExpiresAt'] as String),
      familyId: json['familyId'] as String?,
    );
  }

  Map<String, dynamic> toStorageJson() => {
    'id': id,
    'email': email,
    'role': role.apiValue,
    'token': token,
    'tokenExpiresAt': tokenExpiresAt.toIso8601String(),
    if (familyId != null) 'familyId': familyId,
  };
}
