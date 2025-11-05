import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/family_member_entity.dart';
import '../../data/repositories/family_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for family repository
final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final authRepo = ref.watch(unifiedAuthRepositoryProvider);

  return FamilyRepository(
    getIdToken: () => authRepo.getIdToken() ?? '',
    getUserId: () => authRepo.getCurrentUserIdSync() ?? '',
  );
});

/// State for family members
class FamilyMembersState {
  final List<FamilyMemberEntity> members;
  final bool isLoading;
  final String? error;

  const FamilyMembersState({
    this.members = const [],
    this.isLoading = false,
    this.error,
  });

  FamilyMembersState copyWith({
    List<FamilyMemberEntity>? members,
    bool? isLoading,
    String? error,
  }) {
    return FamilyMembersState(
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing family members
class FamilyMembersNotifier extends StateNotifier<FamilyMembersState> {
  final FamilyRepository _repository;

  FamilyMembersNotifier(this._repository) : super(const FamilyMembersState());

  /// Load family members for a family
  Future<void> loadFamilyMembers(String familyId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final members = await _repository.getFamilyMembers(familyId);
      state = state.copyWith(
        members: members,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add a new family member
  Future<void> addFamilyMember(FamilyMemberEntity member) async {
    try {
      await _repository.createFamilyMember(member);

      // Add to local state
      final updatedMembers = [...state.members, member];
      state = state.copyWith(members: updatedMembers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Update a family member
  Future<void> updateFamilyMember(FamilyMemberEntity member) async {
    try {
      await _repository.updateFamilyMember(member);

      // Update local state
      final updatedMembers = state.members.map((m) {
        return m.id == member.id ? member : m;
      }).toList();

      state = state.copyWith(members: updatedMembers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Remove a family member
  Future<void> removeFamilyMember(String memberId) async {
    try {
      await _repository.deleteFamilyMember(memberId);

      // Remove from local state
      final updatedMembers = state.members.where((m) => m.id != memberId).toList();
      state = state.copyWith(members: updatedMembers);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Get a specific family member by ID
  FamilyMemberEntity? getMemberById(String memberId) {
    try {
      return state.members.firstWhere((m) => m.id == memberId);
    } catch (e) {
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for family members
final familyMembersProvider =
    StateNotifierProvider<FamilyMembersNotifier, FamilyMembersState>((ref) {
  final repository = ref.watch(familyRepositoryProvider);
  return FamilyMembersNotifier(repository);
});
