import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/family_member_entity.dart';
import '../providers/family_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/add_family_member_dialog.dart';
import '../widgets/family_member_card.dart';

/// Page to manage family members
class FamilyMembersPage extends ConsumerStatefulWidget {
  const FamilyMembersPage({super.key});

  @override
  ConsumerState<FamilyMembersPage> createState() => _FamilyMembersPageState();
}

class _FamilyMembersPageState extends ConsumerState<FamilyMembersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFamilyMembers();
    });
  }

  Future<void> _loadFamilyMembers() async {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      // For now, use userId as familyId (single family per user)
      // In production, you'd have a separate family table
      await ref.read(familyMembersProvider.notifier).loadFamilyMembers(user.id);
    }
  }

  Future<void> _showAddMemberDialog() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) => AddFamilyMemberDialog(
        familyId: user.id,
        onSave: (member) async {
          await ref.read(familyMembersProvider.notifier).addFamilyMember(member);
        },
      ),
    );
  }

  Future<void> _deleteMember(FamilyMemberEntity member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Family Member'),
        content: Text('Are you sure you want to remove ${member.name} from your family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(familyMembersProvider.notifier).removeFamilyMember(member.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member.name} removed from family'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final familyState = ref.watch(familyMembersProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFamilyMembers,
          ),
        ],
      ),
      body: familyState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : familyState.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text('Error: ${familyState.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFamilyMembers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : familyState.members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text(
                            'No family members yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add family members to share tasks',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _showAddMemberDialog,
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add First Member'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Info card
                        Card(
                          color: Colors.blue.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue.shade700),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${familyState.members.length} family member(s). Assign tasks and collaborate!',
                                    style: TextStyle(color: Colors.blue.shade900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Family members list
                        ...familyState.members.map((member) {
                          final isCurrentUser = currentUser?.id == member.userId;

                          return FamilyMemberCard(
                            member: member,
                            isCurrentUser: isCurrentUser,
                            onEdit: () async {
                              await showDialog(
                                context: context,
                                builder: (context) => AddFamilyMemberDialog(
                                  familyId: member.familyId,
                                  memberToEdit: member,
                                  onSave: (updatedMember) async {
                                    await ref
                                        .read(familyMembersProvider.notifier)
                                        .updateFamilyMember(updatedMember);
                                  },
                                ),
                              );
                            },
                            onDelete: () => _deleteMember(member),
                          );
                        }).toList(),
                      ],
                    ),
      floatingActionButton: familyState.members.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showAddMemberDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member'),
            )
          : null,
    );
  }
}
