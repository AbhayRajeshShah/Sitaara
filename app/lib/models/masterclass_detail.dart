import 'video_member_activity.dart';

/// A single video within a masterclass. Mirrors the backend's
/// `VideoWithActivity` schema (`backend/docs/openapi.yaml`), including
/// per-family-member like/watch-progress activity (`members`).
class VideoSummary {
  const VideoSummary({
    required this.id,
    required this.title,
    required this.durationSeconds,
    required this.videoUrl,
    required this.members,
  });

  final String id;
  final String title;
  final int durationSeconds;
  final String videoUrl;
  final List<VideoMemberActivity> members;

  factory VideoSummary.fromJson(Map<String, dynamic> json) {
    return VideoSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      durationSeconds: json['durationSeconds'] as int,
      videoUrl: json['videoUrl'] as String,
      members: (json['members'] as List).map((e) => VideoMemberActivity.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Returns a copy with [update] applied to the caller's own entry in
  /// [members] (the one with `isYou == true`), leaving other members
  /// untouched. Used to apply optimistic like/progress updates.
  VideoSummary copyWithSelfMember(VideoMemberActivity Function(VideoMemberActivity self) update) {
    return VideoSummary(
      id: id,
      title: title,
      durationSeconds: durationSeconds,
      videoUrl: videoUrl,
      members: members.map((m) => m.isYou ? update(m) : m).toList(),
    );
  }
}

/// A masterclass's videos. Mirrors the backend's `MasterclassDetailResponse`
/// schema, as returned by `GET /masterclasses/{id}`.
class MasterclassDetail {
  const MasterclassDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.videos,
  });

  final String id;
  final String title;
  final String? description;
  final List<VideoSummary> videos;

  factory MasterclassDetail.fromJson(Map<String, dynamic> json) {
    return MasterclassDetail(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      videos: (json['videos'] as List).map((e) => VideoSummary.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
