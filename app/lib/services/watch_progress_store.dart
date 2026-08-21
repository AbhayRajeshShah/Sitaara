import 'package:shared_preferences/shared_preferences.dart';

/// Local cache of `videoId -> watchedSeconds`, keyed per-video. This is the
/// durability floor for watch-progress reporting: the lesson player writes
/// here on every progress tick/flush *before* attempting the network call,
/// so a value survives even if the app is killed before the backend sync
/// completes, and can be reconciled (re-sent) next time that video opens.
class WatchProgressStore {
  static const _keyPrefix = 'watch_progress_';

  Future<int?> read(String videoId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_keyPrefix$videoId');
  }

  Future<void> write(String videoId, int watchedSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_keyPrefix$videoId', watchedSeconds);
  }

  /// Wipes every cached watch position. Called on sign-out (and forced
  /// logout) so a previously signed-in user's progress can't leak into the
  /// next session on this device.
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_keyPrefix));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
