import 'package:flutter/material.dart';

import '../../components/app_bottom_nav_bar.dart';
import '../../components/app_top_bar.dart';
import '../../components/dual_progress_bar.dart';
import '../../components/image_placeholder.dart';
import '../../models/parent_role.dart';
import '../../models/video_member_activity.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// Mock per-video family activity, shaped like the backend's
/// `VideoMemberActivity` (`backend/docs/openapi.yaml`) so wiring the real
/// `GET /masterclasses/{id}` response later is a data-source swap rather
/// than a UI rewrite.
class _CourseItemData {
  const _CourseItemData({
    required this.title,
    required this.duration,
    required this.durationSeconds,
    required this.status,
    required this.members,
  });

  final String title;
  final String duration;
  final int durationSeconds;
  final _ItemStatus status;
  final List<VideoMemberActivity> members;
}

enum _ItemStatus { playing, completed, upcoming }

/// Nobody liked the video: returns null. Otherwise "Liked by You, Mom" /
/// "Liked by You" / "Liked by Mom", LinkedIn-style.
String? _likedByLabel(List<VideoMemberActivity> members) {
  final names = <String>[];
  for (final m in members) {
    if (!m.liked) continue;
    names.add(m.isYou ? 'You' : m.role.shortLabel);
  }
  if (names.isEmpty) return null;
  return 'Liked by ${names.join(', ')}';
}

VideoMemberActivity? _partner(List<VideoMemberActivity> members) {
  for (final m in members) {
    if (!m.isYou) return m;
  }
  return null;
}

bool _partnerCurrentlyWatching(List<VideoMemberActivity> members, int durationSeconds) {
  final partner = _partner(members);
  if (partner == null) return false;
  return partner.watchedSeconds > 0 && partner.watchedSeconds < durationSeconds;
}

final List<_CourseItemData> _mockCourseItems = [
  _CourseItemData(
    title: 'Understanding Toddler Emotions',
    duration: '12:45',
    durationSeconds: 765,
    status: _ItemStatus.playing,
    members: const [
      VideoMemberActivity(role: ParentRole.dad, isYou: true, liked: true, watchedSeconds: 252),
      VideoMemberActivity(role: ParentRole.mom, isYou: false, liked: true, watchedSeconds: 410),
    ],
  ),
  _CourseItemData(
    title: 'Introduction to Emotional Milestones',
    duration: '08:22',
    durationSeconds: 502,
    status: _ItemStatus.completed,
    members: const [
      VideoMemberActivity(role: ParentRole.dad, isYou: true, liked: false, watchedSeconds: 502),
      VideoMemberActivity(role: ParentRole.mom, isYou: false, liked: true, watchedSeconds: 502),
    ],
  ),
  _CourseItemData(
    title: 'The Science of Tantrums',
    duration: '15:10',
    durationSeconds: 910,
    status: _ItemStatus.completed,
    members: const [
      VideoMemberActivity(role: ParentRole.dad, isYou: true, liked: true, watchedSeconds: 910),
      VideoMemberActivity(role: ParentRole.mom, isYou: false, liked: false, watchedSeconds: 910),
    ],
  ),
  _CourseItemData(
    title: 'De-escalation Strategies',
    duration: '10:05',
    durationSeconds: 605,
    status: _ItemStatus.upcoming,
    members: const [
      VideoMemberActivity(role: ParentRole.dad, isYou: true, liked: false, watchedSeconds: 0),
      VideoMemberActivity(role: ParentRole.mom, isYou: false, liked: false, watchedSeconds: 0),
    ],
  ),
];

class LessonPlayerScreen extends StatelessWidget {
  const LessonPlayerScreen({super.key});

