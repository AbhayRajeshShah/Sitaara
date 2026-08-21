import 'parent_role.dart';

/// One family member's progress on a masterclass. Mirrors the backend's
/// `MasterclassProgress` schema (`backend/docs/openapi.yaml`).
class MasterclassProgress {
  const MasterclassProgress({
    required this.userId,
    required this.role,
    required this.isYou,
    required this.completedVideos,
    required this.totalVideos,
    required this.percentComplete,
  });

  final String userId;
  final ParentRole role;
  final bool isYou;
  final int completedVideos;
  final int totalVideos;
  final int percentComplete;

  factory MasterclassProgress.fromJson(Map<String, dynamic> json) {
    return MasterclassProgress(
      userId: json['userId'] as String,
      role: ParentRole.fromApiValue(json['role'] as String),
      isYou: json['isYou'] as bool,
      completedVideos: json['completedVideos'] as int,
      totalVideos: json['totalVideos'] as int,
      percentComplete: json['percentComplete'] as int,
    );
  }
}

/// A masterclass with each family member's watch progress. Mirrors the
/// backend's `MasterclassSummary` schema, as returned by `GET /masterclasses`.
class MasterclassSummary {
  const MasterclassSummary({
    required this.id,
    required this.title,
    required this.description,
    required this.totalVideos,
    required this.progress,
  });

  final String id;
  final String title;
  final String? description;
  final int totalVideos;
  final List<MasterclassProgress> progress;

  MasterclassProgress? get yourProgress {
    for (final p in progress) {
      if (p.isYou) return p;
    }
    return null;
  }

  MasterclassProgress? get partnerProgress {
    for (final p in progress) {
      if (!p.isYou) return p;
    }
    return null;
  }

  factory MasterclassSummary.fromJson(Map<String, dynamic> json) {
    return MasterclassSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      totalVideos: json['totalVideos'] as int,
      progress: (json['progress'] as List)
          .map((e) => MasterclassProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
