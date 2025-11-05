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

  // Phase 3: Family Collaboration fields
  final String? assignedToId; // Family member assigned to this task
  final String? assignedToName; // Cached name for display
  final List<String>? sharedWith; // List of family member IDs who can see/edit
  final String? completedById; // Who completed the task
  final String? completedByName; // Cached name
  final int commentsCount; // Number of comments

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
    // Family Collaboration fields with defaults
    this.assignedToId,
    this.assignedToName,
    this.sharedWith,
    this.completedById,
    this.completedByName,
    this.commentsCount = 0,
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
        // Family Collaboration fields
        assignedToId,
        assignedToName,
        sharedWith,
        completedById,
        completedByName,
        commentsCount,
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

  /// Convert entity to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'todoDate': todoDate.toIso8601String(),
      'todoTime': todoTime?.toIso8601String(),
      'priority': priority,
      'type': type,
      'status': status,
      'location': location,
      'locationLat': locationLat,
      'locationLng': locationLng,
      'notificationEnabled': notificationEnabled,
      'notificationMinutesBefore': notificationMinutesBefore,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      // Phase 2 fields
      'travelTimeMinutes': travelTimeMinutes,
      'geofenceRadiusMeters': geofenceRadiusMeters,
      'weatherDependent': weatherDependent,
      'trafficAware': trafficAware,
      'preparationTimeMinutes': preparationTimeMinutes,
      'lastTrafficCheck': lastTrafficCheck?.toIso8601String(),
      'lastWeatherCheck': lastWeatherCheck?.toIso8601String(),
      'estimatedDepartureTime': estimatedDepartureTime?.toIso8601String(),
      // Recurrence fields
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceWeekdays': recurrenceWeekdays,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'recurrenceParentId': recurrenceParentId,
      'isRecurrenceInstance': isRecurrenceInstance,
      // Family Collaboration fields
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'sharedWith': sharedWith,
      'completedById': completedById,
      'completedByName': completedByName,
      'commentsCount': commentsCount,
    };
  }

  /// Create entity from JSON
  factory TodoEntity.fromJson(Map<String, dynamic> json) {
    return TodoEntity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      todoDate: DateTime.parse(json['todoDate'] as String),
      todoTime: json['todoTime'] != null ? DateTime.parse(json['todoTime'] as String) : null,
      priority: json['priority'] as int? ?? 3,
      type: json['type'] as String? ?? 'other',
      status: json['status'] as String? ?? 'pending',
      location: json['location'] as String?,
      locationLat: json['locationLat'] as double?,
      locationLng: json['locationLng'] as double?,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      notificationMinutesBefore: json['notificationMinutesBefore'] as int? ?? 30,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      // Phase 2 fields
      travelTimeMinutes: json['travelTimeMinutes'] as int? ?? 0,
      geofenceRadiusMeters: json['geofenceRadiusMeters'] as int? ?? 500,
      weatherDependent: json['weatherDependent'] as bool? ?? false,
      trafficAware: json['trafficAware'] as bool? ?? true,
      preparationTimeMinutes: json['preparationTimeMinutes'] as int? ?? 15,
      lastTrafficCheck: json['lastTrafficCheck'] != null ? DateTime.parse(json['lastTrafficCheck'] as String) : null,
      lastWeatherCheck: json['lastWeatherCheck'] != null ? DateTime.parse(json['lastWeatherCheck'] as String) : null,
      estimatedDepartureTime: json['estimatedDepartureTime'] != null ? DateTime.parse(json['estimatedDepartureTime'] as String) : null,
      // Recurrence fields
      isRecurring: json['isRecurring'] as bool? ?? false,
      recurrencePattern: json['recurrencePattern'] as String?,
      recurrenceInterval: json['recurrenceInterval'] as int?,
      recurrenceWeekdays: (json['recurrenceWeekdays'] as List<dynamic>?)?.map((e) => e as int).toList(),
      recurrenceEndDate: json['recurrenceEndDate'] != null ? DateTime.parse(json['recurrenceEndDate'] as String) : null,
      recurrenceParentId: json['recurrenceParentId'] as String?,
      isRecurrenceInstance: json['isRecurrenceInstance'] as bool? ?? false,
      // Family Collaboration fields
      assignedToId: json['assignedToId'] as String?,
      assignedToName: json['assignedToName'] as String?,
      sharedWith: (json['sharedWith'] as List<dynamic>?)?.map((e) => e as String).toList(),
      completedById: json['completedById'] as String?,
      completedByName: json['completedByName'] as String?,
      commentsCount: json['commentsCount'] as int? ?? 0,
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
    // Family Collaboration fields
    String? assignedToId,
    String? assignedToName,
    List<String>? sharedWith,
    String? completedById,
    String? completedByName,
    int? commentsCount,
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
      // Family Collaboration fields
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      sharedWith: sharedWith ?? this.sharedWith,
      completedById: completedById ?? this.completedById,
      completedByName: completedByName ?? this.completedByName,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}
