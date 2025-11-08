// FCM Service - Currently disabled for iOS (using REST API)
// Firebase Messaging requires Firebase SDK which conflicts with Xcode 16
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for managing Firebase Cloud Messaging
/// NOTE: Currently stubbed out for iOS - using REST API only
class FCMService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _currentToken;

  /// Get the current FCM token
  String? get currentToken => _currentToken;

  /// Initialize FCM service (stubbed for iOS)
  Future<void> initialize() async {
    print('🔔 FCM Service: Skipped for iOS (using REST API)');
    // TODO: Implement REST-based push notifications or APNs directly
    return;
  }

  /// Subscribe to a topic (stubbed)
  Future<void> subscribeToTopic(String topic) async {
    print('📢 FCM: Topic subscription skipped (iOS REST mode)');
  }

  /// Unsubscribe from a topic (stubbed)
  Future<void> unsubscribeFromTopic(String topic) async {
    print('🔇 FCM: Topic unsubscription skipped (iOS REST mode)');
  }

  /// Get FCM token (stubbed)
  Future<String?> getToken() async {
    print('📱 FCM: Token request skipped (iOS REST mode)');
    return null;
  }

  /// Delete FCM token (stubbed)
  Future<void> deleteToken() async {
    print('🗑️ FCM: Token deletion skipped (iOS REST mode)');
    _currentToken = null;
  }
}
