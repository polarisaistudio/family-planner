import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../utils/invite_code_generator.dart';
import '../providers/family_management_provider.dart';
import '../providers/family_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/services/providers/fcm_provider.dart';

class JoinFamilyPage extends ConsumerStatefulWidget {
  const JoinFamilyPage({super.key});

  @override
  ConsumerState<JoinFamilyPage> createState() => _JoinFamilyPageState();
}

class _JoinFamilyPageState extends ConsumerState<JoinFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _inviteCodeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill name from user profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _nameController.text = user.fullName ?? '';
      }
    });
  }

  @override
  void dispose() {
    _inviteCodeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isJoining = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final inviteCode = _inviteCodeController.text.trim();
      final name = _nameController.text.trim();

      // Get FCM device token
      final fcmService = ref.read(fcmServiceProvider);
      final deviceToken = await fcmService.getToken();

      await ref.read(familyManagementProvider).joinFamily(
            inviteCode,
            name,
            user.email,
            deviceToken: deviceToken,
          );

      if (mounted) {
        // Show success and navigate back
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.successfullyJoinedFamily),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh family members list
        ref.invalidate(familyMembersProvider);

        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToJoinFamily(e.toString().replaceAll('Exception: ', ''))),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.joinFamily),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Icon(
                Icons.family_restroom,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                l10n.joinYourFamily,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                l10n.enterInviteCode,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Invite Code Field
              TextFormField(
                controller: _inviteCodeController,
                decoration: InputDecoration(
                  labelText: l10n.inviteCodeLabel,
                  hintText: l10n.inviteCodePlaceholder,
                  prefixIcon: const Icon(Icons.vpn_key),
                  helperText: l10n.inviteCodeFormat,
                ),
                textCapitalization: TextCapitalization.characters,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                onChanged: (value) {
                  // Auto-format with dash
                  final cleaned = value.replaceAll('-', '').toUpperCase();
                  if (cleaned.length > 4 && !value.contains('-')) {
                    final formatted = '${cleaned.substring(0, 4)}-${cleaned.substring(4)}';
                    _inviteCodeController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterInviteCode;
                  }
                  if (!InviteCodeGenerator.isValidFormat(value)) {
                    return l10n.invalidCodeFormat;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.yourName,
                  prefixIcon: const Icon(Icons.person),
                  helperText: l10n.howFamilySeesYou,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Join Button
              FilledButton.icon(
                onPressed: _isJoining ? null : _handleJoinFamily,
                icon: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.group_add),
                label: Text(_isJoining ? l10n.joiningFamily : l10n.joinFamily),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Info card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            l10n.aboutInviteCodes,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l10n.inviteCodeBullet1}\n'
                        '${l10n.inviteCodeBullet2}\n'
                        '${l10n.inviteCodeBullet3}\n'
                        '${l10n.inviteCodeBullet4}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
