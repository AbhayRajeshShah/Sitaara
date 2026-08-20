import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../components/app_text_field.dart';
import '../../components/primary_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _obscurePassword = true;

  void _continue() {
    Navigator.of(context).pushNamed('/child-details');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -66,
              right: -20,
              child: _DecorativeBlurCircle(size: 156, color: AppColors.decorativePurpleBlur),
            ),
            Positioned(
              bottom: -66,
              left: -20,
              child: _DecorativeBlurCircle(size: 117, color: AppColors.decorativeGreenBlur),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 4)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 8,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.primary, AppColors.accentGreen],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome Back',
                                textAlign: TextAlign.center,
                                style: AppTypography.heading1,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Continue your parenting journey',
                                textAlign: TextAlign.center,
                                style: AppTypography.body,
                              ),
                              const SizedBox(height: 32),
                              AppTextField(
                                label: 'Email Address',
                                hint: 'hello@example.com',
                                leadingIcon: Icons.mail_outline_rounded,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Password',
                                hint: '••••••••',
                                leadingIcon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                trailingIcon: _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onTrailingIconTap: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              const SizedBox(height: 24),
                              PrimaryButton(label: 'Log In', onPressed: _continue),
                              const SizedBox(height: 24),
                              Center(
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: AppTypography.labelSmall,
                                    children: [
                                      const TextSpan(text: 'New to Parenting Masterclass? '),
                                      TextSpan(
                                        text: 'Sign up',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.deepPurple,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        recognizer: TapGestureRecognizer()..onTap = _continue,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeBlurCircle extends StatelessWidget {
  const _DecorativeBlurCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
