import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../components/app_bottom_nav_bar.dart';
import '../../components/app_top_bar.dart';
import '../../components/dual_progress_bar.dart';
import '../../components/image_placeholder.dart';
import '../../components/primary_button.dart';
import '../../models/masterclass_detail.dart';
import '../../models/parent_role.dart';
import '../../models/video_member_activity.dart';
import '../../services/api_client.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

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

/// Decorative mock like/watch-progress data, keyed by video position rather
/// than a fixed title, since the real likes/watch-progress APIs don't exist
/// on the backend yet (see plan). Cycles through a few states so the range
/// of UI treatments is visible across a real video list of any length.
List<VideoMemberActivity> _mockMembersFor(int index, int durationSeconds) {
  switch (index % 4) {
    case 0:
      return [
        VideoMemberActivity(
          role: ParentRole.dad,
          isYou: true,
          liked: true,
          watchedSeconds: (durationSeconds * 0.33).round(),
        ),
        VideoMemberActivity(
          role: ParentRole.mom,
          isYou: false,
          liked: true,
          watchedSeconds: (durationSeconds * 0.55).round(),
        ),
      ];
    case 1:
      return [
        VideoMemberActivity(role: ParentRole.dad, isYou: true, liked: false, watchedSeconds: durationSeconds),
        VideoMemberActivity(role: ParentRole.mom, isYou: false, liked: true, watchedSeconds: durationSeconds),
      ];
    case 2:
      return [
        VideoMemberActivity(role: ParentRole.dad, isYou: true, liked: true, watchedSeconds: durationSeconds),
        VideoMemberActivity(role: ParentRole.mom, isYou: false, liked: false, watchedSeconds: 0),
      ];
    default:
      return [
        VideoMemberActivity(role: ParentRole.dad, isYou: true, liked: false, watchedSeconds: 0),
        VideoMemberActivity(role: ParentRole.mom, isYou: false, liked: false, watchedSeconds: 0),
      ];
  }
}

String _formatDuration(Duration d) {
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

class LessonPlayerScreen extends StatefulWidget {
  const LessonPlayerScreen({super.key});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  bool _argsRead = false;
  String? _masterclassId;
  String? _titleFallback;

  MasterclassDetail? _detail;
  bool _loading = true;
  String? _error;

  int _selectedIndex = 0;
  VideoPlayerController? _controller;
  String? _videoError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_argsRead) return;
    _argsRead = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map) {
      _masterclassId = args['masterclassId'] as String?;
      _titleFallback = args['title'] as String?;
    }
    _load();
  }

  Future<void> _load() async {
    final id = _masterclassId;
    if (id == null) {
      setState(() {
        _loading = false;
        _error = 'No masterclass selected.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await AppServices.masterclasses.getDetail(id);
      if (!mounted) return;
      setState(() => _detail = detail);
      if (detail.videos.isNotEmpty) {
        await _selectVideo(0, autoplay: false);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _selectVideo(int index, {required bool autoplay}) async {
    final detail = _detail;
    if (detail == null) return;
    final video = detail.videos[index];

    final oldController = _controller;
    setState(() {
      _selectedIndex = index;
      _controller = null;
      _videoError = null;
    });
    await oldController?.dispose();

    final controller = VideoPlayerController.networkUrl(Uri.parse(video.videoUrl));
    try {
      await controller.initialize();
      if (autoplay) await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _videoError = "Couldn't load this video.");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _detail?.title ?? _titleFallback ?? 'Parenting Masterclass';

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
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final detail = _detail;
    if (detail == null || detail.videos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: Text("This masterclass doesn't have any videos yet.")),
      );
    }

    final current = detail.videos[_selectedIndex];
    final likedByLabel = _likedByLabel(_mockMembersFor(_selectedIndex, current.durationSeconds));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VideoPlayer(
          controller: _controller,
          videoError: _videoError,
          onRetry: () => _selectVideo(_selectedIndex, autoplay: false),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(current.title, style: AppTypography.heading3)),
            IconButton(
              icon: const Icon(Icons.favorite, color: AppColors.deepPurple),
              onPressed: () {},
            ),
          ],
        ),
        if (likedByLabel != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.deepPurple, size: 16),
              const SizedBox(width: 4),
              Text(likedByLabel, style: AppTypography.label),
            ],
          ),
        ],
        const SizedBox(height: 24),
        const Divider(color: AppColors.neutralBorder),
        const SizedBox(height: 16),
        Text('COURSE CONTENT', style: AppTypography.overline.copyWith(letterSpacing: 0.7)),
        const SizedBox(height: 8),
        for (var i = 0; i < detail.videos.length; i++) ...[
          _CourseItem(
            video: detail.videos[i],
            index: i,
            isPlaying: i == _selectedIndex,
            onTap: () {
              if (i != _selectedIndex) _selectVideo(i, autoplay: true);
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Couldn't load this masterclass", style: AppTypography.label),
          const SizedBox(height: 4),
          Text(message, style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText)),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _VideoPlayer extends StatelessWidget {
  const _VideoPlayer({required this.controller, required this.videoError, required this.onRetry});

  final VideoPlayerController? controller;
  final String? videoError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    return AspectRatio(
      aspectRatio: controller != null && controller.value.isInitialized
          ? controller.value.aspectRatio
          : 358 / 201,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 10))],
        ),
        clipBehavior: Clip.antiAlias,
        child: videoError != null
            ? _VideoErrorState(message: videoError!, onRetry: onRetry)
            : controller == null
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _VideoPlayerContent(controller: controller),
      ),
    );
  }
}

