import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../todos/domain/entities/todo_entity.dart';
import '../../../todos/presentation/providers/todo_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../shared/utils/recurrence_helper.dart';

class AddTodoDialog extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const AddTodoDialog({
    super.key,
    required this.selectedDate,
  });

  @override
  ConsumerState<AddTodoDialog> createState() => _AddTodoDialogState();
}

class _AddTodoDialogState extends ConsumerState<AddTodoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  int _priority = AppConstants.priorityMedium;
  String _type = AppConstants.todoTypePersonal;
  bool _isLoading = false;

  // Recurrence fields
  bool _isRecurring = false;
  String _recurrencePattern = 'daily';
  int _recurrenceInterval = 1;
  List<int> _selectedWeekdays = [];
  DateTime? _recurrenceEndDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create DateTime for time if selected
      DateTime? todoTime;
      if (_selectedTime != null) {
        todoTime = DateTime(
          2000,
          1,
          1,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      // Normalize the date to midnight local time to avoid timezone issues
      final normalizedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
      );

      print('🔵 [ADD TODO] Selected date: $_selectedDate');
      print('🔵 [ADD TODO] Normalized date: $normalizedDate');

      final todo = TodoEntity(
        id: const Uuid().v4(),
        userId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        todoDate: normalizedDate,
        todoTime: todoTime,
        priority: _priority,
        type: _type,
        status: AppConstants.statusPending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isRecurring: _isRecurring,
        recurrencePattern: _isRecurring ? _recurrencePattern : null,
        recurrenceInterval: _isRecurring ? _recurrenceInterval : null,
        recurrenceWeekdays: _isRecurring && _recurrencePattern == 'weekly'
            ? _selectedWeekdays
            : null,
        recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
      );

      if (_isRecurring) {
        // Generate recurring instances for the next 365 days
        final endDate = _recurrenceEndDate ?? normalizedDate.add(const Duration(days: 365));
        final instances = RecurrenceHelper.generateRecurringInstances(
          parentTodo: todo,
          startDate: normalizedDate,
          endDate: endDate,
        );

        print('🔵 [ADD TODO] Creating ${instances.length} recurring instances');

        // Create all instances in a single batch to avoid multiple UI re-renders
        await ref.read(todosProvider.notifier).createTodosBatch(instances);

        print('🟢 [ADD TODO] Batch creation complete');
      } else {
        await ref.read(todosProvider.notifier).createTodo(todo);
      }

      if (!mounted) return;

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create task: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _handleSubmit(),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getIntervalLabel() {
    switch (_recurrencePattern) {
      case 'daily':
        return _recurrenceInterval == 1 ? 'day' : 'days';
      case 'weekly':
        return _recurrenceInterval == 1 ? 'week' : 'weeks';
      case 'monthly':
        return _recurrenceInterval == 1 ? 'month' : 'months';
      case 'yearly':
        return _recurrenceInterval == 1 ? 'year' : 'years';
      default:
        return '';
    }
  }

  Widget _buildWeekdayChip(String label, int weekday) {
    final isSelected = _selectedWeekdays.contains(weekday);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedWeekdays.add(weekday);
          } else {
            _selectedWeekdays.remove(weekday);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add New Task',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),

                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter task title',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Enter task description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Date
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
                  onTap: _selectDate,
                ),

                // Time
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time (optional)'),
                  subtitle: Text(
                    _selectedTime != null
                        ? _selectedTime!.format(context)
                        : 'No time set',
                  ),
                  onTap: _selectTime,
                  trailing: _selectedTime != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _selectedTime = null);
                          },
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Type
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: AppConstants.todoTypeAppointment,
                      child: Text('Appointment'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.todoTypeWork,
                      child: Text('Work'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.todoTypeShopping,
                      child: Text('Shopping'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.todoTypePersonal,
                      child: Text('Personal'),
                    ),
                    DropdownMenuItem(
                      value: AppConstants.todoTypeOther,
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _type = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Priority
                DropdownButtonFormField<int>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Urgent (P1)')),
                    DropdownMenuItem(value: 2, child: Text('High (P2)')),
                    DropdownMenuItem(value: 3, child: Text('Medium (P3)')),
                    DropdownMenuItem(value: 4, child: Text('Low (P4)')),
                    DropdownMenuItem(value: 5, child: Text('None (P5)')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _priority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Recurrence Section
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeat'),
                  subtitle: _isRecurring
                      ? Text(
                          RecurrenceHelper.getRecurrenceDescription(
                            pattern: _recurrencePattern,
                            interval: _recurrenceInterval,
                            weekdays: _selectedWeekdays.isEmpty ? null : _selectedWeekdays,
                            endDate: _recurrenceEndDate,
                          ),
                          style: const TextStyle(fontSize: 12),
                        )
                      : const Text('Does not repeat'),
                  value: _isRecurring,
                  onChanged: (value) {
                    setState(() => _isRecurring = value);
                  },
                ),

                if (_isRecurring) ...[
                  const SizedBox(height: 8),

                  // Recurrence Pattern
                  DropdownButtonFormField<String>(
                    value: _recurrencePattern,
                    decoration: const InputDecoration(
                      labelText: 'Repeat Pattern',
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                      DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _recurrencePattern = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Recurrence Interval
                  Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text('Repeat every'),
                      ),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<int>(
                          value: _recurrenceInterval,
                          items: List.generate(30, (i) => i + 1)
                              .map((i) => DropdownMenuItem(
                                    value: i,
                                    child: Text('$i'),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _recurrenceInterval = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(_getIntervalLabel()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Weekday Selection (for weekly recurrence)
                  if (_recurrencePattern == 'weekly') ...[
                    const Text(
                      'Repeat on:',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildWeekdayChip('Mon', 1),
                        _buildWeekdayChip('Tue', 2),
                        _buildWeekdayChip('Wed', 3),
                        _buildWeekdayChip('Thu', 4),
                        _buildWeekdayChip('Fri', 5),
                        _buildWeekdayChip('Sat', 6),
                        _buildWeekdayChip('Sun', 7),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // End Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_busy),
                    title: const Text('Ends'),
                    subtitle: Text(
                      _recurrenceEndDate != null
                          ? DateFormat('MMM d, yyyy').format(_recurrenceEndDate!)
                          : 'Never',
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _recurrenceEndDate ?? _selectedDate.add(const Duration(days: 30)),
                        firstDate: _selectedDate,
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        setState(() => _recurrenceEndDate = date);
                      }
                    },
                    trailing: _recurrenceEndDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() => _recurrenceEndDate = null);
                            },
                          )
                        : null,
                  ),
                ],

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
