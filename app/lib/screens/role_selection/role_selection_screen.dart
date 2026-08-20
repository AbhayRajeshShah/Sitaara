import 'package:flutter/material.dart';

import '../../components/primary_button.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

enum ParentRole { father, mother, guardian }

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  ParentRole? _selectedRole;

  void _continue() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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
              const Icon(Icons.auto_awesome_rounded, size: 44, color: AppColors.deepPurple),
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
                label: 'Father',
                selected: _selectedRole == ParentRole.father,
                onTap: () => setState(() => _selectedRole = ParentRole.father),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.face_3_rounded,
                label: 'Mother',
                selected: _selectedRole == ParentRole.mother,
                onTap: () => setState(() => _selectedRole = ParentRole.mother),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.family_restroom_rounded,
                label: 'Guardian',
                selected: _selectedRole == ParentRole.guardian,
                onTap: () => setState(() => _selectedRole = ParentRole.guardian),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Continue',
                onPressed: _continue,
                backgroundColor: const Color(0xFFE1E3E4),
                enabled: _selectedRole != null,
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
