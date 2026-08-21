import 'package:flutter/foundation.dart' show debugPrint;

import '../config/api_config.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'auth_storage.dart';
import 'masterclass_service.dart';
import 'user_service.dart';
import 'watch_progress_store.dart';

/// Minimal static service locator — this app has no other cross-cutting
/// state yet, so a DI package would be overkill. Call [init] once before
/// `runApp`.
class AppServices {
  AppServices._();

  static late final AuthStorage storage;
  static late final ApiClient api;
  static late final AuthService auth;
  static late final MasterclassService masterclasses;
  static late final UserService users;
  static late final WatchProgressStore watchProgress;

  /// Result of the startup `/health` check — read by [MainApp] to show a
  /// banner when the backend wasn't reachable at launch.
  static bool serverReachable = true;

  static Future<void> init() async {
    storage = AuthStorage();
    watchProgress = WatchProgressStore();
    auth = AuthService(
      ApiClient(baseUrl: ApiConfig.baseUrl, tokenProvider: () => storage.readToken(), onUnauthorized: () {}),
      storage,
      watchProgress,
    );
    api = ApiClient(
      baseUrl: ApiConfig.baseUrl,
      tokenProvider: () => storage.readToken(),
      onUnauthorized: () => auth.handleUnauthorized(),
    );
    masterclasses = MasterclassService(api);
    users = UserService(api);

    serverReachable = await api.checkHealth();
    debugPrint(
      serverReachable
          ? '[Sitaara] Backend reachable at ${ApiConfig.baseUrl}'
          : '[Sitaara] Backend UNREACHABLE at ${ApiConfig.baseUrl}',
    );

    await auth.restoreSession();
  }
}