  String? _titleFromArgs(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['title'] is String) return args['title'] as String;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nowPlaying = _mockCourseItems.first;
    final title = _titleFromArgs(context) ?? 'Parenting Masterclass';

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppTopBar(
        title: title,
        leadingIcon: Icons.menu,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        showAvatar: true,
      ),
      bottomNavigationBar: const AppBottomNavBar(activeTab: AppNavTab.classes),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _VideoPlayer(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(nowPlaying.title, style: AppTypography.heading3)),
                  IconButton(
                    icon: const Icon(Icons.favorite, color: AppColors.deepPurple),
                    onPressed: () {},
                  ),
                ],
              ),
              if (_likedByLabel(nowPlaying.members) != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite, color: AppColors.deepPurple, size: 16),
                    const SizedBox(width: 4),
                    Text(_likedByLabel(nowPlaying.members)!, style: AppTypography.label),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const Divider(color: AppColors.neutralBorder),
              const SizedBox(height: 16),
              Text('COURSE CONTENT', style: AppTypography.overline.copyWith(letterSpacing: 0.7)),
              const SizedBox(height: 8),
              for (final item in _mockCourseItems) ...[_CourseItem(item: item), const SizedBox(height: 8)],
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPlayer extends StatelessWidget {
  const _VideoPlayer();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 358 / 201,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: 0.8, child: ImagePlaceholder(icon: Icons.family_restroom_rounded, iconSize: 40)),
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9999),
                      child: LinearProgressIndicator(
                        value: 0.33,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation(AppColors.lightPurpleBg),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('04:12', style: TextStyle(color: Colors.white, fontSize: 12)),
                        Text('12:45', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseItem extends StatelessWidget {
  const _CourseItem({required this.item});

  final _CourseItemData item;

  @override
  Widget build(BuildContext context) {
    final status = item.status;
    final active = status == _ItemStatus.playing;
    final likedByLabel = _likedByLabel(item.members);
    final partnerWatching =
        status != _ItemStatus.upcoming && _partnerCurrentlyWatching(item.members, item.durationSeconds);
    final hasProgress = status != _ItemStatus.upcoming && item.members.any((m) => m.watchedSeconds > 0);
    final partner = _partner(item.members);

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: active ? AppColors.activeItemBg : AppColors.pageBg,
        border: Border.all(color: active ? AppColors.activeItemBorder : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 56,
                child: ImagePlaceholder(icon: Icons.image_outlined, borderRadius: 8, iconSize: 20),
              ),
              if (status == _ItemStatus.upcoming)
                const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
              if (active) const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (active)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      'NOW PLAYING',
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 10,
                        color: AppColors.deepPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                Text(
                  item.title,
                  style: active
                      ? AppTypography.label.copyWith(color: AppColors.deepPurple, fontWeight: FontWeight.w700)
                      : AppTypography.label,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      status == _ItemStatus.completed
                          ? Icons.check_circle_rounded
                          : status == _ItemStatus.upcoming
                          ? Icons.lock_outline_rounded
                          : Icons.access_time_rounded,
                      size: 12,
                      color: status == _ItemStatus.completed ? AppColors.completedGreen : AppColors.bodyText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status == _ItemStatus.completed
                          ? 'Completed'
                          : status == _ItemStatus.upcoming
                          ? 'Up next'
                          : item.duration,
                      style: AppTypography.labelSmall.copyWith(
                        color: status == _ItemStatus.completed
                            ? AppColors.completedGreen
                            : status == _ItemStatus.playing
                            ? const Color(0xCC30127A)
                            : AppColors.bodyText,
                      ),
                    ),
                    if (partnerWatching) ...[
                      const SizedBox(width: 6),
                      Text('•', style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText)),
                      const SizedBox(width: 6),
                      Icon(Icons.remove_red_eye_outlined, size: 12, color: AppColors.bodyText),
                      const SizedBox(width: 4),
                      Text(
                        '${partner!.role.shortLabel} is watching',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText),
                      ),
                    ],
                  ],
                ),
                if (likedByLabel != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.favorite, size: 11, color: AppColors.bodyText),
                      const SizedBox(width: 4),
                      Text(likedByLabel, style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText)),
                    ],
                  ),
                ],
                if (hasProgress) ...[
                  const SizedBox(height: 6),
                  DualProgressBar(
                    height: 4,
                    userProgress:
                        (item.members.firstWhere((m) => m.isYou).watchedSeconds / item.durationSeconds).clamp(
                          0,
                          1,
                        ),
                    partnerProgress: partner == null
                        ? null
                        : (partner.watchedSeconds / item.durationSeconds).clamp(0, 1),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
