/// The caller's family's invite code. Mirrors the backend's
/// `InviteCodeResponse` schema, as returned by `POST /invite-codes` and
/// `GET /invite-codes/active`.
class InviteCode {
  const InviteCode({required this.code, required this.familyId, required this.createdAt});

  final String code;
  final String familyId;
  final DateTime createdAt;

  factory InviteCode.fromJson(Map<String, dynamic> json) {
    return InviteCode(
      code: json['code'] as String,
      familyId: json['familyId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
