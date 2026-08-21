import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../components/app_text_field.dart';
import '../../components/primary_button.dart';
import '../../models/sign_up_draft.dart';
import '../../services/api_client.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

enum _AuthMode { signIn, signUp }

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  _AuthMode _mode = _AuthMode.signIn;
  bool _obscurePassword = true;
  bool _loading = false;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    setState(() {
      _emailError = email.contains('@') && email.contains('.') ? null : 'Enter a valid email address';
      _passwordError = switch (_mode) {
        _AuthMode.signIn => password.isEmpty ? 'Enter your password' : null,
        _AuthMode.signUp => password.length < 8 ? 'Password must be at least 8 characters' : null,
      };
    });
    return _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    if (!_validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_mode == _AuthMode.signUp) {
      Navigator.of(
        context,
      ).pushNamed('/child-details', arguments: SignUpDraft(email: email, password: password));
      return;
    }

    setState(() => _loading = true);
    try {
      await AppServices.auth.signIn(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } on ApiException catch (e) {
      setState(() => _formError = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _mode = _mode == _AuthMode.signIn ? _AuthMode.signUp : _AuthMode.signIn;
      _formError = null;
      _emailError = null;
      _passwordError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSignUp = _mode == _AuthMode.signUp;
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
                            gradient: LinearGradient(colors: [AppColors.primary, AppColors.accentGreen]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(32, 32, 32, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                isSignUp ? 'Create Account' : 'Welcome Back',
                                textAlign: TextAlign.center,
                                style: AppTypography.heading1,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                isSignUp
                                    ? 'Start your parenting journey'
                                    : 'Continue your parenting journey',
                                textAlign: TextAlign.center,
                                style: AppTypography.body,
                              ),
                              const SizedBox(height: 32),
                              AppTextField(
                                label: 'Email Address',
                                hint: 'hello@example.com',
                                leadingIcon: Icons.mail_outline_rounded,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                errorText: _emailError,
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                label: 'Password',
                                hint: '••••••••',
                                leadingIcon: Icons.lock_outline_rounded,
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                errorText: _passwordError,
                                trailingIcon: _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                onTrailingIconTap: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              if (_formError != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  _formError!,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.labelSmall.copyWith(color: Colors.red.shade700),
                                ),
                              ],
                              const SizedBox(height: 24),
                              PrimaryButton(
                                label: isSignUp ? 'Sign Up' : 'Log In',
                                onPressed: _submit,
                                loading: _loading,
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: AppTypography.labelSmall,
                                    children: [
                                      TextSpan(
                                        text: isSignUp
                                            ? 'Already have an account? '
                                            : 'New to Parenting Masterclass? ',
                                      ),
                                      TextSpan(
                                        text: isSignUp ? 'Log in' : 'Sign up',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.deepPurple,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        recognizer: TapGestureRecognizer()..onTap = _toggleMode,
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
