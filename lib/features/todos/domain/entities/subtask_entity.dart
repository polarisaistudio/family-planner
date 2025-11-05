import 'package:equatable/equatable.dart';

/// Entity representing a subtask/checklist item within a todo
class SubtaskEntity extends Equatable {
  final String id;
  final String todoId; // Parent todo ID
  final String title;
  final bool isCompleted;
  final int order; // For sorting subtasks
  final DateTime createdAt;
  final DateTime? completedAt;

  const SubtaskEntity({
    required this.id,
    required this.todoId,
    required this.title,
    required this.isCompleted,
    required this.order,
    required this.createdAt,
    this.completedAt,
  });

  /// Create a copy with modified fields
  SubtaskEntity copyWith({
    String? id,
    String? todoId,
    String? title,
    bool? isCompleted,
    int? order,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return SubtaskEntity(
      id: id ?? this.id,
      todoId: todoId ?? this.todoId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'todoId': todoId,
      'title': title,
      'isCompleted': isCompleted,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory SubtaskEntity.fromJson(Map<String, dynamic> json) {
    return SubtaskEntity(
      id: json['id'] as String,
      todoId: json['todoId'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        todoId,
        title,
        isCompleted,
        order,
        createdAt,
        completedAt,
      ];
}
