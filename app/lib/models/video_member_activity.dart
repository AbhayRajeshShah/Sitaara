import 'parent_role.dart';

/// One family member's like/watch state for a single video. Mirrors the
/// backend's `VideoMemberActivity` schema (`backend/docs/openapi.yaml`),
/// returned per-video as part of `members` by `GET /masterclasses/{id}`.
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

  factory VideoMemberActivity.fromJson(Map<String, dynamic> json) {
    return VideoMemberActivity(
      role: ParentRole.fromApiValue(json['role'] as String),
      isYou: json['isYou'] as bool,
      liked: json['liked'] as bool,
      watchedSeconds: json['watchedSeconds'] as int,
    );
  }

  VideoMemberActivity copyWith({bool? liked, int? watchedSeconds}) {
    return VideoMemberActivity(
      role: role,
      isYou: isYou,
      liked: liked ?? this.liked,
      watchedSeconds: watchedSeconds ?? this.watchedSeconds,
    );
  }
}
