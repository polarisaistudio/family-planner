import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/family_entity.dart';
import '../providers/family_management_provider.dart';
import '../providers/family_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/services/providers/fcm_provider.dart';
import 'package:share_plus/share_plus.dart';

class CreateFamilyDialog extends ConsumerStatefulWidget {
  const CreateFamilyDialog({super.key});

  @override
  ConsumerState<CreateFamilyDialog> createState() => _CreateFamilyDialogState();
}

class _CreateFamilyDialogState extends ConsumerState<CreateFamilyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _userNameController = TextEditingController();
  bool _isCreating = false;
  FamilyEntity? _createdFamily;

  @override
  void initState() {
    super.initState();
    // Pre-fill user name from profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null) {
        _userNameController.text = user.fullName ?? '';
        _familyNameController.text = '${user.fullName ?? 'Our'} Family';
      }
    });
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final familyName = _familyNameController.text.trim();
      final userName = _userNameController.text.trim();

      // Get FCM device token
      final fcmService = ref.read(fcmServiceProvider);
      final deviceToken = await fcmService.getToken();

      final family = await ref.read(familyManagementProvider).createFamily(
            familyName,
            userName,
            deviceToken: deviceToken,
          );

      setState(() {
        _createdFamily = family;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Family "$familyName" created!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create family: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  void _copyInviteCode() {
    if (_createdFamily?.inviteCode != null) {
      Clipboard.setData(ClipboardData(text: _createdFamily!.inviteCode!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invite code copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareInviteCode() {
    if (_createdFamily?.inviteCode != null) {
      final code = _createdFamily!.inviteCode!;
      final familyName = _createdFamily!.name;
      final message = 'Join "$familyName" on Family Planner!\n\n'
          'Use this invite code: $code\n\n'
          'Download the app and enter this code to join our family.';

      Share.share(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_createdFamily == null ? 'Create Your Family' : '🎉 Family Created!'),
      content: SingleChildScrollView(
        child: _createdFamily == null
            ? _buildCreateForm()
            : _buildSuccessView(),
      ),
      actions: _createdFamily == null
          ? [
              TextButton(
                onPressed: _isCreating ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: _isCreating ? null : _handleCreateFamily,
                child: _isCreating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create'),
              ),
            ]
          : [
              FilledButton(
                onPressed: () {
                  ref.invalidate(familyMembersProvider);
                  Navigator.of(context).pop(true);
                },
                child: const Text('Done'),
              ),
            ],
    );
  }

  Widget _buildCreateForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Create a family to start sharing tasks with your family members.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),

          // Family Name
          TextFormField(
            controller: _familyNameController,
            decoration: const InputDecoration(
              labelText: 'Family Name',
              prefixIcon: Icon(Icons.family_restroom),
              helperText: 'E.g., "Smith Family" or "The Johnsons"',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a family name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // User Name
          TextFormField(
            controller: _userNameController,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              prefixIcon: Icon(Icons.person),
              helperText: 'How you\'ll appear to family members',
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 64,
        ),
        const SizedBox(height: 16),

        Text(
          'Your family "${_createdFamily!.name}" has been created!',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),

        const Text(
          'Share this invite code with family members:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // Invite Code Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            children: [
              Text(
                _createdFamily!.inviteCode!,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _copyInviteCode,
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _shareInviteCode,
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Valid for 7 days',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),

        Card(
          color: Colors.amber[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[900], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can find this code anytime in Family Members settings',
                    style: TextStyle(fontSize: 12, color: Colors.amber[900]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
