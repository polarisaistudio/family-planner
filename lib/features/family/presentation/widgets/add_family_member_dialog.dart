import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/family_member_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

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
            content: Text('Error: ${e.toString()}'),
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
      title: Text(isEditing ? 'Edit Family Member' : 'Add Family Member'),
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
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Email field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty && !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Role dropdown
              DropdownButtonFormField<FamilyRole>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  prefixIcon: Icon(Icons.admin_panel_settings),
                ),
                items: FamilyRole.values.map((role) {
                  IconData icon;
                  String label;
                  switch (role) {
                    case FamilyRole.admin:
                      icon = Icons.admin_panel_settings;
                      label = 'Admin';
                      break;
                    case FamilyRole.child:
                      icon = Icons.child_care;
                      label = 'Child';
                      break;
                    case FamilyRole.member:
                      icon = Icons.person;
                      label = 'Member';
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
              const Text(
                'Color',
                style: TextStyle(
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
                  title: const Text('Active'),
                  subtitle: const Text('Member can access family features'),
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
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _handleSave,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
