import 'package:flutter/material.dart';
import '../../../todos/domain/entities/todo_entity.dart';

/// Smart task card (placeholder for future enhancements)
class SmartTaskCard extends StatelessWidget {
  final TodoEntity task;

  const SmartTaskCard({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(task.title),
        subtitle: task.description != null ? Text(task.description!) : null,
      ),
    );
  }
}
