import 'package:flutter/material.dart';

import '../../components/app_bottom_nav_bar.dart';
import '../../components/app_top_bar.dart';
import '../../components/image_placeholder.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class LessonPlayerScreen extends StatelessWidget {
  const LessonPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppTopBar(
        title: 'Parenting Masterclass',
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
                  Expanded(
                    child: Text(
                      'Understanding Toddler Emotions',
                      style: AppTypography.heading3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_border_rounded, color: AppColors.deepPurple),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                "Learn the foundational steps to recognizing and validating your child's big feelings, "
                'creating a secure base for emotional growth.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.neutralBorder),
              const SizedBox(height: 16),
              Text(
                'COURSE CONTENT',
                style: AppTypography.overline.copyWith(letterSpacing: 0.7),
              ),
              const SizedBox(height: 8),
              _CourseItem(
                title: 'Understanding Toddler Emotions',
                duration: '12:45',
                status: _ItemStatus.playing,
              ),
              const SizedBox(height: 8),
              _CourseItem(
                title: 'Introduction to Emotional Milestones',
                duration: '08:22',
                status: _ItemStatus.completed,
              ),
              const SizedBox(height: 8),
              _CourseItem(
                title: 'The Science of Tantrums',
                duration: '15:10',
                status: _ItemStatus.completed,
              ),
              const SizedBox(height: 8),
              _CourseItem(
                title: 'De-escalation Strategies',
                duration: '10:05',
                status: _ItemStatus.upcoming,
              ),
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
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.8,
              child: ImagePlaceholder(icon: Icons.family_restroom_rounded, iconSize: 40),
            ),
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

enum _ItemStatus { playing, completed, upcoming }

class _CourseItem extends StatelessWidget {
  const _CourseItem({required this.title, required this.duration, required this.status});

  final String title;
  final String duration;
  final _ItemStatus status;

  @override
  Widget build(BuildContext context) {
    final active = status == _ItemStatus.playing;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: active ? AppColors.activeItemBg : AppColors.pageBg,
        border: Border.all(color: active ? AppColors.activeItemBorder : Colors.transparent),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 56,
                child: ImagePlaceholder(
                  icon: Icons.image_outlined,
                  borderRadius: 8,
                  iconSize: 20,
                ),
              ),
              if (status == _ItemStatus.upcoming)
                const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
              if (active)
                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
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
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
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
                  title,
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
                      color: status == _ItemStatus.completed
                          ? AppColors.completedGreen
                          : AppColors.bodyText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status == _ItemStatus.completed
                          ? 'Completed'
                          : status == _ItemStatus.upcoming
                              ? 'Up next'
                              : duration,
                      style: AppTypography.labelSmall.copyWith(
                        color: status == _ItemStatus.completed
                            ? AppColors.completedGreen
                            : status == _ItemStatus.playing
                                ? const Color(0xCC30127A)
                                : AppColors.bodyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
