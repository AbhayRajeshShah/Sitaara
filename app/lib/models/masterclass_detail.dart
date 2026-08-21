/// A single video within a masterclass. Mirrors the backend's
/// `VideoWithActivity` schema (`backend/docs/openapi.yaml`), minus the
/// `members` field — per-family like/watch-progress activity isn't wired up
/// yet, so it's intentionally left unparsed here.
class VideoSummary {
  const VideoSummary({
    required this.id,
    required this.title,
    required this.durationSeconds,
    required this.videoUrl,
  });

  final String id;
  final String title;
  final int durationSeconds;
  final String videoUrl;

  factory VideoSummary.fromJson(Map<String, dynamic> json) {
    return VideoSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      durationSeconds: json['durationSeconds'] as int,
      videoUrl: json['videoUrl'] as String,
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
