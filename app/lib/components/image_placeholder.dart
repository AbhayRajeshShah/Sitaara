import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Stand-in for a photo/video/avatar slot that in the design is a real
/// image. No image data/network fetching in this iteration, so this
/// renders a soft tinted rectangle with a centered icon instead.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({
    super.key,
    this.icon = Icons.image_outlined,
    this.borderRadius = 0,
    this.iconSize = 32,
  });

  final IconData icon;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lightPurpleBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: AppColors.primary.withValues(alpha: 0.4)),
    );
  }
}
