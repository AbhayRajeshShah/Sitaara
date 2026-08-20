import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Icon + Quicksand heading row used for dashboard/lesson section titles
/// ("Currently watching", "Available Masterclasses", "Course Content").
class SectionHeading extends StatelessWidget {
  const SectionHeading({super.key, required this.icon, required this.title, this.overline = false});

  final IconData icon;
  final String title;
  final bool overline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.deepPurple),
        const SizedBox(width: 8),
        Text(
          title,
          style: overline
              ? AppTypography.overline
              : AppTypography.heading3,
        ),
      ],
    );
  }
}
