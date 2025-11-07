import 'package:flutter/material.dart';
import 'package:family_planner/features/todos/domain/entities/subtask_entity.dart';
import 'package:family_planner/shared/widgets/translated_text.dart';

class SubtaskListWidget extends StatelessWidget {
  final List<SubtaskEntity> subtasks;
  final Function(String subtaskId, bool isCompleted) onSubtaskToggled;
  final Function(String subtaskId) onSubtaskDeleted;
  final Function(int oldIndex, int newIndex)? onSubtaskReordered;
  final bool isEditing;

  const SubtaskListWidget({
    Key? key,
    required this.subtasks,
    required this.onSubtaskToggled,
    required this.onSubtaskDeleted,
    this.onSubtaskReordered,
    this.isEditing = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (subtasks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort subtasks by order
    final sortedSubtasks = List<SubtaskEntity>.from(subtasks)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Subtasks',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            _buildProgressIndicator(context),
          ],
        ),
        const SizedBox(height: 12),
        if (isEditing && onSubtaskReordered != null)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedSubtasks.length,
            onReorder: onSubtaskReordered!,
            itemBuilder: (context, index) {
              final subtask = sortedSubtasks[index];
              return _buildSubtaskItem(context, subtask, index, key: ValueKey(subtask.id));
            },
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedSubtasks.length,
            itemBuilder: (context, index) {
              final subtask = sortedSubtasks[index];
              return _buildSubtaskItem(context, subtask, index);
            },
          ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    final completed = subtasks.where((s) => s.isCompleted).length;
    final total = subtasks.length;
    final percentage = total > 0 ? (completed / total * 100).toInt() : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: percentage == 100
            ? Colors.green.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$completed/$total ($percentage%)',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: percentage == 100
              ? Colors.green.shade700
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  Widget _buildSubtaskItem(
    BuildContext context,
    SubtaskEntity subtask,
    int index, {
    Key? key,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing && onSubtaskReordered != null)
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
              ),
            Checkbox(
              value: subtask.isCompleted,
              onChanged: (value) {
                onSubtaskToggled(subtask.id, value ?? false);
              },
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        title: TranslatedText(
          subtask.title,
          style: TextStyle(
            fontSize: 14,
            decoration: subtask.isCompleted ? TextDecoration.lineThrough : null,
            color: subtask.isCompleted ? Colors.grey : null,
          ),
        ),
        trailing: isEditing
            ? IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => onSubtaskDeleted(subtask.id),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            : null,
      ),
    );
  }
}
