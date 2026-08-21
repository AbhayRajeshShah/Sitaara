import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  /// The Go backend listens on :8080 (see backend/docs/openapi.yaml).
  /// Android emulators can't reach the host's `localhost` directly, so they
  /// use the special `10.0.2.2` alias instead. A physical Android device
  /// needs `adb reverse tcp:8080 tcp:8080` and must hit `localhost` (not
  /// `10.0.2.2`, which is meaningless outside the emulator) — pass
  /// `--dart-define=API_HOST=localhost` when running on real hardware.
  static const String _apiHost = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'http://localhost:8080',
  );

  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return _apiHost;
    }
    return _apiHost;
  }
}
