import 'package:flutter/foundation.dart' show debugPrint;

import '../config/api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'auth_storage.dart';

/// Minimal static service locator — this app has no other cross-cutting
/// state yet, so a DI package would be overkill. Call [init] once before
/// `runApp`.
class AppServices {
  AppServices._();

  static late final AuthStorage storage;
  static late final ApiClient api;
  static late final AuthService auth;

  /// Result of the startup `/health` check — read by [MainApp] to show a
  /// banner when the backend wasn't reachable at launch.
  static bool serverReachable = true;

  static Future<void> init() async {
    storage = AuthStorage();
    auth = AuthService(
      ApiClient(baseUrl: ApiConfig.baseUrl, tokenProvider: () => storage.readToken(), onUnauthorized: () {}),
      storage,
    );
    api = ApiClient(
      baseUrl: ApiConfig.baseUrl,
      tokenProvider: () => storage.readToken(),
      onUnauthorized: () => auth.handleUnauthorized(),
    );

    serverReachable = await api.checkHealth();
    debugPrint(
      serverReachable
          ? '[Sitaara] Backend reachable at ${ApiConfig.baseUrl}'
          : '[Sitaara] Backend UNREACHABLE at ${ApiConfig.baseUrl}',
    );

    await auth.restoreSession();
  }
}