class _VideoErrorState extends StatelessWidget {
  const _VideoErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry', style: TextStyle(color: AppColors.lightPurpleBg)),
          ),
        ],
      ),
    );
  }
}

class _VideoPlayerContent extends StatelessWidget {
  const _VideoPlayerContent({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final position = value.position;
        final duration = value.duration;
        final progress = duration.inMilliseconds == 0
            ? 0.0
            : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
        return GestureDetector(
          onTap: () => value.isPlaying ? controller.pause() : controller.play(),
          child: Stack(
            fit: StackFit.expand,
            children: [
              VideoPlayer(controller),
              Center(
                child: AnimatedOpacity(
                  opacity: value.isPlaying ? 0 : 1,
                  duration: const Duration(milliseconds: 150),
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
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation(AppColors.lightPurpleBg),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CourseItem extends StatelessWidget {
  const _CourseItem({required this.video, required this.index, required this.isPlaying, required this.onTap});

  final VideoSummary video;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final members = _mockMembersFor(index, video.durationSeconds);
    final likedByLabel = _likedByLabel(members);
    final partnerWatching = _partnerCurrentlyWatching(members, video.durationSeconds);
    final partner = _partner(members);
    final yourMember = members.firstWhere((m) => m.isYou);
    final completed = !isPlaying && yourMember.watchedSeconds >= video.durationSeconds;
    final hasProgress = members.any((m) => m.watchedSeconds > 0);
    final durationLabel = _formatDuration(Duration(seconds: video.durationSeconds));
    final metaColor = completed
        ? AppColors.completedGreen
        : isPlaying
        ? const Color(0xCC30127A)
        : AppColors.bodyText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: isPlaying ? AppColors.activeItemBg : AppColors.pageBg,
            border: Border.all(color: isPlaying ? AppColors.activeItemBorder : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 80,
                    height: 56,
                    child: ImagePlaceholder(icon: Icons.image_outlined, borderRadius: 8, iconSize: 20),
                  ),
                  if (isPlaying) const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isPlaying)
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
                      video.title,
                      style: isPlaying
                          ? AppTypography.label.copyWith(
                              color: AppColors.deepPurple,
                              fontWeight: FontWeight.w700,
                            )
                          : AppTypography.label,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          completed ? Icons.check_circle_rounded : Icons.access_time_rounded,
                          size: 12,
                          color: metaColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          completed ? 'Completed' : durationLabel,
                          style: AppTypography.labelSmall.copyWith(color: metaColor),
                        ),
                        if (partnerWatching) ...[
                          const SizedBox(width: 6),
                          Text('•', style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText)),
                          const SizedBox(width: 6),
                          const Icon(Icons.remove_red_eye_outlined, size: 12, color: AppColors.bodyText),
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
                          const Icon(Icons.favorite, size: 11, color: AppColors.bodyText),
                          const SizedBox(width: 4),
                          Text(
                            likedByLabel,
                            style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText),
                          ),
                        ],
                      ),
                    ],
                    if (hasProgress) ...[
                      const SizedBox(height: 6),
                      DualProgressBar(
                        height: 4,
                        userProgress: (yourMember.watchedSeconds / video.durationSeconds).clamp(0, 1),
                        partnerProgress: partner == null
                            ? null
                            : (partner.watchedSeconds / video.durationSeconds).clamp(0, 1),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
