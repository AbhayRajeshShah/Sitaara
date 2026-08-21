import 'package:flutter/material.dart';

import '../../components/app_bottom_nav_bar.dart';
import '../../components/app_top_bar.dart';
import '../../components/dual_progress_bar.dart';
import '../../components/image_placeholder.dart';
import '../../components/masterclass_card.dart';
import '../../components/primary_button.dart';
import '../../components/section_heading.dart';
import '../../models/masterclass.dart';
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
    try {
      final masterclasses = await AppServices.masterclasses.list();
      if (!mounted) return;
      setState(() => _masterclasses = masterclasses);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openLesson(BuildContext context, MasterclassSummary masterclass) {
    Navigator.of(
      context,
    ).pushNamed('/lesson-player', arguments: {'masterclassId': masterclass.id, 'title': masterclass.title});
  }

  Future<void> _showAccountMenu(BuildContext context) async {
    final signOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppServices.auth.currentSession?.email ?? 'Account'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Sign Out')),
        ],
      ),
    );
    if (signOut == true) {
      await AppServices.auth.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  MasterclassSummary? _findInProgress(List<MasterclassSummary>? masterclasses) {
    if (masterclasses == null) return null;
    for (final m in masterclasses) {
      final percent = m.yourProgress?.percentComplete;
      if (percent != null && percent > 0 && percent < 100) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final masterclasses = _masterclasses;
    final inProgress = _findInProgress(masterclasses);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTopBar(
        title: 'Parenting Masterclass',
        leadingIcon: Icons.menu,
        showAvatar: true,
        onAvatarTap: () => _showAccountMenu(context),
      ),
      bottomNavigationBar: AppBottomNavBar(activeTab: AppNavTab.home),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, Test's Dad", style: AppTypography.heading1),
            const SizedBox(height: 8),
            Text('Ready to level up your superpower?', style: AppTypography.bodyLarge),
            const SizedBox(height: 32),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorState(message: _error!, onRetry: _load)
            else ...[
              if (inProgress != null) ...[
                const SectionHeading(icon: Icons.play_circle_outline_rounded, title: 'Currently watching'),
                const SizedBox(height: 16),
                _CurrentlyWatchingCard(
                  title: inProgress.title,
                  subtitle:
                      '${inProgress.yourProgress!.completedVideos} of '
                      '${inProgress.yourProgress!.totalVideos} lessons complete',
                  yourPercent: inProgress.yourProgress!.percentComplete,
                  partnerPercent: inProgress.partnerProgress?.percentComplete,
                  onTap: () => _openLesson(context, inProgress),
                ),
                const SizedBox(height: 32),
              ],
              const SectionHeading(icon: Icons.school_outlined, title: 'Available Masterclasses'),
              const SizedBox(height: 16),
              for (final masterclass in masterclasses!) ...[
                MasterclassCard(
                  title: masterclass.title,
                  description: masterclass.description ?? '',
                  lessonCount: '${masterclass.totalVideos} Lesson${masterclass.totalVideos == 1 ? '' : 's'}',
                  badgeLabel: masterclass.yourProgress?.percentComplete == 100 ? 'Completed' : null,
                  onTap: () => _openLesson(context, masterclass),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ],
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
          Text(message, style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText)),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: onRetry),
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
            boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 4))],
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
                    child: ImagePlaceholder(icon: Icons.family_restroom_rounded, iconSize: 40),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(color: AppColors.deepPurple, shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.heading4),
                    const SizedBox(height: 8),
                    Text(subtitle, style: AppTypography.body),
                    const SizedBox(height: 8),
                    DualProgressBar(
                      userProgress: yourPercent / 100,
                      partnerProgress: partnerPercent == null ? null : partnerPercent! / 100,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$yourPercent% Complete', style: AppTypography.labelSmall),
                        if (partnerPercent != null)
                          Row(
                            children: [
                              const Icon(Icons.favorite_rounded, size: 14, color: AppColors.deepPurple),
                              const SizedBox(width: 4),
                              Text(
                                'Partner at $partnerPercent%',
                                style: AppTypography.labelSmall.copyWith(color: AppColors.deepPurple),
                              ),
                            ],
                          ),
                      ],
                    ),
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
