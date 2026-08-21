import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum AppNavTab { home, partner, classes, profile }

/// Pill-style bottom navigation shared by Home Dashboard, Lesson Player,
/// Partner Link, and Profile. Classes is still visual only — no screen
/// exists for it yet.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.activeTab,
    this.onHomeTap,
    this.onPartnerTap,
    this.onProfileTap,
  });

  final AppNavTab activeTab;
  final VoidCallback? onHomeTap;
  final VoidCallback? onPartnerTap;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pageBg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: activeTab == AppNavTab.home,
              onTap: onHomeTap,
            ),
            _NavItem(
              icon: Icons.link_rounded,
              label: 'Partner',
              active: activeTab == AppNavTab.partner,
              onTap: onPartnerTap,
            ),
            _NavItem(
              icon: Icons.school_rounded,
              label: 'Classes',
              active: activeTab == AppNavTab.classes,
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              active: activeTab == AppNavTab.profile,
              onTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.active, this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: active ? AppColors.navPillText : AppColors.bodyText),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: active ? AppColors.navPillText : AppColors.bodyText,
          ),
        ),
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: content,
      ),
    );
  }
}
