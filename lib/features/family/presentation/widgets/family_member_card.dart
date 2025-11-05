import 'package:flutter/material.dart';
import '../../domain/entities/family_member_entity.dart';

/// Card displaying a family member
class FamilyMemberCard extends StatelessWidget {
  final FamilyMemberEntity member;
  final bool isCurrentUser;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const FamilyMemberCard({
    super.key,
    required this.member,
    this.isCurrentUser = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final memberColor = member.color != null
        ? Color(int.parse(member.color!.replaceFirst('#', '0xFF')))
        : Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: memberColor.withOpacity(0.2),
          radius: 24,
          child: member.avatarUrl != null
              ? ClipOval(
                  child: Image.network(
                    member.avatarUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildInitials(memberColor);
                    },
                  ),
                )
              : _buildInitials(memberColor),
        ),
        title: Row(
          children: [
            Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'You',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (member.email != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.email, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    member.email!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                _buildRoleBadge(),
                const SizedBox(width: 8),
                if (!member.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
                tooltip: 'Edit member',
              ),
            if (onDelete != null && !isCurrentUser)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                color: Colors.red,
                onPressed: onDelete,
                tooltip: 'Remove member',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitials(Color color) {
    final initials = member.name.split(' ').map((word) {
      return word.isNotEmpty ? word[0].toUpperCase() : '';
    }).take(2).join();

    return Text(
      initials,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildRoleBadge() {
    Color badgeColor;
    IconData icon;
    String label;

    switch (member.role) {
      case FamilyRole.admin:
        badgeColor = Colors.purple;
        icon = Icons.admin_panel_settings;
        label = 'Admin';
        break;
      case FamilyRole.child:
        badgeColor = Colors.orange;
        icon = Icons.child_care;
        label = 'Child';
        break;
      case FamilyRole.member:
        badgeColor = Colors.blue;
        icon = Icons.person;
        label = 'Member';
        break;
    }

    // Create a darker shade of the badge color
    final darkerColor = Color.fromRGBO(
      (badgeColor.red * 0.7).toInt(),
      (badgeColor.green * 0.7).toInt(),
      (badgeColor.blue * 0.7).toInt(),
      1,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: darkerColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: darkerColor,
            ),
          ),
        ],
      ),
    );
  }
}
