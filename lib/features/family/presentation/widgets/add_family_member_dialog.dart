import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/family_member_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../l10n/app_localizations.dart';

class AddFamilyMemberDialog extends ConsumerStatefulWidget {
  final String familyId;
  final FamilyMemberEntity? memberToEdit;
  final Function(FamilyMemberEntity) onSave;

  const AddFamilyMemberDialog({
    super.key,
    required this.familyId,
    this.memberToEdit,
    required this.onSave,
  });

  @override
  ConsumerState<AddFamilyMemberDialog> createState() => _AddFamilyMemberDialogState();
}

class _AddFamilyMemberDialogState extends ConsumerState<AddFamilyMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late FamilyRole _selectedRole;
  late String _selectedColor;
  bool _isActive = true;
  bool _isSaving = false;

  final List<String> _availableColors = [
    '#FF5252', // Red
    '#FF4081', // Pink
    '#E040FB', // Purple
    '#7C4DFF', // Deep Purple
    '#536DFE', // Indigo
    '#448AFF', // Blue
    '#40C4FF', // Light Blue
    '#18FFFF', // Cyan
    '#64FFDA', // Teal
    '#69F0AE', // Green
    '#B2FF59', // Light Green
    '#EEFF41', // Lime
    '#FFFF00', // Yellow
    '#FFD740', // Amber
    '#FFAB40', // Orange
    '#FF6E40', // Deep Orange
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.memberToEdit?.name ?? '');
    _emailController = TextEditingController(text: widget.memberToEdit?.email ?? '');
    _phoneController = TextEditingController(text: widget.memberToEdit?.phoneNumber ?? '');
    _selectedRole = widget.memberToEdit?.role ?? FamilyRole.member;
    _selectedColor = widget.memberToEdit?.color ?? _availableColors[0];
    _isActive = widget.memberToEdit?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final user = ref.read(currentUserProvider).value;
      final member = FamilyMemberEntity(
        id: widget.memberToEdit?.id ?? const Uuid().v4(),
        userId: widget.memberToEdit?.userId ?? user?.id ?? '',
        familyId: widget.familyId,
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        role: _selectedRole,
        color: _selectedColor,
        joinedAt: widget.memberToEdit?.joinedAt ?? DateTime.now(),
        isActive: _isActive,
        avatarUrl: widget.memberToEdit?.avatarUrl,
        preferences: widget.memberToEdit?.preferences,
      );

      await widget.onSave(member);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorWithMessage(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.memberToEdit != null;

    return AlertDialog(
      title: Text(isEditing ? AppLocalizations.of(context)!.editFamilyMember : AppLocalizations.of(context)!.addFamilyMember),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.nameRequired,
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.pleaseEnterName;
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.email,
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return AppLocalizations.of(context)!.pleaseEnterValidEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.phone,
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Role dropdown
              DropdownButtonFormField<FamilyRole>(
                value: _selectedRole,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.role,
                  prefixIcon: const Icon(Icons.admin_panel_settings),
                ),
                items: FamilyRole.values.map((role) {
                  IconData icon;
                  String label;
                  switch (role) {
                    case FamilyRole.admin:
                      icon = Icons.admin_panel_settings;
                      label = AppLocalizations.of(context)!.admin;
                      break;
                    case FamilyRole.child:
                      icon = Icons.child_care;
                      label = AppLocalizations.of(context)!.child;
                      break;
                    case FamilyRole.member:
                      icon = Icons.person;
                      label = AppLocalizations.of(context)!.member;
                      break;
                  }
                  return DropdownMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                        Text(label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedRole = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Color picker
              Text(
                AppLocalizations.of(context)!.color,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _availableColors.length,
                  itemBuilder: (context, index) {
                    final color = _availableColors[index];
                    final isSelected = color == _selectedColor;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Active status switch
              if (isEditing)
                SwitchListTile(
                  title: Text(AppLocalizations.of(context)!.active),
                  subtitle: Text(AppLocalizations.of(context)!.memberCanAccess),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () {
            Navigator.of(context).pop();
          },
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? AppLocalizations.of(context)!.save : AppLocalizations.of(context)!.add),
        ),
      ],
    );
  }
}
