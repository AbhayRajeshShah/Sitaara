import 'package:flutter/material.dart';

import '../../components/app_bottom_nav_bar.dart';
import '../../components/app_top_bar.dart';
import '../../components/dual_progress_bar.dart';
import '../../components/image_placeholder.dart';
import '../../components/masterclass_card.dart';
import '../../components/section_heading.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  void _openLesson(BuildContext context) {
    Navigator.of(context).pushNamed('/lesson-player');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppTopBar(
        title: 'Parenting Masterclass',
        leadingIcon: Icons.menu,
        showAvatar: true,
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
            const SectionHeading(icon: Icons.play_circle_outline_rounded, title: 'Currently watching'),
            const SizedBox(height: 16),
            _CurrentlyWatchingCard(onTap: () => _openLesson(context)),
            const SizedBox(height: 32),
            const SectionHeading(icon: Icons.school_outlined, title: 'Available Masterclasses'),
            const SizedBox(height: 16),
            MasterclassCard(
              title: 'The Fourth Trimester',
              description:
                  'Navigating the first 12 weeks with confidence and calm. Essential skills for new parents.',
              duration: '2h 15m',
              lessonCount: '8 Lessons',
              badgeLabel: 'New',
              onTap: () => _openLesson(context),
            ),
            const SizedBox(height: 16),
            MasterclassCard(
              title: 'Picky Eaters',
              description: 'Transform mealtime battles into peaceful bonding.',
              duration: '1h 45m',
              thumbnailHeight: 128,
              onTap: () => _openLesson(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentlyWatchingCard extends StatelessWidget {
  const _CurrentlyWatchingCard({required this.onTap});

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
              BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 4)),
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
                    Text('Toddler Tantrums 101', style: AppTypography.heading4),
                    const SizedBox(height: 8),
                    Text('Module 3: De-escalation Techniques', style: AppTypography.body),
                    const SizedBox(height: 8),
                    const DualProgressBar(userProgress: 0.65, partnerProgress: 0.85),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('65% Complete', style: AppTypography.labelSmall),
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, size: 14, color: AppColors.deepPurple),
                            const SizedBox(width: 4),
                            Text(
                              'Partner at 85%',
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
