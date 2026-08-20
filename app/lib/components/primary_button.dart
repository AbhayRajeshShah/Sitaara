import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Solid rounded call-to-action button with a trailing icon, used across
/// the sign-in, child-details, and role-selection screens.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
    this.backgroundColor = AppColors.primary,
    this.borderRadius = 12,
    this.enabled = true,
    this.boldLabel = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
  final Color backgroundColor;
  final double borderRadius;
  final bool enabled;
  final bool boldLabel;

  @override
  Widget build(BuildContext context) {
    final textStyle = boldLabel ? AppTypography.buttonBold : AppTypography.button;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: enabled ? onPressed : null,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: textStyle),
                const SizedBox(width: 8),
                Icon(icon, size: 14, color: textStyle.color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
