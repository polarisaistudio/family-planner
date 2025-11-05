import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../todos/domain/entities/todo_entity.dart';
import '../../../todos/domain/entities/category_entity.dart';
import '../../../todos/presentation/providers/todo_providers.dart';
import '../../../todos/services/providers/todo_notification_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import 'add_todo_dialog.dart';

class TodoListItem extends ConsumerWidget {
  final TodoEntity todo;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;

  const TodoListItem({
    super.key,
    required this.todo,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionChanged,
  });

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.medical_services;
      case 'work':
        return Icons.work;
      case 'shopping':
        return Icons.shopping_cart;
      case 'personal':
        return Icons.person;
      default:
        return Icons.event;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priorityColor = AppTheme.getPriorityColor(todo.priority);

    // Get category if exists
    CategoryEntity? category;
    if (todo.category != null) {
      category = PredefinedCategories.categories
          .where((c) => c.id == todo.category)
          .firstOrNull;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
      child: ListTile(
        onTap: () {
          if (isSelectionMode) {
            onSelectionChanged?.call();
          } else {
            // Open edit dialog
            showDialog(
              context: context,
              builder: (context) => AddTodoDialog(
                selectedDate: todo.todoDate,
                todoToEdit: todo,
              ),
            );
          }
        },
        leading: isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onSelectionChanged?.call(),
              )
            : category != null
                ? CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(category.colorValue).withValues(alpha: 0.2),
                    child: Icon(
                      IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                      color: Color(category.colorValue),
                      size: 20,
                    ),
                  )
                : Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.description != null && todo.description!.isNotEmpty)
              Text(
                todo.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getTypeIcon(todo.type),
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  todo.type.toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                if (todo.todoTime != null) ...[
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(todo.todoTime!),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            // Display tags
            if (todo.tags != null && todo.tags!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: todo.tags!.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  );
                }).toList()
                  ..addAll(
                    todo.tags!.length > 3
                        ? [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                '+${todo.tags!.length - 3}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ]
                        : [],
                  ),
              ),
            ],
          ],
        ),
        trailing: isSelectionMode
            ? null
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Priority Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'P${todo.priority}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: priorityColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Complete Checkbox
            Checkbox(
              value: todo.isCompleted,
              onChanged: (value) async {
                try {
                  // Check if task is being completed (not uncompleted)
                  final wasCompleted = todo.isCompleted;

                  await ref.read(todosProvider.notifier).toggleTodoStatus(todo.id);

                  // Send notification if task was just completed
                  if (!wasCompleted && value == true) {
                    final user = ref.read(currentUserProvider).value;
                    if (user != null) {
                      final notificationService = ref.read(todoNotificationServiceProvider);
                      await notificationService.notifyTaskCompleted(
                        todo: todo,
                        completedByName: user.fullName ?? 'Someone',
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update: $e'),
                        backgroundColor: Colors.red,
                        action: SnackBarAction(
                          label: 'Retry',
                          textColor: Colors.white,
                          onPressed: () async {
                            try {
                              await ref.read(todosProvider.notifier).toggleTodoStatus(todo.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Update successful'),
                                    backgroundColor: Colors.green,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (retryError) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Retry failed: $retryError'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
            ),
            // Delete Button
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () async {
                String? deleteOption;

                if (todo.isRecurring || todo.isRecurrenceInstance) {
                  // Show options for recurring events
                  deleteOption = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Recurring Task'),
                      content: const Text('This is a recurring task. What would you like to delete?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'this'),
                          child: const Text('This task only'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'all'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('All recurring tasks'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Regular delete confirmation
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Task'),
                      content: const Text('Are you sure you want to delete this task?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) deleteOption = 'this';
                }

                if (deleteOption != null) {
                  try {
                    if (deleteOption == 'all') {
                      // Delete all recurring instances
                      final parentId = todo.recurrenceParentId ?? todo.id;
                      await ref.read(todosProvider.notifier).deleteRecurringTodos(parentId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All recurring tasks deleted'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      // Delete only this instance
                      await ref.read(todosProvider.notifier).deleteTodo(todo.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Task deleted'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete: $e'),
                          backgroundColor: Colors.red,
                          action: SnackBarAction(
                            label: 'Retry',
                            textColor: Colors.white,
                            onPressed: () async {
                              try {
                                await ref.read(todosProvider.notifier).deleteTodo(todo.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Task deleted'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (retryError) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Retry failed: $retryError'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
