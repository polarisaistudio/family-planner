import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for sending push notifications to family members
class NotificationService {
  final String Function() _getIdToken;
  final String _projectId;

  NotificationService({
    required String Function() getIdToken,
    required String projectId,
  })  : _getIdToken = getIdToken,
        _projectId = projectId;

  /// Send notification when a task is assigned to a family member
  Future<void> sendTaskAssignedNotification({
    required String recipientDeviceToken,
    required String taskTitle,
    required String assignedByName,
    required String taskId,
  }) async {
    await _sendNotification(
      deviceToken: recipientDeviceToken,
      title: 'New Task Assigned',
      body: '$assignedByName assigned you: $taskTitle',
      data: {
        'type': 'task_assigned',
        'taskId': taskId,
      },
    );
  }

  /// Send notification when a task is completed
  Future<void> sendTaskCompletedNotification({
    required String recipientDeviceToken,
    required String taskTitle,
    required String completedByName,
    required String taskId,
  }) async {
    await _sendNotification(
      deviceToken: recipientDeviceToken,
      title: 'Task Completed',
      body: '$completedByName completed: $taskTitle',
      data: {
        'type': 'task_completed',
        'taskId': taskId,
      },
    );
  }

  /// Send notification when someone comments on a shared task
  Future<void> sendTaskCommentNotification({
    required String recipientDeviceToken,
    required String taskTitle,
    required String commenterName,
    required String comment,
    required String taskId,
  }) async {
    await _sendNotification(
      deviceToken: recipientDeviceToken,
      title: 'New Comment on $taskTitle',
      body: '$commenterName: $comment',
      data: {
        'type': 'task_comment',
        'taskId': taskId,
      },
    );
  }

  /// Send notification to multiple devices
  Future<void> sendNotificationToMultipleDevices({
    required List<String> deviceTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Send to each device (FCM v1 doesn't support multi-cast directly via REST)
    await Future.wait(
      deviceTokens.map((token) => _sendNotification(
            deviceToken: token,
            title: title,
            body: body,
            data: data,
          )),
    );
  }

  /// Core method to send a notification via FCM REST API
  Future<void> _sendNotification({
    required String deviceToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final idToken = _getIdToken();
      if (idToken.isEmpty) {
        print('⚠️ Cannot send notification: No auth token');
        return;
      }

      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$_projectId/messages:send',
      );

      final message = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': title,
            'body': body,
          },
          'data': data ?? {},
          'android': {
            'priority': 'high',
            'notification': {
              'sound': 'default',
              'priority': 'high',
            },
          },
          'apns': {
            'payload': {
              'aps': {
                'sound': 'default',
                'badge': 1,
              },
            },
          },
        },
      };

      print('📤 Sending notification to token: ${deviceToken.substring(0, 20)}...');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Notification sent successfully');
      } else {
        print('❌ Failed to send notification: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  /// Send notification to all family members except sender
  Future<void> notifyFamilyMembers({
    required List<String> deviceTokens,
    required String excludeUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Filter out sender's device token if needed
    final filteredTokens = deviceTokens.where((token) => token.isNotEmpty).toList();

    if (filteredTokens.isEmpty) {
      print('⚠️ No device tokens to send notifications');
      return;
    }

    await sendNotificationToMultipleDevices(
      deviceTokens: filteredTokens,
      title: title,
      body: body,
      data: data,
    );
  }
}
