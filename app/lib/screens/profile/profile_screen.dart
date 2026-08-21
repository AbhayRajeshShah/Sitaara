import 'package:flutter/material.dart';

import '../../components/app_bottom_nav_bar.dart';
import '../../components/app_top_bar.dart';
import '../../components/primary_button.dart';
import '../../components/section_heading.dart';
import '../../models/user_profile.dart';
import '../../services/api_client.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

const _monthNames = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime d) => '${_monthNames[d.month - 1]} ${d.day}, ${d.year}';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await AppServices.users.getMe();
      if (!mounted) return;
      setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppTopBar(
        title: 'Profile',
        leadingIcon: Icons.menu,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        showAvatar: true,
      ),
      bottomNavigationBar: AppBottomNavBar(
        activeTab: AppNavTab.profile,
        onHomeTap: () => Navigator.of(context).pushReplacementNamed('/home'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
              ? _ErrorState(message: _error!, onRetry: _load)
              : _buildContent(_profile!),
        ),
      ),
    );
  }

  Widget _buildContent(UserProfile profile) {
    final child = profile.child;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeading(icon: Icons.badge_outlined, title: 'Account'),
        const SizedBox(height: 16),
        _InfoCard(
          rows: [
            _InfoRow(label: 'Email', value: profile.email),
            _InfoRow(label: 'Role', value: profile.role.label),
            _InfoRow(label: 'Joined', value: _formatDate(profile.createdAt)),
          ],
        ),
        const SizedBox(height: 32),
        const SectionHeading(icon: Icons.family_restroom_rounded, title: 'Child'),
        const SizedBox(height: 16),
        child == null
            ? _InfoCard(rows: const [_InfoRow(label: 'Name', value: 'No child on file')])
            : _InfoCard(
                rows: [
                  _InfoRow(label: 'Name', value: child.name),
                  _InfoRow(label: 'Date of birth', value: _formatDate(child.dateOfBirth)),
                ],
              ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Couldn't load your profile", style: AppTypography.label),
          const SizedBox(height: 4),
          Text(message, style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText)),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Retry', icon: Icons.refresh_rounded, onPressed: onRetry),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.neutralBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const Divider(color: AppColors.neutralBorder, height: 1),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.body.copyWith(color: AppColors.bodyText)),
          Flexible(
            child: Text(
              value,
              style: AppTypography.label,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
