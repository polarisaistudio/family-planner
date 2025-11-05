import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../todo_notification_service.dart';
import '../../../../core/services/providers/fcm_provider.dart';
import '../../../family/presentation/providers/family_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Provider for TodoNotificationService
final todoNotificationServiceProvider = Provider<TodoNotificationService>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  final familyRepository = ref.watch(familyRepositoryProvider);
  final authRepo = ref.watch(unifiedAuthRepositoryProvider);

  return TodoNotificationService(
    notificationService: notificationService,
    familyRepository: familyRepository,
    getCurrentUserId: () => authRepo.getCurrentUserIdSync() ?? '',
  );
});
