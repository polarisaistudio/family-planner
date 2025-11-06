import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/family_member_entity.dart';
import '../providers/family_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/add_family_member_dialog.dart';
import '../widgets/family_member_card.dart';
import '../widgets/create_family_dialog.dart';
import 'join_family_page.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFamilyMember),
        content: Text(l10n.confirmRemoveMember(member.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.confirmRemove),
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
              content: Text(l10n.memberRemoved(member.name)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorRemovingMember(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final familyState = ref.watch(familyMembersProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.familyMembers),
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
                      Text(l10n.errorWithMessage(familyState.error!)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadFamilyMembers,
                        child: Text(l10n.retry),
                      ),
                    ],
                  ),
                )
              : familyState.members.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.family_restroom, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 24),
                            Text(
                              l10n.noFamilyYet,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.startCollaborating,
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Create Family Button
                            FilledButton.icon(
                              onPressed: () async {
                                final result = await showDialog(
                                  context: context,
                                  builder: (context) => const CreateFamilyDialog(),
                                );
                                if (result == true) {
                                  _loadFamilyMembers();
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: Text(l10n.createNewFamily),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Or Divider
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    l10n.or,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Join Family Button
                            OutlinedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const JoinFamilyPage(),
                                  ),
                                );
                                if (result == true) {
                                  _loadFamilyMembers();
                                }
                              },
                              icon: const Icon(Icons.group_add),
                              label: Text(l10n.joinExistingFamily),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Info Card
                            Card(
                              color: Colors.blue[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                                        const SizedBox(width: 8),
                                        Text(
                                          l10n.gettingStarted,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '${l10n.gettingStartedBullet1}\n'
                                      '${l10n.gettingStartedBullet2}\n'
                                      '${l10n.gettingStartedBullet3}\n'
                                      '${l10n.gettingStartedBullet4}',
                                      style: TextStyle(
                                        fontSize: 13,
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
                                    l10n.familyMembersCount(familyState.members.length),
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
              label: Text(l10n.addMember),
            )
          : null,
    );
  }
}
