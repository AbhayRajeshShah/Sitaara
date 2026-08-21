import 'dart:async';

import 'package:flutter/material.dart';

import '../../components/app_bottom_nav_bar.dart';
import '../../components/app_top_bar.dart';
import '../../components/dual_progress_bar.dart';
import '../../components/image_placeholder.dart';
import '../../components/masterclass_card.dart';
import '../../components/primary_button.dart';
import '../../components/section_heading.dart';
import '../../models/masterclass.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  List<MasterclassSummary>? _masterclasses;
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _refresh();
    if (mounted) setState(() => _loading = false);
  }

  /// Re-fetches without the full-screen spinner, so existing content stays
  /// visible while it updates — used by pull-to-refresh and by
  /// [_openLesson] on return from the lesson player.
  Future<void> _refresh() async {
    // Fetched separately from the masterclasses list (below) and not tied to
    // `_error`: the greeting it feeds is decorative, so a `/me` hiccup
    // shouldn't block the screen's primary content.
    unawaited(_loadProfile());
    try {
      final masterclasses = await AppServices.masterclasses.list();
      if (!mounted) return;
      setState(() {
        _masterclasses = masterclasses;
        _error = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await AppServices.users.getMe();
      if (!mounted) return;
      setState(() => _profile = profile);
    } on ApiException {
      // Greeting falls back to role-only/generic copy below; not worth
      // surfacing a separate error state for decorative copy.
    }
  }

  Future<void> _openLesson(
    BuildContext context,
    MasterclassSummary masterclass,
  ) async {
    await Navigator.of(context).pushNamed(
      '/lesson-player',
      arguments: {'masterclassId': masterclass.id, 'title': masterclass.title},
    );
    if (!mounted) return;
    _refresh();
  }

  /// Buckets masterclasses into mutually-exclusive Currently Watching /
  /// Partner Up / Available / Completed lists based on
  /// `yourProgress.percentComplete`. "Partner up" pulls out masterclasses
  /// the user hasn't started yet but their partner has, so that nudge
  /// doesn't also show up in "Available".
  ({
    List<MasterclassSummary> inProgress,
    List<MasterclassSummary> partnerAhead,
    List<MasterclassSummary> available,
    List<MasterclassSummary> completed,
  })
  _categorize(List<MasterclassSummary> masterclasses) {
    final inProgress = <MasterclassSummary>[];
    final partnerAhead = <MasterclassSummary>[];
    final available = <MasterclassSummary>[];
    final completed = <MasterclassSummary>[];
    for (final m in masterclasses) {
      final percent = m.yourProgress?.percentComplete;
      final partnerPercent = m.partnerProgress?.percentComplete;
      if (percent == 100) {
        completed.add(m);
      } else if (percent != null && percent > 0) {
        inProgress.add(m);
      } else if (partnerPercent != null && partnerPercent > 0) {
        partnerAhead.add(m);
      } else {
        available.add(m);
      }
    }
    return (
      inProgress: inProgress,
      partnerAhead: partnerAhead,
      available: available,
      completed: completed,
    );
  }

  /// A horizontally-scrollable row of cards, each sized to leave a visible
  /// sliver of the next card (indicating there's more to scroll to), all at
  /// a fixed [height] so every card in the row matches — [height] must be
  /// tall enough to fit [cardBuilder]'s tallest possible content for the
  /// card type being used (see call sites).
  Widget _horizontalCardList<T>({
    required List<T> items,
    required double height,
    required Widget Function(BuildContext context, T item) cardBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = items.length == 1
            ? constraints.maxWidth
            : constraints.maxWidth * 0.78;
        return SizedBox(
          height: height,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  SizedBox(
                    width: cardWidth,
                    child: cardBuilder(context, items[i]),
                  ),
                  if (i != items.length - 1) const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final masterclasses = _masterclasses;
    final buckets = masterclasses == null ? null : _categorize(masterclasses);

    final child = _profile?.child;
    final roleLabel = _profile?.role.shortLabel;
    final greeting = child != null && roleLabel != null
        ? "Welcome, ${child.name}'s $roleLabel"
        : roleLabel != null
        ? 'Welcome, $roleLabel'
        : 'Welcome back';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTopBar(
        title: 'Parenting Masterclass',
        showAvatar: true,
        onAvatarTap: () =>
            Navigator.of(context).pushReplacementNamed('/profile'),
      ),
      bottomNavigationBar: AppBottomNavBar(
        activeTab: AppNavTab.home,
        onPartnerTap: () =>
            Navigator.of(context).pushReplacementNamed('/partner-link'),
        onProfileTap: () =>
            Navigator.of(context).pushReplacementNamed('/profile'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting, style: AppTypography.heading1),
              const SizedBox(height: 8),
              Text(
                'Ready to level up your superpower?',
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 32),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _ErrorState(message: _error!, onRetry: _load)
              else if (buckets != null) ...[
                if (buckets.inProgress.isNotEmpty) ...[
                  const SectionHeading(
                    icon: Icons.play_circle_outline_rounded,
                    title: 'Currently watching',
                  ),
                  const SizedBox(height: 16),
                  _horizontalCardList<MasterclassSummary>(
                    items: buckets.inProgress,
                    height: 385,
                    cardBuilder: (context, m) => _CurrentlyWatchingCard(
                      title: m.title,
                      subtitle:
                          '${m.yourProgress!.completedVideos} of ${m.yourProgress!.totalVideos} lessons complete',
                      yourPercent: m.yourProgress!.percentComplete,
                      partnerPercent: m.partnerProgress?.percentComplete,
                      onTap: () => _openLesson(context, m),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                if (buckets.partnerAhead.isNotEmpty) ...[
                  const SectionHeading(
                    icon: Icons.favorite_rounded,
                    title: 'Partner up',
                  ),
                  const SizedBox(height: 16),
                  _horizontalCardList<MasterclassSummary>(
                    items: buckets.partnerAhead,
                    height: 350,
                    cardBuilder: (context, m) => MasterclassCard(
                      title: m.title,
                      description: m.description ?? '',
                      lessonCount:
                          '${m.totalVideos} Lesson${m.totalVideos == 1 ? '' : 's'}',
                      badgeLabel:
                          '${m.partnerProgress!.role.shortLabel} is '
                          '${m.partnerProgress!.percentComplete}% in',
                      onTap: () => _openLesson(context, m),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                if (buckets.available.isNotEmpty) ...[
                  const SectionHeading(
                    icon: Icons.school_outlined,
                    title: 'Available Masterclasses',
                  ),
                  const SizedBox(height: 16),
                  _horizontalCardList<MasterclassSummary>(
                    items: buckets.available,
                    height: 320,
                    cardBuilder: (context, m) => MasterclassCard(
                      title: m.title,
                      description: m.description ?? '',
                      lessonCount:
                          '${m.totalVideos} Lesson${m.totalVideos == 1 ? '' : 's'}',
                      onTap: () => _openLesson(context, m),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                if (buckets.completed.isNotEmpty) ...[
                  const SectionHeading(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'Completed',
                  ),
                  const SizedBox(height: 16),
                  _horizontalCardList<MasterclassSummary>(
                    items: buckets.completed,
                    height: 350,
                    cardBuilder: (context, m) => MasterclassCard(
                      title: m.title,
                      description: m.description ?? '',
                      lessonCount:
                          '${m.totalVideos} Lesson${m.totalVideos == 1 ? '' : 's'}',
                      badgeLabel: 'Completed',
                      onTap: () => _openLesson(context, m),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
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
          Text("Couldn't load masterclasses", style: AppTypography.label),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

class _CurrentlyWatchingCard extends StatelessWidget {
  const _CurrentlyWatchingCard({
    required this.title,
    required this.subtitle,
    required this.yourPercent,
    required this.partnerPercent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final int yourPercent;
  final int? partnerPercent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.neutralBorder),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 20,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    height: 192,
                    width: double.infinity,
                    child: ImagePlaceholder(
                      icon: Icons.family_restroom_rounded,
                      iconSize: 40,
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: AppTypography.heading4,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: AppTypography.body,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DualProgressBar(
                            userProgress: yourPercent / 100,
                            partnerProgress: partnerPercent == null
                                ? null
                                : partnerPercent! / 100,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$yourPercent% Complete',
                                style: AppTypography.labelSmall,
                              ),
                              if (partnerPercent != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.favorite_rounded,
                                      size: 14,
                                      color: AppColors.deepPurple,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Partner at $partnerPercent%',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.deepPurple,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
