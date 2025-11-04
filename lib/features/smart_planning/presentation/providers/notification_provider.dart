import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../data/services/notification_service.dart';

/// Provider for NotificationService singleton
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// State class for notification data
class NotificationState {
  final bool isInitialized;
  final List<PendingNotificationRequest> pendingNotifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.isInitialized = false,
    this.pendingNotifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    bool? isInitialized,
    List<PendingNotificationRequest>? pendingNotifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      isInitialized: isInitialized ?? this.isInitialized,
      pendingNotifications: pendingNotifications ?? this.pendingNotifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get count of pending notifications
  int get pendingCount => pendingNotifications.length;
}

/// Notifier for managing notification state
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;

  NotificationNotifier(this._notificationService) : super(const NotificationState()) {
    _initialize();
  }

  /// Initialize notification service
  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      await _notificationService.initialize();
      state = state.copyWith(
        isInitialized: true,
        isLoading: false,
      );

      // Load pending notifications
      await refreshPendingNotifications();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize notifications: $e',
      );
    }
  }

  /// Schedule a notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      await _notificationService.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledTime: scheduledTime,
        payload: payload,
        priority: priority,
      );

      // Refresh pending notifications list
      await refreshPendingNotifications();
    } catch (e) {
      state = state.copyWith(error: 'Failed to schedule notification: $e');
    }
  }

  /// Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.normal,
  }) async {
    try {
      await _notificationService.showNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
        priority: priority,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to show notification: $e');
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notificationService.cancelNotification(id);
      await refreshPendingNotifications();
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      await refreshPendingNotifications();
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel all notifications: $e');
    }
  }

  /// Refresh the list of pending notifications
  Future<void> refreshPendingNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      state = state.copyWith(pendingNotifications: pending);
    } catch (e) {
      print('Error refreshing pending notifications: $e');
    }
  }

  /// Schedule a location-based reminder
  Future<void> scheduleLocationReminder({
    required int id,
    required String todoTitle,
    required String locationName,
  }) async {
    try {
      await _notificationService.scheduleLocationReminder(
        id: id,
        todoTitle: todoTitle,
        locationName: locationName,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to schedule location reminder: $e');
    }
  }

  /// Schedule a traffic alert
  Future<void> scheduleTrafficAlert({
    required int id,
    required String todoTitle,
    required int delayMinutes,
    required DateTime newDepartureTime,
  }) async {
    try {
      await _notificationService.scheduleTrafficAlert(
        id: id,
        todoTitle: todoTitle,
        delayMinutes: delayMinutes,
        newDepartureTime: newDepartureTime,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to schedule traffic alert: $e');
    }
  }

  /// Schedule a weather alert
  Future<void> scheduleWeatherAlert({
    required int id,
    required String todoTitle,
    required String weatherCondition,
  }) async {
    try {
      await _notificationService.scheduleWeatherAlert(
        id: id,
        todoTitle: todoTitle,
        weatherCondition: weatherCondition,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to schedule weather alert: $e');
    }
  }

  /// Schedule a preparation reminder
  Future<void> schedulePreparationReminder({
    required int id,
    required String todoTitle,
    required DateTime reminderTime,
    required int preparationMinutes,
  }) async {
    try {
      await _notificationService.schedulePreparationReminder(
        id: id,
        todoTitle: todoTitle,
        reminderTime: reminderTime,
        preparationMinutes: preparationMinutes,
      );

      await refreshPendingNotifications();
    } catch (e) {
      state = state.copyWith(error: 'Failed to schedule preparation reminder: $e');
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for notification state notifier
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationNotifier(notificationService);
});
