import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Service to handle local notifications
/// Schedules and manages notifications for todos
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      print('🔵 [NOTIFICATION] Initializing notification service...');

      // Initialize timezone data
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      _initialized = true;
      print('🟢 [NOTIFICATION] Notification service initialized');
    } catch (e) {
      print('🔴 [NOTIFICATION] Error initializing: $e');
    }
  }

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    // High priority channel for urgent reminders
    const urgentChannel = AndroidNotificationChannel(
      'urgent_reminders',
      'Urgent Reminders',
      description: 'Urgent task reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Normal priority channel for regular reminders
    const normalChannel = AndroidNotificationChannel(
      'task_reminders',
      'Task Reminders',
      description: 'Regular task reminders',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    // Location-based reminders
    const locationChannel = AndroidNotificationChannel(
      'location_reminders',
      'Location Reminders',
      description: 'Reminders based on your location',
      importance: Importance.high,
      playSound: true,
    );

    // Weather/Traffic alerts
    const alertChannel = AndroidNotificationChannel(
      'weather_traffic_alerts',
      'Weather & Traffic Alerts',
      description: 'Alerts about weather and traffic conditions',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    final plugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (plugin != null) {
      await plugin.createNotificationChannel(urgentChannel);
      await plugin.createNotificationChannel(normalChannel);
      await plugin.createNotificationChannel(locationChannel);
      await plugin.createNotificationChannel(alertChannel);
      print('🟢 [NOTIFICATION] Android channels created');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('🔵 [NOTIFICATION] Notification tapped: ${response.id}');
    // TODO: Navigate to todo details
    // This will be implemented when we add navigation handling
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
    if (!_initialized) await initialize();

    try {
      print('🔵 [NOTIFICATION] Scheduling notification #$id for $scheduledTime');

      final channelId = _getChannelId(priority);

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _getChannelName(priority),
            channelDescription: _getChannelDescription(priority),
            importance: _getImportance(priority),
            priority: _getPriority(priority),
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      print('🟢 [NOTIFICATION] Notification #$id scheduled successfully');
    } catch (e) {
      print('🔴 [NOTIFICATION] Error scheduling notification: $e');
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
    if (!_initialized) await initialize();

    try {
      print('🔵 [NOTIFICATION] Showing immediate notification #$id');

      final channelId = _getChannelId(priority);

      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            _getChannelName(priority),
            channelDescription: _getChannelDescription(priority),
            importance: _getImportance(priority),
            priority: _getPriority(priority),
            playSound: true,
            enableVibration: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );

      print('🟢 [NOTIFICATION] Notification #$id shown');
    } catch (e) {
      print('🔴 [NOTIFICATION] Error showing notification: $e');
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      print('🟢 [NOTIFICATION] Notification #$id cancelled');
    } catch (e) {
      print('🔴 [NOTIFICATION] Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      print('🟢 [NOTIFICATION] All notifications cancelled');
    } catch (e) {
      print('🔴 [NOTIFICATION] Error cancelling all notifications: $e');
    }
  }

  /// Get all pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('🔵 [NOTIFICATION] ${pending.length} pending notifications');
      return pending;
    } catch (e) {
      print('🔴 [NOTIFICATION] Error getting pending notifications: $e');
      return [];
    }
  }

  /// Schedule a location-based reminder
  Future<void> scheduleLocationReminder({
    required int id,
    required String todoTitle,
    required String locationName,
  }) async {
    await showNotification(
      id: id,
      title: 'Near $locationName',
      body: 'Don\'t forget: $todoTitle',
      priority: NotificationPriority.location,
    );
  }

  /// Schedule a traffic alert
  Future<void> scheduleTrafficAlert({
    required int id,
    required String todoTitle,
    required int delayMinutes,
    required DateTime newDepartureTime,
  }) async {
    final timeStr = _formatTime(newDepartureTime);

    await showNotification(
      id: id,
      title: 'Traffic Alert',
      body: 'Heavy traffic detected! Leave by $timeStr for: $todoTitle ($delayMinutes min delay)',
      priority: NotificationPriority.alert,
    );
  }

  /// Schedule a weather alert
  Future<void> scheduleWeatherAlert({
    required int id,
    required String todoTitle,
    required String weatherCondition,
  }) async {
    await showNotification(
      id: id,
      title: 'Weather Alert',
      body: '$weatherCondition expected for: $todoTitle',
      priority: NotificationPriority.alert,
    );
  }

  /// Schedule a preparation reminder
  Future<void> schedulePreparationReminder({
    required int id,
    required String todoTitle,
    required DateTime reminderTime,
    required int preparationMinutes,
  }) async {
    await scheduleNotification(
      id: id,
      title: 'Time to Prepare',
      body: '$todoTitle in $preparationMinutes minutes',
      scheduledTime: reminderTime,
      priority: NotificationPriority.normal,
    );
  }

  /// Get channel ID based on priority
  String _getChannelId(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return 'urgent_reminders';
      case NotificationPriority.location:
        return 'location_reminders';
      case NotificationPriority.alert:
        return 'weather_traffic_alerts';
      case NotificationPriority.normal:
      default:
        return 'task_reminders';
    }
  }

  /// Get channel name based on priority
  String _getChannelName(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return 'Urgent Reminders';
      case NotificationPriority.location:
        return 'Location Reminders';
      case NotificationPriority.alert:
        return 'Weather & Traffic Alerts';
      case NotificationPriority.normal:
      default:
        return 'Task Reminders';
    }
  }

  /// Get channel description based on priority
  String _getChannelDescription(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return 'Urgent task reminders';
      case NotificationPriority.location:
        return 'Reminders based on your location';
      case NotificationPriority.alert:
        return 'Alerts about weather and traffic conditions';
      case NotificationPriority.normal:
      default:
        return 'Regular task reminders';
    }
  }

  /// Get Android importance based on priority
  Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Importance.high;
      case NotificationPriority.location:
        return Importance.high;
      case NotificationPriority.alert:
        return Importance.defaultImportance;
      case NotificationPriority.normal:
      default:
        return Importance.defaultImportance;
    }
  }

  /// Get Android priority based on priority
  Priority _getPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.urgent:
        return Priority.high;
      case NotificationPriority.location:
        return Priority.high;
      case NotificationPriority.alert:
        return Priority.defaultPriority;
      case NotificationPriority.normal:
      default:
        return Priority.defaultPriority;
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Notification priority levels
enum NotificationPriority {
  normal,
  urgent,
  location,
  alert,
}
