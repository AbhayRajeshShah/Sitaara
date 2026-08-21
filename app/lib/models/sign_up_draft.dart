import 'parent_role.dart';

/// Accumulates sign-up fields as the user moves from Sign In (email/password)
/// through Child Details (child info or invite code) to Role Selection,
/// threaded between screens via route arguments.
class SignUpDraft {
  const SignUpDraft({
    required this.email,
    required this.password,
    this.childName,
    this.childDob,
    this.inviteCode,
    this.role,
  });

  final String email;
  final String password;

  /// Set when creating a new family. Mutually exclusive with [inviteCode].
  final String? childName;

  /// ISO `yyyy-MM-dd`. Mutually exclusive with [inviteCode].
  final String? childDob;

  /// Set when joining an existing family instead of creating one.
  final String? inviteCode;

  final ParentRole? role;

  /// Fills in the "create a new family" path and clears any invite code.
  SignUpDraft withNewChild({required String childName, required String childDob}) {
    return SignUpDraft(
      email: email,
      password: password,
      childName: childName,
      childDob: childDob,
      role: role,
    );
  }

  /// Fills in the "join an existing family" path and clears any child info.
  SignUpDraft withInviteCode(String inviteCode) {
    return SignUpDraft(email: email, password: password, inviteCode: inviteCode, role: role);
  }

  SignUpDraft withRole(ParentRole role) {
    return SignUpDraft(
      email: email,
      password: password,
      childName: childName,
      childDob: childDob,
      inviteCode: inviteCode,
      role: role,
    );
  }
}
