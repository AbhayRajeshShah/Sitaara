import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shared top app bar: a leading menu/back icon, a centered-ish Quicksand
/// title, and an optional trailing circular avatar placeholder.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.leadingIcon = Icons.menu,
    this.onLeadingTap,
    this.showAvatar = false,
    this.titleFontSize = 20,
  });

  final String title;
  final IconData leadingIcon;
  final VoidCallback? onLeadingTap;
  final bool showAvatar;
  final double titleFontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.pageBg,
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(leadingIcon, color: AppColors.deepPurple),
              onPressed: onLeadingTap,
            ),
            Expanded(
              child: Text(
                title,
                style: AppTypography.heading2.copyWith(fontSize: titleFontSize),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showAvatar)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.lightPurpleBg, width: 2),
                    color: AppColors.iconCircleBg,
                  ),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 20),
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
