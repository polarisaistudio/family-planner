import 'package:equatable/equatable.dart';

/// Domain entity representing a todo/task
class TodoEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final DateTime todoDate;
  final DateTime? todoTime;
  final int priority; // 1=urgent, 2=high, 3=medium, 4=low, 5=none
  final String type; // 'appointment', 'work', 'shopping', 'personal', 'other'
  final String status; // 'pending', 'in_progress', 'completed', 'cancelled'
  final String? location;
  final double? locationLat;
  final double? locationLng;
  final bool notificationEnabled;
  final int notificationMinutesBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Phase 2: Smart Planning fields
  final int travelTimeMinutes;
  final int geofenceRadiusMeters;
  final bool weatherDependent;
  final bool trafficAware;
  final int preparationTimeMinutes;
  final DateTime? lastTrafficCheck;
  final DateTime? lastWeatherCheck;
  final DateTime? estimatedDepartureTime;

  // Recurrence fields
  final bool isRecurring;
  final String? recurrencePattern; // 'daily', 'weekly', 'monthly', 'yearly'
  final int? recurrenceInterval; // e.g., 2 for "every 2 days"
  final List<int>? recurrenceWeekdays; // For weekly: [1,3,5] = Mon, Wed, Fri
  final DateTime? recurrenceEndDate; // When to stop recurring
  final String? recurrenceParentId; // Link to parent recurring task
  final bool isRecurrenceInstance; // Is this an instance of a recurring task?

  const TodoEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.todoDate,
    this.todoTime,
    this.priority = 3,
    this.type = 'other',
    this.status = 'pending',
    this.location,
    this.locationLat,
    this.locationLng,
    this.notificationEnabled = true,
    this.notificationMinutesBefore = 30,
    required this.createdAt,
    required this.updatedAt,
    // Phase 2: Smart Planning fields with defaults
    this.travelTimeMinutes = 0,
    this.geofenceRadiusMeters = 500,
    this.weatherDependent = false,
    this.trafficAware = true,
    this.preparationTimeMinutes = 15,
    this.lastTrafficCheck,
    this.lastWeatherCheck,
    this.estimatedDepartureTime,
    // Recurrence fields with defaults
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceInterval,
    this.recurrenceWeekdays,
    this.recurrenceEndDate,
    this.recurrenceParentId,
    this.isRecurrenceInstance = false,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        todoDate,
        todoTime,
        priority,
        type,
        status,
        location,
        locationLat,
        locationLng,
        notificationEnabled,
        notificationMinutesBefore,
        createdAt,
        updatedAt,
        // Phase 2 fields
        travelTimeMinutes,
        geofenceRadiusMeters,
        weatherDependent,
        trafficAware,
        preparationTimeMinutes,
        lastTrafficCheck,
        lastWeatherCheck,
        estimatedDepartureTime,
        // Recurrence fields
        isRecurring,
        recurrencePattern,
        recurrenceInterval,
        recurrenceWeekdays,
        recurrenceEndDate,
        recurrenceParentId,
        isRecurrenceInstance,
      ];

  /// Check if todo is completed
  bool get isCompleted => status == 'completed';

  /// Check if todo is overdue
  bool get isOverdue {
    if (isCompleted) return false;
    final now = DateTime.now();
    final todoDateTime = todoTime != null
        ? DateTime(
            todoDate.year,
            todoDate.month,
            todoDate.day,
            todoTime!.hour,
            todoTime!.minute,
          )
        : todoDate;
    return todoDateTime.isBefore(now);
  }

  /// Get combined date and time
  DateTime? get dateTime {
    if (todoTime == null) return todoDate;
    return DateTime(
      todoDate.year,
      todoDate.month,
      todoDate.day,
      todoTime!.hour,
      todoTime!.minute,
    );
  }

  /// Create a copy with updated fields
  TodoEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? todoDate,
    DateTime? todoTime,
    int? priority,
    String? type,
    String? status,
    String? location,
    double? locationLat,
    double? locationLng,
    bool? notificationEnabled,
    int? notificationMinutesBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
    // Phase 2 fields
    int? travelTimeMinutes,
    int? geofenceRadiusMeters,
    bool? weatherDependent,
    bool? trafficAware,
    int? preparationTimeMinutes,
    DateTime? lastTrafficCheck,
    DateTime? lastWeatherCheck,
    DateTime? estimatedDepartureTime,
    // Recurrence fields
    bool? isRecurring,
    String? recurrencePattern,
    int? recurrenceInterval,
    List<int>? recurrenceWeekdays,
    DateTime? recurrenceEndDate,
    String? recurrenceParentId,
    bool? isRecurrenceInstance,
  }) {
    return TodoEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      todoDate: todoDate ?? this.todoDate,
      todoTime: todoTime ?? this.todoTime,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      status: status ?? this.status,
      location: location ?? this.location,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationMinutesBefore:
          notificationMinutesBefore ?? this.notificationMinutesBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Phase 2 fields
      travelTimeMinutes: travelTimeMinutes ?? this.travelTimeMinutes,
      geofenceRadiusMeters: geofenceRadiusMeters ?? this.geofenceRadiusMeters,
      weatherDependent: weatherDependent ?? this.weatherDependent,
      trafficAware: trafficAware ?? this.trafficAware,
      preparationTimeMinutes: preparationTimeMinutes ?? this.preparationTimeMinutes,
      lastTrafficCheck: lastTrafficCheck ?? this.lastTrafficCheck,
      lastWeatherCheck: lastWeatherCheck ?? this.lastWeatherCheck,
      estimatedDepartureTime: estimatedDepartureTime ?? this.estimatedDepartureTime,
      // Recurrence fields
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceWeekdays: recurrenceWeekdays ?? this.recurrenceWeekdays,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      recurrenceParentId: recurrenceParentId ?? this.recurrenceParentId,
      isRecurrenceInstance: isRecurrenceInstance ?? this.isRecurrenceInstance,
    );
  }
}
