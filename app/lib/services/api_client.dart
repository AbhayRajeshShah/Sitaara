import 'dart:convert';

import 'package:http/http.dart' as http;

/// Thrown for any non-2xx response or network failure. `code` is the
/// backend's machine-readable `ErrorBody.code` (e.g. `invalid_credentials`)
/// when available, so callers can branch on it instead of string-matching
/// `message`.
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}

/// Thin, generic HTTP client for the Sitaara backend: attaches the bearer
/// token (via [tokenProvider]) to every authenticated request and parses
/// every error response as the backend's uniform `{"error", "code"}` body.
/// This is the one piece any future data call (masterclasses, videos, ...)
/// should reuse instead of hand-rolling `http` calls.
class ApiClient {
  ApiClient({required this.baseUrl, required this.tokenProvider, http.Client? httpClient, this.onUnauthorized})
    : _http = httpClient ?? http.Client();

  final String baseUrl;
  final Future<String?> Function() tokenProvider;
  final http.Client _http;

  /// Invoked when a request comes back 401 with `invalid_token`/`unauthorized`
  /// — the caller (AuthService) uses this to clear the dead stored session.
  final void Function()? onUnauthorized;

  Future<dynamic> get(String path, {bool auth = true}) => _send('GET', path, auth: auth);

  /// Pings `/health` with a short timeout so startup can report reachability
  /// in seconds instead of waiting on the OS's ~30-60s TCP connect timeout.
  Future<bool> checkHealth() async {
    try {
      final response = await _http.get(Uri.parse('$baseUrl/health')).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      // ignore: avoid_print
      print('[Sitaara] checkHealth failed: $e');
      return false;
    }
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> _send(String method, String path, {Map<String, dynamic>? body, bool auth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (auth) {
      final token = await tokenProvider();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }

    final uri = Uri.parse('$baseUrl$path');
    http.Response response;
    try {
      response = switch (method) {
        'GET' => await _http.get(uri, headers: headers),
        'POST' => await _http.post(uri, headers: headers, body: body != null ? jsonEncode(body) : null),
        _ => throw UnsupportedError('Unsupported method: $method'),
      };
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not reach the server. Check your connection.', code: 'network_error');
    }

    final dynamic decoded = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final errorJson = decoded is Map<String, dynamic> ? decoded : const <String, dynamic>{};
    final code = errorJson['code'] as String?;
    if (response.statusCode == 401 && (code == 'unauthorized' || code == 'invalid_token')) {
      onUnauthorized?.call();
    }
    throw ApiException(
      errorJson['error'] as String? ?? 'Something went wrong.',
      code: code,
      statusCode: response.statusCode,
    );
  }
}
