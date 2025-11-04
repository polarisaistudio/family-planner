import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../data/services/permission_service.dart';

/// Provider for PermissionService singleton
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// State class for permission data
class PermissionState {
  final bool hasLocation;
  final bool hasBackgroundLocation;
  final bool hasNotification;
  final bool isLoading;
  final String? error;
  final Map<String, PermissionStatus>? detailedStatus;

  const PermissionState({
    this.hasLocation = false,
    this.hasBackgroundLocation = false,
    this.hasNotification = false,
    this.isLoading = false,
    this.error,
    this.detailedStatus,
  });

  PermissionState copyWith({
    bool? hasLocation,
    bool? hasBackgroundLocation,
    bool? hasNotification,
    bool? isLoading,
    String? error,
    Map<String, PermissionStatus>? detailedStatus,
  }) {
    return PermissionState(
      hasLocation: hasLocation ?? this.hasLocation,
      hasBackgroundLocation: hasBackgroundLocation ?? this.hasBackgroundLocation,
      hasNotification: hasNotification ?? this.hasNotification,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      detailedStatus: detailedStatus ?? this.detailedStatus,
    );
  }

  /// Check if all required permissions are granted
  bool get allGranted => hasLocation && hasNotification;

  /// Check if all permissions including background location are granted
  bool get allIncludingBackgroundGranted => hasLocation && hasBackgroundLocation && hasNotification;

  /// Get a human-readable list of missing permissions
  List<String> get missingPermissions {
    final missing = <String>[];
    if (!hasLocation) missing.add('Location');
    if (!hasNotification) missing.add('Notifications');
    return missing;
  }
}

/// Notifier for managing permission state
class PermissionNotifier extends StateNotifier<PermissionState> {
  final PermissionService _permissionService;

  PermissionNotifier(this._permissionService) : super(const PermissionState()) {
    _checkPermissions();
  }

  /// Check all permissions
  Future<void> _checkPermissions() async {
    state = state.copyWith(isLoading: true);

    try {
      final permissions = await _permissionService.checkAllPermissions();
      final detailed = await _permissionService.getDetailedStatus();

      state = state.copyWith(
        hasLocation: permissions['location'] ?? false,
        hasBackgroundLocation: permissions['backgroundLocation'] ?? false,
        hasNotification: permissions['notification'] ?? false,
        detailedStatus: detailed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to check permissions: $e',
      );
    }
  }

  /// Refresh permission status
  Future<void> refresh() async {
    await _checkPermissions();
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    state = state.copyWith(isLoading: true);

    try {
      final granted = await _permissionService.requestLocationPermission();

      await _checkPermissions();

      return granted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request location permission: $e',
      );
      return false;
    }
  }

  /// Request background location permission
  Future<bool> requestBackgroundLocationPermission() async {
    state = state.copyWith(isLoading: true);

    try {
      final granted = await _permissionService.requestBackgroundLocationPermission();

      await _checkPermissions();

      return granted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request background location permission: $e',
      );
      return false;
    }
  }

  /// Request notification permission
  Future<bool> requestNotificationPermission() async {
    state = state.copyWith(isLoading: true);

    try {
      final granted = await _permissionService.requestNotificationPermission();

      await _checkPermissions();

      return granted;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request notification permission: $e',
      );
      return false;
    }
  }

  /// Request all required permissions
  Future<Map<String, bool>> requestAllPermissions() async {
    state = state.copyWith(isLoading: true);

    try {
      final results = await _permissionService.requestAllPermissions();

      await _checkPermissions();

      return results;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to request permissions: $e',
      );
      return {
        'location': false,
        'backgroundLocation': false,
        'notification': false,
      };
    }
  }

  /// Open app settings
  Future<void> openSettings() async {
    await _permissionService.openSettings();

    // Refresh after user returns from settings
    // Note: User must manually return to app
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
  }

  /// Check if should show rationale for location permission
  Future<bool> shouldShowLocationRationale() async {
    return await _permissionService.shouldShowLocationRationale();
  }

  /// Check if should show rationale for notification permission
  Future<bool> shouldShowNotificationRationale() async {
    return await _permissionService.shouldShowNotificationRationale();
  }

  /// Get user-friendly permission status text
  String getPermissionStatusText(String permissionName) {
    if (state.detailedStatus == null) return 'Unknown';

    final status = state.detailedStatus![permissionName];
    if (status == null) return 'Unknown';

    switch (status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.limited:
        return 'Limited';
      default:
        return 'Unknown';
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for permission state notifier
final permissionProvider = StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
  final permissionService = ref.watch(permissionServiceProvider);
  return PermissionNotifier(permissionService);
});
