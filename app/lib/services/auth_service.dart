import '../models/auth_session.dart';
import '../models/parent_role.dart';
import 'api_client.dart';
import 'auth_storage.dart';

/// Auth-specific endpoints on top of [ApiClient]/[AuthStorage]: sign in,
/// sign up, session restore/sign-out, and a shared error-message mapping.
class AuthService {
  AuthService(this._client, this._storage);

  final ApiClient _client;
  final AuthStorage _storage;

  AuthSession? _currentSession;
  AuthSession? get currentSession => _currentSession;

  Future<AuthSession> signIn({required String email, required String password}) async {
    final json = await _client.post(
      '/auth/signin',
      body: {'email': email, 'password': password},
      auth: false,
    );
    final session = AuthSession.fromSignInJson(json as Map<String, dynamic>);
    await _storage.saveSession(session);
    _currentSession = session;
    return session;
  }

  Future<AuthSession> signUp({
    required String email,
    required String password,
    required ParentRole role,
    String? inviteCode,
    String? childName,
    String? childDob,
  }) async {
    final body = <String, dynamic>{'email': email, 'password': password, 'role': role.apiValue};
    if (inviteCode != null) body['inviteCode'] = inviteCode;
    if (childName != null) body['childName'] = childName;
    if (childDob != null) body['childDob'] = childDob;

    final json = await _client.post('/users', body: body, auth: false);
    final session = AuthSession.fromCreateUserJson(json as Map<String, dynamic>);
    await _storage.saveSession(session);
    _currentSession = session;
    return session;
  }

  Future<AuthSession?> restoreSession() async {
    _currentSession = await _storage.readSession();
    return _currentSession;
  }

  Future<void> signOut() async {
    _currentSession = null;
    await _storage.clear();
  }

  /// Called by [ApiClient.onUnauthorized] when a stored token is dead.
  void handleUnauthorized() {
    _currentSession = null;
    _storage.clear();
  }
}

/// Maps known backend error codes to user-facing copy; falls back to the
/// backend's own message for anything unmapped (e.g. `invalid_request`,
/// whose message is already human-readable).
String friendlyAuthError(ApiException e) {
  switch (e.code) {
    case 'invalid_credentials':
      return 'Invalid email or password.';
    case 'email_already_registered':
      return 'That email is already registered.';
    case 'invite_not_found':
      return "That invite code wasn't found.";
    case 'invite_already_used':
      return 'That invite code has already been used.';
    case 'family_has_two_parents':
      return 'This family already has two parents linked.';
    case 'family_already_has_role':
      return e.message;
    case 'network_error':
      return e.message;
    case 'internal_error':
      return 'Something went wrong. Please try again.';
    default:
      return e.message;
  }
}
