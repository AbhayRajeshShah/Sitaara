import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'image_placeholder.dart';

/// Card used in the "Available Masterclasses" grid: thumbnail, optional
/// badge, title, description, and a meta row (duration / lesson count).
class MasterclassCard extends StatelessWidget {
  const MasterclassCard({
    super.key,
    required this.title,
    required this.description,
    required this.duration,
    this.lessonCount,
    this.badgeLabel,
    this.thumbnailHeight = 160,
    this.onTap,
  });

  final String title;
  final String description;
  final String duration;
  final String? lessonCount;
  final String? badgeLabel;
  final double thumbnailHeight;
  final VoidCallback? onTap;

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
              SizedBox(
                height: thumbnailHeight,
                width: double.infinity,
                child: const ImagePlaceholder(icon: Icons.smart_display_outlined),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (badgeLabel != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          badgeLabel!,
                          style: AppTypography.labelSmall.copyWith(color: AppColors.deepPurple),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(title, style: AppTypography.cardTitle),
                    const SizedBox(height: 8),
                    Text(description, style: AppTypography.body),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 13, color: AppColors.bodyText),
                        const SizedBox(width: 4),
                        Text(duration, style: AppTypography.labelSmall),
                        if (lessonCount != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.menu_book_rounded, size: 13, color: AppColors.bodyText),
                          const SizedBox(width: 4),
                          Text(lessonCount!, style: AppTypography.labelSmall),
                        ],
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
