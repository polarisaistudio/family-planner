import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../todos/presentation/providers/todo_providers.dart';
import '../../../todos/domain/entities/todo_entity.dart';
import '../widgets/todo_list_item.dart';
import '../widgets/add_todo_dialog.dart';
import '../../../smart_planning/presentation/widgets/smart_suggestions_card.dart';
import '../../../smart_planning/presentation/providers/smart_planning_provider.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isSelectionMode = false;
  final Set<String> _selectedTodoIds = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTodoIds.clear();
      }
    });
  }

  void _toggleTodoSelection(String todoId) {
    setState(() {
      if (_selectedTodoIds.contains(todoId)) {
        _selectedTodoIds.remove(todoId);
      } else {
        _selectedTodoIds.add(todoId);
      }
    });
  }

  Future<void> _deleteSelectedTodos() async {
    if (_selectedTodoIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tasks'),
        content: Text('Are you sure you want to delete ${_selectedTodoIds.length} task(s)?'),
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

    if (confirmed == true) {
      try {
        for (final todoId in _selectedTodoIds) {
          await ref.read(todosProvider.notifier).deleteTodo(todoId);
        }
        setState(() {
          _selectedTodoIds.clear();
          _isSelectionMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedTodoIds.length} task(s) deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete tasks: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _analyzeSelectedDay(List<TodoEntity> todos) {
    final selectedDayTodos = _getTodosForDay(todos, _selectedDay ?? DateTime.now());
    if (selectedDayTodos.isNotEmpty) {
      // Analyze todos for the selected day
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(smartPlanningProvider.notifier).analyzeDayTodos(selectedDayTodos);
      });
    }
  }

  List<TodoEntity> _getTodosForDay(List<TodoEntity> todos, DateTime day) {
    return todos.where((todo) {
      return isSameDay(todo.todoDate, day);
    }).toList();
  }

  Future<void> _showAddTodoDialog() async {
    final dateToUse = _selectedDay ?? DateTime.now();
    print('🔵 [CALENDAR] Opening dialog with date: $dateToUse (day: ${dateToUse.day})');
    await showDialog(
      context: context,
      builder: (context) => AddTodoDialog(selectedDate: dateToUse),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(currentUserProvider);
    final todosState = ref.watch(todosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '${_selectedTodoIds.length} selected' : 'Family Planner'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (_isSelectionMode) ...[
            if (_selectedTodoIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedTodos,
                tooltip: 'Delete selected',
              ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select multiple',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.read(todosProvider.notifier).loadTodos();
              },
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                await ref.read(currentUserProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(
                      userState.maybeWhen(
                        data: (user) => user?.fullName ?? user?.email ?? 'User',
                        orElse: () => 'User',
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: todosState.when(
        data: (todos) {
          final selectedDayTodos = _getTodosForDay(todos, _selectedDay ?? DateTime.now());

          return Column(
            children: [
              // Calendar Widget
              Card(
                margin: const EdgeInsets.all(8),
                child: TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    // Analyze the newly selected day
                    _analyzeSelectedDay(todos);
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: (day) => _getTodosForDay(todos, day),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

              // Selected Date Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDay != null
                          ? DateFormat('EEEE, MMMM d').format(_selectedDay!)
                          : 'Select a date',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${selectedDayTodos.length} tasks',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Smart Suggestions
              const SmartSuggestionsCard(),

              // Todos List
              Expanded(
                child: selectedDayTodos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_available,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks for this day',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: selectedDayTodos.length,
                        itemBuilder: (context, index) {
                          final todo = selectedDayTodos[index];
                          return TodoListItem(
                            todo: todo,
                            isSelectionMode: _isSelectionMode,
                            isSelected: _selectedTodoIds.contains(todo.id),
                            onSelectionChanged: () => _toggleTodoSelection(todo.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(todosProvider.notifier).loadTodos();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
