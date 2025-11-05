import 'package:flutter/material.dart';

/// Service for handling app-wide navigation and deep linking
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Get the current navigation context
  static BuildContext? get context => navigatorKey.currentContext;

  /// Navigate to a named route
  static Future<dynamic>? navigateTo(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  /// Navigate to a route and remove all previous routes
  static Future<dynamic>? navigateAndReplace(String routeName, {Object? arguments}) {
    return navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Pop the current route
  static void pop([Object? result]) {
    return navigatorKey.currentState?.pop(result);
  }

  /// Navigate to a widget directly
  static Future<dynamic>? navigateToWidget(Widget widget) {
    return navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => widget),
    );
  }

  /// Handle notification tap and navigate to appropriate screen
  static void handleNotificationTap(Map<String, dynamic> data) {
    print('📱 Handling notification tap with data: $data');

    final type = data['type'] as String?;
    final taskId = data['taskId'] as String?;

    if (type == null || taskId == null) {
      print('⚠️ Invalid notification data');
      return;
    }

    switch (type) {
      case 'task_assigned':
      case 'task_completed':
      case 'task_updated':
      case 'task_comment':
        // Navigate to calendar page with task ID
        // The calendar page will open the task dialog
        navigateTo('/calendar', arguments: {'taskId': taskId, 'openTask': true});
        break;
      default:
        print('⚠️ Unknown notification type: $type');
    }
  }
}
