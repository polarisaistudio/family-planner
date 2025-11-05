import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../fcm_service.dart';
import '../notification_service.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';

/// Provider for FCM Service
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// Provider for Notification Service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final authRepo = ref.watch(unifiedAuthRepositoryProvider);

  return NotificationService(
    getIdToken: () => authRepo.getIdToken() ?? '',
    projectId: 'family-planner-8dc9f', // TODO: Move to config
  );
});

/// Provider to initialize FCM on app startup
final fcmInitializerProvider = FutureProvider<void>((ref) async {
  final fcmService = ref.watch(fcmServiceProvider);
  await fcmService.initialize();
});
