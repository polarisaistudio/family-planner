import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

/// Service to handle app permissions
/// Manages location and notification permissions for Phase 2 features
class PermissionService {
  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }

  /// Check if background location permission is granted (Android)
  Future<bool> hasBackgroundLocationPermission() async {
    if (await Permission.locationAlways.isPermanentlyDenied) {
      return false;
    }
    final status = await Permission.locationAlways.status;
    return status.isGranted;
  }

  /// Check if notification permission is granted
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted || status.isLimited;
  }

  /// Request location permission
  /// Returns true if granted
  Future<bool> requestLocationPermission() async {
    try {
      // First check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('🔴 [PERMISSION] Location services are disabled');
        return false;
      }

      // Use Geolocator instead of permission_handler for iOS compatibility
      print('🔵 [PERMISSION] Checking current location permission status...');
      LocationPermission permission = await Geolocator.checkPermission();
      print('🔵 [PERMISSION] Current status: $permission');

      if (permission == LocationPermission.denied) {
        print('🔵 [PERMISSION] Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('🔵 [PERMISSION] New status after request: $permission');
      }

      if (permission == LocationPermission.deniedForever) {
        print('🔴 [PERMISSION] Location permission permanently denied - opening settings');
        await openAppSettings();
        return false;
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        print('🟢 [PERMISSION] Location permission granted');
        return true;
      }

      print('🔴 [PERMISSION] Location permission denied');
      return false;
    } catch (e) {
      print('🔴 [PERMISSION] Error requesting location permission: $e');
      return false;
    }
  }

  /// Request background location permission (Android only)
  /// On iOS, this is handled by the system based on usage
  Future<bool> requestBackgroundLocationPermission() async {
    try {
      // Only request if foreground permission is already granted
      if (!await hasLocationPermission()) {
        print('🔴 [PERMISSION] Foreground location permission not granted');
        return false;
      }

      final status = await Permission.locationAlways.request();

      if (status.isGranted) {
        print('🟢 [PERMISSION] Background location permission granted');
        return true;
      } else if (status.isDenied) {
        print('🔴 [PERMISSION] Background location permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        print('🔴 [PERMISSION] Background location permission permanently denied');
        await openAppSettings();
        return false;
      }

      return false;
    } catch (e) {
      print('🔴 [PERMISSION] Error requesting background location: $e');
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    try {
      print('🔵 [PERMISSION] Checking notification permission status...');
      final currentStatus = await Permission.notification.status;
      print('🔵 [PERMISSION] Current notification status: $currentStatus');

      if (currentStatus.isGranted || currentStatus.isLimited) {
        print('🟢 [PERMISSION] Notification permission already granted');
        return true;
      }

      if (currentStatus.isPermanentlyDenied) {
        print('🔴 [PERMISSION] Notification permission permanently denied - opening settings');
        await openAppSettings();
        return false;
      }

      print('🔵 [PERMISSION] Requesting notification permission...');
      final status = await Permission.notification.request();
      print('🔵 [PERMISSION] New notification status: $status');

      if (status.isGranted || status.isLimited) {
        print('🟢 [PERMISSION] Notification permission granted');
        return true;
      } else if (status.isPermanentlyDenied) {
        print('🔴 [PERMISSION] Notification permission permanently denied - opening settings');
        await openAppSettings();
        return false;
      } else {
        print('🔴 [PERMISSION] Notification permission denied');
        return false;
      }
    } catch (e) {
      print('🔴 [PERMISSION] Error requesting notification permission: $e');
      return false;
    }
  }

  /// Request all required permissions for smart planning
  Future<Map<String, bool>> requestAllPermissions() async {
    print('🔵 [PERMISSION] Requesting all permissions for smart planning');

    final locationGranted = await requestLocationPermission();
    final notificationGranted = await requestNotificationPermission();

    // Only request background location if foreground is granted
    bool backgroundLocationGranted = false;
    if (locationGranted) {
      backgroundLocationGranted = await requestBackgroundLocationPermission();
    }

    final results = {
      'location': locationGranted,
      'backgroundLocation': backgroundLocationGranted,
      'notification': notificationGranted,
    };

    print('🔵 [PERMISSION] Results: $results');
    return results;
  }

  /// Check all permissions status
  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'location': await hasLocationPermission(),
      'backgroundLocation': await hasBackgroundLocationPermission(),
      'notification': await hasNotificationPermission(),
    };
  }

  /// Open app settings for manual permission management
  Future<void> openSettings() async {
    await openAppSettings();
  }

  /// Get detailed permission status for display
  Future<Map<String, PermissionStatus>> getDetailedStatus() async {
    return {
      'location': await Permission.location.status,
      'backgroundLocation': await Permission.locationAlways.status,
      'notification': await Permission.notification.status,
    };
  }

  /// Check if user should be shown rationale for location permission
  Future<bool> shouldShowLocationRationale() async {
    final status = await Permission.location.status;
    return status.isDenied && !status.isPermanentlyDenied;
  }

  /// Check if user should be shown rationale for notification permission
  Future<bool> shouldShowNotificationRationale() async {
    final status = await Permission.notification.status;
    return status.isDenied && !status.isPermanentlyDenied;
  }
}
