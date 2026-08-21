import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../components/app_bottom_nav_bar.dart';
import '../../components/app_text_field.dart';
import '../../components/app_top_bar.dart';
import '../../components/primary_button.dart';
import '../../models/invite_code.dart';
import '../../services/api_client.dart';
import '../../services/app_services.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class PartnerLinkScreen extends StatefulWidget {
  const PartnerLinkScreen({super.key});

  @override
  State<PartnerLinkScreen> createState() => _PartnerLinkScreenState();
}

class _PartnerLinkScreenState extends State<PartnerLinkScreen> {
  bool _loading = true;
  String? _statusError;
  bool _isConnected = false;

  int _tabIndex = 0;

  bool _inviteLoading = true;
  String? _inviteError;
  InviteCode? _activeInvite;
  bool _generating = false;

  final _codeController = TextEditingController();
  String? _joinError;
  bool _joining = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _statusError = null;
    });
    try {
      final status = await AppServices.partner.getStatus();
      if (!mounted) return;
      setState(() => _isConnected = status.isConnected);
      if (!status.isConnected) {
        unawaited(_loadActiveInvite());
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _statusError = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadActiveInvite() async {
    setState(() {
      _inviteLoading = true;
      _inviteError = null;
    });
    try {
      final invite = await AppServices.partner.getActiveInviteCode();
      if (!mounted) return;
      setState(() => _activeInvite = invite);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _inviteError = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _inviteLoading = false);
    }
  }

  Future<void> _generateInvite() async {
    setState(() {
      _generating = true;
      _inviteError = null;
    });
    try {
      final invite = await AppServices.partner.generateInviteCode();
      if (!mounted) return;
      setState(() => _activeInvite = invite);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _inviteError = friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _submitJoin() async {
    final code = _codeController.text.trim();
    setState(() => _joinError = code.isEmpty ? 'Enter an invite code' : null);
    if (_joinError != null) return;

    setState(() => _joining = true);
    try {
      await AppServices.partner.redeem(code);
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _joining = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _joinError = friendlyAuthError(e);
        _joining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppTopBar(
        title: 'Partner',
        leadingIcon: Icons.menu,
        onLeadingTap: () => Navigator.of(context).maybePop(),
        showAvatar: true,
      ),
      bottomNavigationBar: AppBottomNavBar(
        activeTab: AppNavTab.partner,
        onHomeTap: () => Navigator.of(context).pushReplacementNamed('/home'),
        onProfileTap: () =>
            Navigator.of(context).pushReplacementNamed('/profile'),
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
              : _statusError != null
              ? _ErrorState(message: _statusError!, onRetry: _load)
              : _isConnected
              ? const _SyncedView()
              : _buildLinkTabs(),
        ),
      ),
    );
  }

  Widget _buildLinkTabs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TabSwitcher(
          index: _tabIndex,
          labels: const ['Invite', 'Join'],
          onChanged: (i) => setState(() => _tabIndex = i),
        ),
        const SizedBox(height: 24),
        if (_tabIndex == 0) _buildInviteTab() else _buildJoinTab(),
      ],
    );
  }

  Widget _buildInviteTab() {
    if (_inviteLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_inviteError != null) {
      return _ErrorState(message: _inviteError!, onRetry: _loadActiveInvite);
    }

    final invite = _activeInvite;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: invite == null
          ? [
              Text(
                "You don't have any active invite codes.",
                style: AppTypography.label,
              ),
              const SizedBox(height: 4),
              Text(
                'Generate one to invite your partner.',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.bodyText,
                ),
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Generate Invite Code',
                icon: Icons.add_link_rounded,
                loading: _generating,
                onPressed: _generateInvite,
              ),
            ]
          : [
              Text(
                'Share this code with your partner',
                style: AppTypography.label,
              ),
              const SizedBox(height: 12),
              _CodeCard(code: invite.code),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Generate New Code',
                icon: Icons.refresh_rounded,
                backgroundColor: AppColors.deepPurple,
                loading: _generating,
                onPressed: _generateInvite,
              ),
            ],
    );
  }

  Widget _buildJoinTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Enter your partner's invite code", style: AppTypography.label),
        const SizedBox(height: 4),
        Text(
          "You'll leave your current setup and join theirs.",
          style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText),
        ),
        const SizedBox(height: 16),
        AppTextField(
          label: 'Invite Code',
          hint: 'HAVE A CODE?',
          controller: _codeController,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          textInputAction: TextInputAction.done,
          errorText: _joinError,
          borderRadius: 8,
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Join',
          icon: Icons.link_rounded,
          loading: _joining,
          onPressed: _submitJoin,
        ),
      ],
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.index,
    required this.labels,
    required this.onChanged,
  });

  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: AppColors.neutralBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(9999),
                onTap: () => onChanged(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    labels[i],
                    style: AppTypography.label.copyWith(
                      color: i == index
                          ? AppColors.navPillText
                          : AppColors.bodyText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SyncedView extends StatelessWidget {
  const _SyncedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.deepPurple,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "You're synced with your partner!",
              textAlign: TextAlign.center,
              style: AppTypography.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              'You can both see shared progress and activity.',
              textAlign: TextAlign.center,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.bodyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  const _CodeCard({required this.code});

  final String code;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Code copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.neutralBorder),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: AppTypography.heading2.copyWith(letterSpacing: 4),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: AppColors.deepPurple),
            onPressed: () => _copy(context),
          ),
        ],
      ),
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
          Text("Couldn't load partner info", style: AppTypography.label),
          const SizedBox(height: 4),
          Text(
            message,
            style: AppTypography.labelSmall.copyWith(color: AppColors.bodyText),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
