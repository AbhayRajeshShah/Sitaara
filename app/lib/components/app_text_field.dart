import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Labeled text input matching the Figma input style: light grey fill,
/// rounded border, and an optional leading/trailing icon.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.leadingIcon,
    this.trailingIcon,
    this.onTrailingIconTap,
    this.obscureText = false,
    this.borderRadius = 12,
    this.textAlign = TextAlign.start,
    this.controller,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final VoidCallback? onTrailingIconTap;
  final bool obscureText;
  final double borderRadius;
  final TextAlign textAlign;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(label, style: AppTypography.labelSmall),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          textAlign: textAlign,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          enabled: enabled,
          style: AppTypography.body.copyWith(color: AppColors.headingText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.body.copyWith(color: AppColors.placeholderText),
            errorText: errorText,
            filled: true,
            fillColor: AppColors.inputBg,
            prefixIcon: leadingIcon != null
                ? Icon(leadingIcon, size: 20, color: AppColors.bodyText)
                : null,
            suffixIcon: trailingIcon != null
                ? IconButton(
                    icon: Icon(trailingIcon, size: 20, color: AppColors.bodyText),
                    onPressed: onTrailingIconTap,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
