import 'package:flutter/material.dart';

import '../../components/primary_button.dart';
import '../../models/parent_role.dart';
import '../../models/sign_up_draft.dart';
import '../../services/api_client.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  ParentRole? _selectedRole;
  bool _loading = false;

  SignUpDraft _draftFromArgs(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    if (args is SignUpDraft) return args;
    return const SignUpDraft(email: '', password: '');
  }

  Future<void> _continue(BuildContext context) async {
    final role = _selectedRole;
    if (role == null) return;

    final draft = _draftFromArgs(context).withRole(role);
    print(
      (
        email: draft.email,
        password: draft.password,
        role: role,
        inviteCode: draft.inviteCode,
        childName: draft.childName,
        childDob: draft.childDob,
      ).toString(),
    );
    setState(() => _loading = true);
    try {
      await AppServices.auth.signUp(
        email: draft.email,
        password: draft.password,
        role: role,
        inviteCode: draft.inviteCode,
        childName: draft.childName,
        childDob: draft.childDob,
      );
      print('signUp successful');
      if (!context.mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAuthError(e)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 44,
                color: AppColors.deepPurple,
              ),
              const SizedBox(height: 8),
              Text(
                "What's your\nsuperpower?",
                textAlign: TextAlign.center,
                style: AppTypography.displayXl,
              ),
              const SizedBox(height: 16),
              Text(
                'Select your role to help us tailor your\nmasterclass journey.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyLarge,
              ),
              const SizedBox(height: 32),
              _RoleCard(
                icon: Icons.face_rounded,
                label: ParentRole.dad.label,
                selected: _selectedRole == ParentRole.dad,
                onTap: () => setState(() => _selectedRole = ParentRole.dad),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.face_3_rounded,
                label: ParentRole.mom.label,
                selected: _selectedRole == ParentRole.mom,
                onTap: () => setState(() => _selectedRole = ParentRole.mom),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.family_restroom_rounded,
                label: ParentRole.guardian.label,
                selected: _selectedRole == ParentRole.guardian,
                onTap: () =>
                    setState(() => _selectedRole = ParentRole.guardian),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Continue',
                onPressed: () => _continue(context),
                backgroundColor: AppColors.primary,
                enabled: _selectedRole != null,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 34),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.iconCircleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 34, color: AppColors.deepPurple),
              ),
              const SizedBox(height: 16),
              Text(label, style: AppTypography.heading2SemiBold),
            ],
          ),
        ),
      ),
    );
  }
}
