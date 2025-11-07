import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/themes/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../todos/domain/entities/todo_entity.dart';
import '../../../todos/domain/entities/category_entity.dart';
import '../../../todos/presentation/providers/todo_providers.dart';
import '../../../todos/services/providers/todo_notification_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/widgets/translated_text.dart';
import '../../../smart_planning/presentation/providers/smart_planning_provider.dart';
import '../../../smart_planning/presentation/providers/permission_provider.dart';
import 'add_todo_dialog.dart';

class TodoListItem extends ConsumerStatefulWidget {
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

  @override
  ConsumerState<TodoListItem> createState() => _TodoListItemState();
}

class _TodoListItemState extends ConsumerState<TodoListItem> {
  bool _showSuggestions = false;
  List<SmartSuggestion> _suggestions = [];
  bool _isLoadingSuggestions = false;

  @override
  void initState() {
    super.initState();
    // Don't auto-load suggestions to avoid memory issues
    // Suggestions will load on-demand when user interacts
  }

  Future<void> _loadSuggestions() async {
    // Don't reload if already loaded or currently loading
    if (_isLoadingSuggestions || _suggestions.isNotEmpty) return;

    setState(() => _isLoadingSuggestions = true);

    try {
      // Check if we have location permissions
      final permissionNotifier = ref.read(permissionProvider.notifier);
      final permissionState = ref.read(permissionProvider);

      if (!permissionState.hasLocation) {
        // Request permissions if not granted
        print('💡 Requesting location permission for suggestions...');
        await permissionNotifier.requestAllPermissions();

        // Check again after request
        final updatedState = ref.read(permissionProvider);
        if (!updatedState.hasLocation) {
          // User denied permission, show message
          if (mounted) {
            setState(() => _isLoadingSuggestions = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission is required for smart suggestions. Please enable it in Settings.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
      }

      print('💡 Loading suggestions for ${widget.todo.title}...');
      final suggestions = await ref
          .read(smartPlanningProvider.notifier)
          .analyzeSingleTodo(widget.todo);

      print('💡 Got ${suggestions.length} suggestions for ${widget.todo.title}');
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      print('❌ Error loading suggestions for ${widget.todo.title}: $e');
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

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

  Widget _buildSuggestionItem(BuildContext context, SmartSuggestion suggestion) {
    Color color;
    IconData icon;

    switch (suggestion.type) {
      case 'location':
        color = Colors.blue;
        icon = Icons.location_on;
        break;
      case 'weather':
        color = Colors.orange;
        icon = Icons.wb_sunny;
        break;
      case 'time':
        color = Colors.red;
        icon = Icons.access_time;
        break;
      case 'traffic':
        color = Colors.purple;
        icon = Icons.traffic;
        break;
      default:
        color = Colors.grey;
        icon = Icons.lightbulb;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: TranslatedText(
                  suggestion.message,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (suggestion.actionText != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _handleSuggestionAction(context, suggestion),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                ),
                icon: const Icon(Icons.alarm_add, size: 16),
                label: TranslatedText(
                  suggestion.actionText!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSuggestionAction(BuildContext context, SmartSuggestion suggestion) async {
    if (suggestion.actionText == 'Set reminder' || suggestion.actionText == 'Set time') {
      if (suggestion.suggestedTime != null && mounted) {
        await _showReminderDialog(context, suggestion);
      } else {
        // If no suggested time, open edit dialog to set time first
        showDialog(
          context: context,
          builder: (context) => AddTodoDialog(
            selectedDate: widget.todo.todoDate,
            todoToEdit: widget.todo,
          ),
        );
      }
    }
  }

  Future<void> _showReminderDialog(BuildContext context, SmartSuggestion suggestion) async {
    final suggestedTime = suggestion.suggestedTime!;
    DateTime? selectedReminderTime = suggestedTime;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final timeStr = DateFormat('MMM d, h:mm a').format(selectedReminderTime!);
          final breakdown = suggestion.travelTimeMinutes != null
              ? '${suggestion.travelTimeMinutes}min travel + ${suggestion.prepTimeMinutes}min prep'
              : null;

          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.alarm_add, color: Colors.blue),
                SizedBox(width: 8),
                Text('Set Reminder'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'For: ${widget.todo.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 20, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            timeStr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      if (breakdown != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          breakdown,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(selectedReminderTime!),
                    );
                    if (picked != null && selectedReminderTime != null) {
                      setState(() {
                        selectedReminderTime = DateTime(
                          selectedReminderTime!.year,
                          selectedReminderTime!.month,
                          selectedReminderTime!.day,
                          picked.hour,
                          picked.minute,
                        );
                      });
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Change time'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.alarm_add),
                label: const Text('Set Reminder'),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Actually schedule the reminder/notification
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Reminder set for ${DateFormat('h:mm a').format(selectedReminderTime!)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildSuggestionsCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoadingSuggestions)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_suggestions.isEmpty)
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                    size: 16,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No suggestions for this task',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else
              ..._suggestions.map((suggestion) => _buildSuggestionItem(context, suggestion)).toList(),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.getPriorityColor(widget.todo.priority);

    // Get category if exists
    CategoryEntity? category;
    if (widget.todo.category != null) {
      category = PredefinedCategories.categories
          .where((c) => c.id == widget.todo.category)
          .firstOrNull;
    }

    // Check if we should show suggestion button (has location or no time set for high priority)
    final bool canHaveSuggestions = widget.todo.location != null && widget.todo.location!.isNotEmpty ||
        (widget.todo.todoTime == null && widget.todo.priority <= 2);

    // Debug: Print to see which todos can have suggestions
    if (canHaveSuggestions) {
      print('🔍 Todo "${widget.todo.title}" can have suggestions - location: ${widget.todo.location}, time: ${widget.todo.todoTime}, priority: ${widget.todo.priority}');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: widget.isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
      child: ListTile(
        onTap: () {
          if (widget.isSelectionMode) {
            widget.onSelectionChanged?.call();
          } else {
            // Open edit dialog
            showDialog(
              context: context,
              builder: (context) => AddTodoDialog(
                selectedDate: widget.todo.todoDate,
                todoToEdit: widget.todo,
              ),
            );
          }
        },
        leading: widget.isSelectionMode
            ? Checkbox(
                value: widget.isSelected,
                onChanged: (_) => widget.onSelectionChanged?.call(),
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
        title: TranslatedText(
          widget.todo.title,
          style: TextStyle(
            decoration: widget.todo.isCompleted ? TextDecoration.lineThrough : null,
            color: widget.todo.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.todo.description != null && widget.todo.description!.isNotEmpty)
              TranslatedText(
                widget.todo.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _getTypeIcon(widget.todo.type),
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                TranslatedText(
                  widget.todo.type,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                if (widget.todo.todoTime != null) ...[
                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(widget.todo.todoTime!),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ],
            ),
            // Display subtask progress
            if (widget.todo.hasSubtasks) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.checklist,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.subtasksCount(widget.todo.subtasksCompleted, widget.todo.subtasksTotal),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: widget.todo.subtaskCompletionPercentage,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.todo.subtaskCompletionPercentage == 1.0
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ],
            // Display tags
            if (widget.todo.tags != null && widget.todo.tags!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: widget.todo.tags!.take(3).map((tag) {
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
                    widget.todo.tags!.length > 3
                        ? [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                '+${widget.todo.tags!.length - 3}',
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
            // Smart suggestions button and expandable section
            if (canHaveSuggestions && !widget.isSelectionMode) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (!_showSuggestions && _suggestions.isEmpty) {
                        _loadSuggestions();
                      }
                      setState(() {
                        _showSuggestions = !_showSuggestions;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showSuggestions ? Icons.expand_less : Icons.lightbulb_outline,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isLoadingSuggestions
                                ? 'Loading...'
                                : _showSuggestions
                                    ? 'Hide suggestions'
                                    : 'Smart suggestions',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_suggestions.isNotEmpty && !_showSuggestions) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _suggestions.any((s) => s.isUrgent)
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_suggestions.length}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: widget.isSelectionMode
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
                'P${widget.todo.priority}',
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
              value: widget.todo.isCompleted,
              onChanged: (value) async {
                try {
                  // Check if task is being completed (not uncompleted)
                  final wasCompleted = widget.todo.isCompleted;

                  await ref.read(todosProvider.notifier).toggleTodoStatus(widget.todo.id);

                  // Send notification if task was just completed
                  if (!wasCompleted && value == true) {
                    final user = ref.read(currentUserProvider).value;
                    if (user != null) {
                      final notificationService = ref.read(todoNotificationServiceProvider);
                      await notificationService.notifyTaskCompleted(
                        todo: widget.todo,
                        completedByName: user.fullName ?? 'Someone',
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.failedToUpdate(e.toString())),
                        backgroundColor: Colors.red,
                        action: SnackBarAction(
                          label: AppLocalizations.of(context)!.retry,
                          textColor: Colors.white,
                          onPressed: () async {
                            try {
                              await ref.read(todosProvider.notifier).toggleTodoStatus(widget.todo.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.updateSuccessful),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (retryError) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.retryFailed(retryError.toString())),
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

                if (widget.todo.isRecurring || widget.todo.isRecurrenceInstance) {
                  // Show options for recurring events
                  deleteOption = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppLocalizations.of(context)!.deleteRecurringTask),
                      content: Text(AppLocalizations.of(context)!.thisIsRecurringTask),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, null),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'this'),
                          child: Text(AppLocalizations.of(context)!.deleteThisTaskOnly),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'all'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text(AppLocalizations.of(context)!.deleteAllRecurringTasks),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Regular delete confirmation
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(AppLocalizations.of(context)!.deleteTask),
                      content: Text(AppLocalizations.of(context)!.confirmDeleteTask),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: Text(AppLocalizations.of(context)!.delete),
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
                      final parentId = widget.todo.recurrenceParentId ?? widget.todo.id;
                      await ref.read(todosProvider.notifier).deleteRecurringTodos(parentId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.allRecurringTasksDeleted),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      // Delete only this instance
                      await ref.read(todosProvider.notifier).deleteTodo(widget.todo.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)!.taskDeletedSuccess),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.failedToDelete(e.toString())),
                          backgroundColor: Colors.red,
                          action: SnackBarAction(
                            label: AppLocalizations.of(context)!.retry,
                            textColor: Colors.white,
                            onPressed: () async {
                              try {
                                await ref.read(todosProvider.notifier).deleteTodo(widget.todo.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.taskDeletedSuccess),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (retryError) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.retryFailed(retryError.toString())),
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
    ),
        // Show suggestions card below the todo card when expanded
        if (_showSuggestions && canHaveSuggestions && !widget.isSelectionMode)
          _buildSuggestionsCard(context),
      ],
    );
  }
}
