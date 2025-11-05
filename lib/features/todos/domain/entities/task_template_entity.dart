import 'package:equatable/equatable.dart';

/// Entity representing a reusable task template
class TaskTemplateEntity extends Equatable {
  final String id;
  final String userId; // Creator of the template
  final String title;
  final String? description;
  final String? category;
  final List<String>? tags;
  final int priority;
  final String type;
  final List<TaskTemplateSubtask>? subtasks;
  final bool isPredefined; // System templates vs user templates
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskTemplateEntity({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.category,
    this.tags,
    required this.priority,
    required this.type,
    this.subtasks,
    required this.isPredefined,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with modified fields
  TaskTemplateEntity copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    int? priority,
    String? type,
    List<TaskTemplateSubtask>? subtasks,
    bool? isPredefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskTemplateEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      subtasks: subtasks ?? this.subtasks,
      isPredefined: isPredefined ?? this.isPredefined,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'priority': priority,
      'type': type,
      'subtasks': subtasks?.map((s) => s.toJson()).toList(),
      'isPredefined': isPredefined,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory TaskTemplateEntity.fromJson(Map<String, dynamic> json) {
    return TaskTemplateEntity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      priority: json['priority'] as int? ?? 3,
      type: json['type'] as String? ?? 'personal',
      subtasks: (json['subtasks'] as List<dynamic>?)
          ?.map((e) => TaskTemplateSubtask.fromJson(e as Map<String, dynamic>))
          .toList(),
      isPredefined: json['isPredefined'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        category,
        tags,
        priority,
        type,
        subtasks,
        isPredefined,
        createdAt,
        updatedAt,
      ];
}

/// Simplified subtask for templates (no completion state)
class TaskTemplateSubtask extends Equatable {
  final String title;
  final int order;

  const TaskTemplateSubtask({
    required this.title,
    required this.order,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'order': order,
    };
  }

  factory TaskTemplateSubtask.fromJson(Map<String, dynamic> json) {
    return TaskTemplateSubtask(
      title: json['title'] as String,
      order: json['order'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [title, order];
}
