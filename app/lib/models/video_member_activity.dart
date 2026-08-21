import 'parent_role.dart';

/// One family member's like/watch state for a single video. Mirrors the
/// backend's `VideoMemberActivity` schema (`backend/docs/openapi.yaml`),
/// returned per-video by `GET /masterclasses/{id}` — not wired up yet, so
/// this is currently only used to shape mock data on the lesson player
/// screen ahead of that integration.
class VideoMemberActivity {
  const VideoMemberActivity({
    required this.role,
    required this.isYou,
    required this.liked,
    required this.watchedSeconds,
  });

  final ParentRole role;
  final bool isYou;
  final bool liked;
  final int watchedSeconds;
}
