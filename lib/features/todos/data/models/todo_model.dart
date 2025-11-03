import 'package:intl/intl.dart';
import '../../domain/entities/todo_entity.dart';

/// Data model for Todo (handles serialization/deserialization)
class TodoModel extends TodoEntity {
  const TodoModel({
    required super.id,
    required super.userId,
    required super.title,
    super.description,
    required super.todoDate,
    super.todoTime,
    super.priority,
    super.type,
    super.status,
    super.location,
    super.locationLat,
    super.locationLng,
    super.notificationEnabled,
    super.notificationMinutesBefore,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create from JSON
  factory TodoModel.fromJson(Map<String, dynamic> json) {
    DateTime? todoTime;
    if (json['todo_time'] != null) {
      // Parse time from string format "HH:mm:ss"
      final timeString = json['todo_time'] as String;
      final timeParts = timeString.split(':');
      todoTime = DateTime(
        0,
        1,
        1,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    }

    return TodoModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      todoDate: DateTime.parse(json['todo_date'] as String),
      todoTime: todoTime,
      priority: json['priority'] as int? ?? 3,
      type: json['type'] as String? ?? 'other',
      status: json['status'] as String? ?? 'pending',
      location: json['location'] as String?,
      locationLat: json['location_lat'] as double?,
      locationLng: json['location_lng'] as double?,
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      notificationMinutesBefore:
          json['notification_minutes_before'] as int? ?? 30,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    String? todoTimeString;
    if (todoTime != null) {
      // Format time as "HH:mm:ss"
      todoTimeString = DateFormat('HH:mm:ss').format(todoTime!);
    }

    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'todo_date': DateFormat('yyyy-MM-dd').format(todoDate),
      'todo_time': todoTimeString,
      'priority': priority,
      'type': type,
      'status': status,
      'location': location,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'notification_enabled': notificationEnabled,
      'notification_minutes_before': notificationMinutesBefore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Create from entity
  factory TodoModel.fromEntity(TodoEntity entity) {
    return TodoModel(
      id: entity.id,
      userId: entity.userId,
      title: entity.title,
      description: entity.description,
      todoDate: entity.todoDate,
      todoTime: entity.todoTime,
      priority: entity.priority,
      type: entity.type,
      status: entity.status,
      location: entity.location,
      locationLat: entity.locationLat,
      locationLng: entity.locationLng,
      notificationEnabled: entity.notificationEnabled,
      notificationMinutesBefore: entity.notificationMinutesBefore,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to entity
  TodoEntity toEntity() {
    return TodoEntity(
      id: id,
      userId: userId,
      title: title,
      description: description,
      todoDate: todoDate,
      todoTime: todoTime,
      priority: priority,
      type: type,
      status: status,
      location: location,
      locationLat: locationLat,
      locationLng: locationLng,
      notificationEnabled: notificationEnabled,
      notificationMinutesBefore: notificationMinutesBefore,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
