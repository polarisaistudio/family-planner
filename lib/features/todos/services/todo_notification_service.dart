import '../../../core/services/notification_service.dart';
import '../../family/data/repositories/family_repository.dart';
import '../domain/entities/todo_entity.dart';

/// Service for handling todo-related notifications
class TodoNotificationService {
  final NotificationService _notificationService;
  final FamilyRepository _familyRepository;
  final String Function() _getCurrentUserId;

  TodoNotificationService({
    required NotificationService notificationService,
    required FamilyRepository familyRepository,
    required String Function() getCurrentUserId,
  })  : _notificationService = notificationService,
        _familyRepository = familyRepository,
        _getCurrentUserId = getCurrentUserId;

  /// Notify when a task is assigned to a family member
  Future<void> notifyTaskAssigned({
    required TodoEntity todo,
    required String assignedToId,
    required String assignedByName,
  }) async {
    try {
      // Don't notify if assigning to self
      if (assignedToId == _getCurrentUserId()) {
        print('📭 Not sending notification: assigning to self');
        return;
      }

      // Get current user's family members
      final currentMembers = await _familyRepository.getFamilyMembers(_getCurrentUserId());
      if (currentMembers.isEmpty) {
        print('📭 No family members found');
        return;
      }

      // Get familyId from current user's membership
      final familyId = currentMembers.first.familyId;

      // Get all family members
      final members = await _familyRepository.getFamilyMembers(familyId);
      final assignedMember = members.firstWhere(
        (m) => m.userId == assignedToId,
        orElse: () => throw Exception('Assigned member not found'),
      );

      if (assignedMember.deviceToken == null || assignedMember.deviceToken!.isEmpty) {
        print('📭 No device token for assigned user');
        return;
      }

      await _notificationService.sendTaskAssignedNotification(
        recipientDeviceToken: assignedMember.deviceToken!,
        taskTitle: todo.title,
        assignedByName: assignedByName,
        taskId: todo.id,
      );
    } catch (e) {
      print('❌ Error sending task assigned notification: $e');
    }
  }

  /// Notify when a task is completed
  Future<void> notifyTaskCompleted({
    required TodoEntity todo,
    required String completedByName,
  }) async {
    try {
      final currentUserId = _getCurrentUserId();

      // Get current user's family members
      final currentMembers = await _familyRepository.getFamilyMembers(currentUserId);
      if (currentMembers.isEmpty) {
        print('📭 No family members found');
        return;
      }

      // Get familyId from current user's membership
      final familyId = currentMembers.first.familyId;

      // Get all family members
      final members = await _familyRepository.getFamilyMembers(familyId);

      // Notify all family members except the one who completed it
      final recipientMembers = members.where(
        (m) => m.userId != currentUserId && m.deviceToken != null && m.deviceToken!.isNotEmpty,
      ).toList();

      if (recipientMembers.isEmpty) {
        print('📭 No recipients with device tokens');
        return;
      }

      // Send notification to each recipient
      for (final member in recipientMembers) {
        await _notificationService.sendTaskCompletedNotification(
          recipientDeviceToken: member.deviceToken!,
          taskTitle: todo.title,
          completedByName: completedByName,
          taskId: todo.id,
        );
      }
    } catch (e) {
      print('❌ Error sending task completed notification: $e');
    }
  }

  /// Notify shared users when a task they're shared with is updated
  Future<void> notifySharedTaskUpdated({
    required TodoEntity todo,
    required String updatedByName,
  }) async {
    try {
      final currentUserId = _getCurrentUserId();

      // Only notify if task has sharedWith users
      if (todo.sharedWith == null || todo.sharedWith!.isEmpty) {
        return;
      }

      // Get current user's family members
      final currentMembers = await _familyRepository.getFamilyMembers(currentUserId);
      if (currentMembers.isEmpty) {
        print('📭 No family members found');
        return;
      }

      // Get familyId from current user's membership
      final familyId = currentMembers.first.familyId;

      // Get all family members
      final members = await _familyRepository.getFamilyMembers(familyId);

      // Notify all shared users except the one who updated it
      for (final sharedUserId in todo.sharedWith!) {
        if (sharedUserId == currentUserId) continue;

        final sharedMember = members.firstWhere(
          (m) => m.userId == sharedUserId,
          orElse: () => throw Exception('Shared member not found'),
        );

        if (sharedMember.deviceToken == null || sharedMember.deviceToken!.isEmpty) {
          continue;
        }

        await _notificationService.sendNotificationToMultipleDevices(
          deviceTokens: [sharedMember.deviceToken!],
          title: 'Task Updated',
          body: '$updatedByName updated: ${todo.title}',
          data: {
            'type': 'task_updated',
            'taskId': todo.id,
          },
        );
      }
    } catch (e) {
      print('❌ Error sending shared task update notification: $e');
    }
  }
}
