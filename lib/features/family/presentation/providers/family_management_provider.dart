import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/family_management_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for family management repository
final familyManagementRepositoryProvider = Provider<FamilyManagementRepository>((ref) {
  final authRepo = ref.watch(unifiedAuthRepositoryProvider);

  return FamilyManagementRepository(
    getIdToken: () => authRepo.getIdToken() ?? '',
    getUserId: () => authRepo.getCurrentUserIdSync() ?? '',
  );
});

/// Provider for family management operations
final familyManagementProvider = Provider<FamilyManagementRepository>((ref) {
  return ref.watch(familyManagementRepositoryProvider);
});
