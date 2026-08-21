import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shared top app bar: a centered-ish Quicksand title and an optional
/// trailing circular avatar placeholder. Navigation between screens is
/// handled by the bottom nav bar, so there's no leading menu/back icon.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.showAvatar = false,
    this.titleFontSize = 20,
    this.onAvatarTap,
  });

  final String title;
  final bool showAvatar;
  final double titleFontSize;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTypography.heading2.copyWith(fontSize: titleFontSize),
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(9999),
                  onTap: onAvatarTap,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.lightPurpleBg,
                        width: 2,
                      ),
                      color: AppColors.iconCircleBg,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56);
}
