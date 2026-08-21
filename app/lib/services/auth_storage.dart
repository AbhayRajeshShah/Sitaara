import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';

/// Persists the current [AuthSession] as a single JSON blob in secure
/// storage (Keychain/Keystore on iOS/Android).
class AuthStorage {
  AuthStorage({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'auth_session';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) {
    return _storage.write(key: _sessionKey, value: jsonEncode(session.toStorageJson()));
  }

  Future<AuthSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null) return null;
    return AuthSession.fromStorageJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<String?> readToken() async {
    final session = await readSession();
    return session?.token;
  }

  Future<void> clear() {
    return _storage.delete(key: _sessionKey);
  }
}
