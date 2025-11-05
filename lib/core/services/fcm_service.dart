import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;
import 'navigation_service.dart';

/// Service for managing Firebase Cloud Messaging
class FCMService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;

  /// Get the current FCM token
  String? get currentToken => _currentToken;

  /// Initialize FCM service
  Future<void> initialize() async {
    print('🔔 Initializing FCM Service...');

    // Request notification permissions
    final settings = await _requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('⚠️ Notification permission not granted');
      return;
    }

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Get FCM token
    _currentToken = await _firebaseMessaging.getToken();
    print('📱 FCM Token: $_currentToken');

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM Token refreshed: $newToken');
      _currentToken = newToken;
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    print('✅ FCM Service initialized successfully');
  }

  /// Request notification permissions
  Future<NotificationSettings> _requestPermission() async {
    return await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );
  }

  /// Initialize local notifications for displaying in-app
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const androidChannel = AndroidNotificationChannel(
        'family_planner_channel',
        'Family Planner Notifications',
        description: 'Notifications for task assignments and updates',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message received: ${message.notification?.title}');

    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'family_planner_channel',
            'Family Planner Notifications',
            channelDescription: 'Notifications for task assignments and updates',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('👆 Notification tapped: ${message.notification?.title}');
    print('📦 Data: ${message.data}');

    // Navigate to appropriate screen based on notification type
    NavigationService.handleNotificationTap(message.data);
  }

  /// Handle notification tap from local notifications
  void _onNotificationTap(NotificationResponse response) {
    print('👆 Local notification tapped: ${response.payload}');

    if (response.payload != null) {
      try {
        // Parse the payload string back to map
        // Note: payload is stored as string in _handleForegroundMessage
        // For now, we'll extract taskId from the data
        // In production, you'd want to use JSON encoding
        final payload = response.payload!;

        // Simple parsing - assumes format like: "{type: task_assigned, taskId: abc123}"
        final taskIdMatch = RegExp(r'taskId[:\s]+([^,}]+)').firstMatch(payload);
        final typeMatch = RegExp(r'type[:\s]+([^,}]+)').firstMatch(payload);

        if (taskIdMatch != null && typeMatch != null) {
          final taskId = taskIdMatch.group(1)?.trim();
          final type = typeMatch.group(1)?.trim();

          if (taskId != null && type != null) {
            NavigationService.handleNotificationTap({
              'taskId': taskId,
              'type': type,
            });
          }
        }
      } catch (e) {
        print('❌ Error parsing notification payload: $e');
      }
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('📢 Subscribed to topic: $topic');
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('🔇 Unsubscribed from topic: $topic');
  }

  /// Get FCM token (refresh if needed)
  Future<String?> getToken() async {
    if (_currentToken == null) {
      _currentToken = await _firebaseMessaging.getToken();
    }
    return _currentToken;
  }

  /// Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
    _currentToken = null;
    print('🗑️ FCM token deleted');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 Background message received: ${message.notification?.title}');
  // Note: Cannot update UI here, only process data
}
