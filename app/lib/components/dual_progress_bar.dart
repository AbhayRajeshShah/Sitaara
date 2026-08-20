import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rounded progress track showing the current user's progress as a filled
/// bar plus a thin marker for the partner's progress, as seen on the Home
/// Dashboard "Currently watching" card.
class DualProgressBar extends StatelessWidget {
  const DualProgressBar({
    super.key,
    required this.userProgress,
    this.partnerProgress,
    this.height = 12,
  });

  /// 0..1
  final double userProgress;

  /// 0..1, optional marker for partner progress.
  final double? partnerProgress;

  final double height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return SizedBox(
          height: height,
          width: width,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.neutralBorder,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: userProgress.clamp(0, 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.progressGreen,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
              if (partnerProgress != null)
                Positioned(
                  left: (width * partnerProgress!.clamp(0, 1)).clamp(0, width - 4),
                  child: Container(
                    width: 4,
                    height: height,
                    decoration: BoxDecoration(
                      color: AppColors.deepPurple,
                      borderRadius: BorderRadius.circular(9999),
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
