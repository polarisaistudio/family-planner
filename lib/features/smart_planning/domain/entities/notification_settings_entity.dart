import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Entity representing user's notification settings for smart planning
class NotificationSettingsEntity extends Equatable {
  final String userId;
  final bool locationNotificationsEnabled;
  final bool trafficNotificationsEnabled;
  final bool weatherNotificationsEnabled;
  final int defaultGeofenceRadius; // in meters
  final int defaultPreparationTime; // in minutes
  final String notificationSound;
  final bool vibrationEnabled;
  final String? quietHoursStart; // Format: "HH:mm" (e.g., "22:00")
  final String? quietHoursEnd; // Format: "HH:mm" (e.g., "08:00")
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationSettingsEntity({
    required this.userId,
    this.locationNotificationsEnabled = true,
    this.trafficNotificationsEnabled = true,
    this.weatherNotificationsEnabled = true,
    this.defaultGeofenceRadius = 500,
    this.defaultPreparationTime = 15,
    this.notificationSound = 'default',
    this.vibrationEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        userId,
        locationNotificationsEnabled,
        trafficNotificationsEnabled,
        weatherNotificationsEnabled,
        defaultGeofenceRadius,
        defaultPreparationTime,
        notificationSound,
        vibrationEnabled,
        quietHoursStart,
        quietHoursEnd,
        createdAt,
        updatedAt,
      ];

  /// Check if currently in quiet hours
  bool get isInQuietHours {
    if (quietHoursStart == null || quietHoursEnd == null) {
      return false;
    }

    try {
      final now = DateTime.now();
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

      final start = _parseTimeString(quietHoursStart!);
      final end = _parseTimeString(quietHoursEnd!);

      if (start == null || end == null) return false;

      // Handle cases where quiet hours span midnight
      if (start.hour > end.hour ||
          (start.hour == end.hour && start.minute > end.minute)) {
        // Quiet hours span midnight (e.g., 22:00 to 08:00)
        return _isTimeBetween(currentTime, start, const TimeOfDay(hour: 23, minute: 59)) ||
               _isTimeBetween(currentTime, const TimeOfDay(hour: 0, minute: 0), end);
      } else {
        // Normal quiet hours (e.g., 14:00 to 16:00)
        return _isTimeBetween(currentTime, start, end);
      }
    } catch (e) {
      print('Error checking quiet hours: $e');
      return false;
    }
  }

  /// Parse time string "HH:mm" to TimeOfDay
  TimeOfDay? _parseTimeString(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
        return null;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  /// Check if time is between start and end
  bool _isTimeBetween(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }

  /// Create a copy with updated fields
  NotificationSettingsEntity copyWith({
    String? userId,
    bool? locationNotificationsEnabled,
    bool? trafficNotificationsEnabled,
    bool? weatherNotificationsEnabled,
    int? defaultGeofenceRadius,
    int? defaultPreparationTime,
    String? notificationSound,
    bool? vibrationEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NotificationSettingsEntity(
      userId: userId ?? this.userId,
      locationNotificationsEnabled:
          locationNotificationsEnabled ?? this.locationNotificationsEnabled,
      trafficNotificationsEnabled:
          trafficNotificationsEnabled ?? this.trafficNotificationsEnabled,
      weatherNotificationsEnabled:
          weatherNotificationsEnabled ?? this.weatherNotificationsEnabled,
      defaultGeofenceRadius: defaultGeofenceRadius ?? this.defaultGeofenceRadius,
      defaultPreparationTime:
          defaultPreparationTime ?? this.defaultPreparationTime,
      notificationSound: notificationSound ?? this.notificationSound,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create default settings for a user
  factory NotificationSettingsEntity.defaults(String userId) {
    final now = DateTime.now();
    return NotificationSettingsEntity(
      userId: userId,
      locationNotificationsEnabled: true,
      trafficNotificationsEnabled: true,
      weatherNotificationsEnabled: true,
      defaultGeofenceRadius: 500,
      defaultPreparationTime: 15,
      notificationSound: 'default',
      vibrationEnabled: true,
      quietHoursStart: '22:00',
      quietHoursEnd: '08:00',
      createdAt: now,
      updatedAt: now,
    );
  }
}
