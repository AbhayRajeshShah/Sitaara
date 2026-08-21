import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../components/app_bottom_nav_bar.dart';
import '../../components/app_top_bar.dart';
import '../../components/dual_progress_bar.dart';
import '../../components/image_placeholder.dart';
import '../../components/primary_button.dart';
import '../../models/masterclass_detail.dart';
import '../../models/video_member_activity.dart';
import '../../services/api_client.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

/// How often to save/report watch progress while a video is playing. See
/// `_flushProgress` for the full set of triggers (this timer is only the
/// steady-state one — completion, video switches, backgrounding, and
/// disposal all flush immediately instead of waiting for this tick).
const _progressTickInterval = Duration(seconds: 10);

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

class _LessonPlayerScreenState extends State<LessonPlayerScreen> with WidgetsBindingObserver {
  bool _argsRead = false;
  String? _masterclassId;
  String? _titleFallback;

  MasterclassDetail? _detail;
  bool _loading = true;
  String? _error;

  int _selectedIndex = 0;
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  String? _videoError;

  Timer? _progressTimer;
  bool _progressFlushedForCurrentVideo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      unawaited(_flushProgress());
    }
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
        await _selectVideo(_nextIncompleteVideoIndex(detail.videos), autoplay: false);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The first video the caller hasn't finished watching, so reopening a
  /// masterclass picks up where they left off instead of always restarting
  /// at index 0. Falls back to the last video if everything's complete.
  int _nextIncompleteVideoIndex(List<VideoSummary> videos) {
    for (var i = 0; i < videos.length; i++) {
      final self = videos[i].members.firstWhere((m) => m.isYou);
      if (self.watchedSeconds < videos[i].durationSeconds) return i;
    }
    return videos.length - 1;
  }

  Future<void> _selectVideo(int index, {required bool autoplay}) async {
    final detail = _detail;
    if (detail == null) return;
    final video = detail.videos[index];

    final oldController = _controller;
    final oldChewieController = _chewieController;
    if (oldController != null && oldController.value.isInitialized) {
      await _flushProgress();
    }
    _progressTimer?.cancel();
    _progressTimer = null;

    setState(() {
      _selectedIndex = index;
      _controller = null;
      _chewieController = null;
      _videoError = null;
    });
    oldChewieController?.dispose();
    await oldController?.dispose();

    final controller = VideoPlayerController.networkUrl(Uri.parse(video.videoUrl));
    try {
      await controller.initialize();

      final durationSeconds = controller.value.duration.inSeconds;
      final resumeSeconds = await _reconcileProgress(video, durationSeconds);
      if (resumeSeconds > 0 && resumeSeconds < durationSeconds) {
        await controller.seekTo(Duration(seconds: resumeSeconds));
      }

      if (autoplay) await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final chewieController = ChewieController(
        videoPlayerController: controller,
        autoPlay: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.lightPurpleBg,
          handleColor: AppColors.lightPurpleBg,
          bufferedColor: Colors.white.withValues(alpha: 0.3),
          backgroundColor: Colors.white.withValues(alpha: 0.2),
        ),
        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [DeviceOrientation.portraitUp],
        systemOverlaysAfterFullScreen: SystemUiOverlay.values,
      );
      setState(() {
        _controller = controller;
        _chewieController = chewieController;
      });
      _progressFlushedForCurrentVideo = false;
      _progressTimer = Timer.periodic(_progressTickInterval, (_) {
        if (_controller?.value.isPlaying ?? false) unawaited(_flushProgress());
      });
      controller.addListener(_onControllerTick);
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _videoError = "Couldn't load this video.");
    }
  }

  /// Detects playback reaching the end of the video and flushes immediately,
  /// so the final position is the true end (not truncated to the last
  /// periodic tick).
  void _onControllerTick() {
    if (_progressFlushedForCurrentVideo) return;
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final position = controller.value.position;
    final duration = controller.value.duration;
    if (duration.inMilliseconds > 0 && position >= duration) {
      _progressFlushedForCurrentVideo = true;
      _progressTimer?.cancel();
      unawaited(_flushProgress());
    }
  }

  /// Compares the locally-cached watch position against the server's, pushes
  /// the local value if it's ahead (covers a prior sync that never made it
  /// to the backend before the app closed), and returns the position
  /// playback should resume from.
  Future<int> _reconcileProgress(VideoSummary video, int durationSeconds) async {
    final serverSeconds = video.members.firstWhere((m) => m.isYou).watchedSeconds;
    final localSeconds = await AppServices.watchProgress.read(video.id) ?? 0;

    if (localSeconds > serverSeconds) {
      try {
        final stored = await AppServices.masterclasses.updateProgress(video.id, localSeconds);
        _updateSelfMember(video.id, (m) => m.copyWith(watchedSeconds: stored));
      } catch (_) {
        // Still offline — the local cache already holds this value and will
        // be retried the next time this video is opened or flushed.
      }
    }

    var resumeSeconds = localSeconds > serverSeconds ? localSeconds : serverSeconds;
    if (resumeSeconds < 0) resumeSeconds = 0;
    if (durationSeconds > 0 && resumeSeconds > durationSeconds) resumeSeconds = durationSeconds;
    return resumeSeconds;
  }

  /// Saves the current playback position locally, then best-effort syncs it
  /// to the backend. Called on a steady 10s timer while playing, and
  /// immediately on video completion, video switch, screen disposal, and app
  /// backgrounding — see `_progressTickInterval`'s doc comment.
  Future<void> _flushProgress() async {
    final controller = _controller;
    final detail = _detail;
    if (controller == null || detail == null || !controller.value.isInitialized) return;
    final video = detail.videos[_selectedIndex];

    final seconds = controller.value.position.inSeconds;
    if (seconds <= 0) return;

    await AppServices.watchProgress.write(video.id, seconds);

    try {
      final stored = await AppServices.masterclasses.updateProgress(video.id, seconds);
      _updateSelfMember(video.id, (m) => m.copyWith(watchedSeconds: stored));
    } catch (_) {
      // Offline or the request failed — the local cache already holds this
      // value, so nothing is lost, just delayed until the next flush.
    }
  }

  /// Re-fetches without the full-screen spinner, so the currently playing
  /// video keeps playing — used by pull-to-refresh to pick up updated
  /// progress/likes/partner activity.
  Future<void> _refresh() async {
    final id = _masterclassId;
    if (id == null) return;
    try {
      final detail = await AppServices.masterclasses.getDetail(id);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _toggleLike(VideoSummary video) async {
    final previousLiked = video.members.firstWhere((m) => m.isYou).liked;
    _updateSelfMember(video.id, (m) => m.copyWith(liked: !previousLiked));

    try {
      final liked = await AppServices.masterclasses.toggleLike(video.id);
      _updateSelfMember(video.id, (m) => m.copyWith(liked: liked));
    } catch (_) {
      _updateSelfMember(video.id, (m) => m.copyWith(liked: previousLiked));
    }
  }

  void _updateSelfMember(String videoId, VideoMemberActivity Function(VideoMemberActivity self) update) {
    final detail = _detail;
    if (!mounted || detail == null) return;
    final index = detail.videos.indexWhere((v) => v.id == videoId);
    if (index == -1) return;
    setState(() {
      final videos = [...detail.videos];
      videos[index] = videos[index].copyWithSelfMember(update);
      _detail = MasterclassDetail(id: detail.id, title: detail.title, description: detail.description, videos: videos);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressTimer?.cancel();
    unawaited(_flushProgress());
    _chewieController?.dispose();
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
        showAvatar: true,
        onAvatarTap: () =>
            Navigator.of(context).pushReplacementNamed('/profile'),
      ),
      bottomNavigationBar: AppBottomNavBar(
        activeTab: null,
        onHomeTap: () => Navigator.of(context).pushReplacementNamed('/home'),
        onPartnerTap: () => Navigator.of(context).pushReplacementNamed('/partner-link'),
        onProfileTap: () => Navigator.of(context).pushReplacementNamed('/profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
    final liked = current.members.firstWhere((m) => m.isYou).liked;
    final likedByLabel = _likedByLabel(current.members);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _VideoPlayer(
          controller: _controller,
          chewieController: _chewieController,
          videoError: _videoError,
          onRetry: () => _selectVideo(_selectedIndex, autoplay: false),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(current.title, style: AppTypography.heading3)),
            IconButton(
              icon: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: liked ? AppColors.deepPurple : AppColors.bodyText,
              ),
              onPressed: () => _toggleLike(current),
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
  const _VideoPlayer({
    required this.controller,
    required this.chewieController,
    required this.videoError,
    required this.onRetry,
  });

  final VideoPlayerController? controller;
  final ChewieController? chewieController;
  final String? videoError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    final chewieController = this.chewieController;
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
            : (controller == null || chewieController == null)
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Chewie(controller: chewieController),
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

class _CourseItem extends StatelessWidget {
  const _CourseItem({required this.video, required this.index, required this.isPlaying, required this.onTap});

  final VideoSummary video;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final members = video.members;
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
