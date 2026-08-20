import 'package:flutter/material.dart';

import '../../components/app_text_field.dart';
import '../../components/primary_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class ChildDetailsScreen extends StatelessWidget {
  const ChildDetailsScreen({super.key});

  void _continue(BuildContext context) {
    Navigator.of(context).pushNamed('/role-selection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(54),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.pageBg,
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.deepPurple),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Text('Add Child', style: AppTypography.heading2),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -161,
            right: -98,
            child: _blurCircle(800, AppColors.lightPurpleBg.withValues(alpha: 0.3)),
          ),
          Positioned(
            bottom: -161,
            left: -98,
            child: _blurCircle(600, AppColors.accentGreen.withValues(alpha: 0.3)),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 448),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Who are we nurturing?',
                        textAlign: TextAlign.center,
                        style: AppTypography.heading2SemiBold.copyWith(color: AppColors.deepPurple),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Tell us a bit about your little one.",
                        textAlign: TextAlign.center,
                        style: AppTypography.body,
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        label: "Child's Name",
                        hint: 'e.g. Leo',
                        borderRadius: 8,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Date of Birth (or Due Date)',
                        hint: 'mm/dd/yyyy',
                        trailingIcon: Icons.calendar_today_outlined,
                        borderRadius: 8,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Continue',
                        onPressed: () => _continue(context),
                        backgroundColor: AppColors.deepPurple,
                        borderRadius: 16,
                        boldLabel: true,
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: AppTypography.labelSmall.copyWith(letterSpacing: 0.6),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Joining a partner?',
                        textAlign: TextAlign.center,
                        style: AppTypography.label,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter their invite code below.',
                        textAlign: TextAlign.center,
                        style: AppTypography.labelSmall,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Container(
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.inputBg,
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'HAVE A CODE?',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.placeholderText,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: const Color(0xFFE7E8E9),
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () => _continue(context),
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 25),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.border),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Join',
                                  style: AppTypography.label.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
