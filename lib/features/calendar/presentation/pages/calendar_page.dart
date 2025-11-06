import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../todos/presentation/providers/todo_providers.dart';
import '../../../todos/domain/entities/todo_entity.dart';
import '../../../todos/domain/entities/category_entity.dart';
import '../widgets/todo_list_item.dart';
import '../widgets/add_todo_dialog.dart';
import '../../../smart_planning/presentation/widgets/smart_suggestions_card.dart';
import '../../../smart_planning/presentation/providers/smart_planning_provider.dart';
import '../../../smart_planning/presentation/pages/daily_planning_page.dart';
import '../../../family/presentation/pages/family_members_page.dart';
import '../../../settings/presentation/pages/settings_page.dart';
import '../../../../l10n/app_localizations.dart';

class CalendarPage extends ConsumerStatefulWidget {
  final String? initialTaskId;
  final bool shouldOpenTask;

  const CalendarPage({
    super.key,
    this.initialTaskId,
    this.shouldOpenTask = false,
  });

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

enum TaskFilter { all, myTasks }

class _CalendarPageState extends ConsumerState<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  bool _isSelectionMode = false;
  final Set<String> _selectedTodoIds = {};
  TaskFilter _taskFilter = TaskFilter.all;
  String? _categoryFilter; // null means show all categories

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // Open task dialog after the widget is built if navigated from notification
    if (widget.shouldOpenTask && widget.initialTaskId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openTaskFromNotification(widget.initialTaskId!);
      });
    }
  }

  /// Open task dialog when navigating from a notification
  void _openTaskFromNotification(String taskId) async {
    try {
      print('📋 Opening task from notification: $taskId');

      // Get all todos to find the one with matching ID
      final todosAsyncValue = ref.read(todosProvider);

      todosAsyncValue.when(
        data: (todos) {
          final task = todos.firstWhere(
            (todo) => todo.id == taskId,
            orElse: () => throw Exception('Task not found'),
          );

          // Open the task edit dialog
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AddTodoDialog(
                selectedDate: task.todoDate,
                todoToEdit: task,
              ),
            );
          }
        },
        loading: () {
          print('⏳ Todos still loading...');
          // Retry after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _openTaskFromNotification(taskId);
            }
          });
        },
        error: (error, stack) {
          print('❌ Error loading todos: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error loading tasks: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      print('❌ Error opening task from notification: $e');

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotFindTask(e.toString())),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
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

    final l10n = AppLocalizations.of(context)!;
    final count = _selectedTodoIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteMultipleTasks),
        content: Text(l10n.confirmDeleteMultiple(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
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
              content: Text(l10n.tasksDeleted(count)),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.failedToDeleteTasks(e.toString())),
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

  List<TodoEntity> _filterTodosByUser(List<TodoEntity> todos) {
    var filteredTodos = todos;

    // Apply user filter
    if (_taskFilter == TaskFilter.myTasks) {
      final currentUser = ref.read(currentUserProvider).value;
      if (currentUser != null) {
        filteredTodos = filteredTodos.where((todo) {
          // Show task if:
          // 1. It's assigned to the current user, OR
          // 2. It's shared with the current user, OR
          // 3. The user created it
          return todo.assignedToId == currentUser.id ||
                 (todo.sharedWith?.contains(currentUser.id) ?? false) ||
                 todo.userId == currentUser.id;
        }).toList();
      }
    }

    // Apply category filter
    if (_categoryFilter != null) {
      filteredTodos = filteredTodos.where((todo) {
        return todo.category == _categoryFilter;
      }).toList();
    }

    return filteredTodos;
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
    final l10n = AppLocalizations.of(context)!;
    final userState = ref.watch(currentUserProvider);
    final todosState = ref.watch(todosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? l10n.tasksSelected(_selectedTodoIds.length) : l10n.appTitle),
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
                tooltip: l10n.deleteSelected,
              ),
          ] else ...[
            // Filter toggle chip
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: ChoiceChip(
                label: Text(
                  _taskFilter == TaskFilter.all ? l10n.allTasks : l10n.myTasks,
                  style: const TextStyle(fontSize: 12),
                ),
                selected: _taskFilter == TaskFilter.myTasks,
                onSelected: (selected) {
                  setState(() {
                    _taskFilter = selected ? TaskFilter.myTasks : TaskFilter.all;
                  });
                },
                avatar: Icon(
                  _taskFilter == TaskFilter.all ? Icons.people : Icons.person,
                  size: 18,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: l10n.selectMultiple,
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
              } else if (value == 'family') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FamilyMembersPage(),
                  ),
                );
              } else if (value == 'settings') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              }
            },
            itemBuilder: (context) {
              final l10n = AppLocalizations.of(context)!;
              return [
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
                PopupMenuItem(
                  value: 'family',
                  child: Row(
                    children: [
                      const Icon(Icons.people),
                      const SizedBox(width: 8),
                      Text(l10n.familyMembers),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings),
                      const SizedBox(width: 8),
                      Text(l10n.settings),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout),
                      const SizedBox(width: 8),
                      Text(l10n.logoutButton),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: todosState.when(
        data: (todos) {
          // Apply user filter first
          final filteredTodos = _filterTodosByUser(todos);
          final selectedDayTodos = _getTodosForDay(filteredTodos, _selectedDay ?? DateTime.now());

          return CustomScrollView(
            slivers: [
              // Calendar Widget
              SliverToBoxAdapter(
                child: Card(
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
                    eventLoader: (day) => _getTodosForDay(filteredTodos, day),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
              ),

              // Selected Date Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDay != null
                            ? DateFormat('EEEE, MMMM d', Localizations.localeOf(context).languageCode).format(_selectedDay!)
                            : l10n.selectDate,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        l10n.tasks(selectedDayTodos.length),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              // Category Filter
              SliverToBoxAdapter(
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // All categories chip
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(l10n.all),
                          selected: _categoryFilter == null,
                          onSelected: (selected) {
                            setState(() {
                              _categoryFilter = null;
                            });
                          },
                          avatar: _categoryFilter == null
                              ? const Icon(Icons.check, size: 16)
                              : null,
                        ),
                      ),
                      // Category chips
                      ...PredefinedCategories.categories.map((category) {
                        final isSelected = _categoryFilter == category.id;
                        final languageCode = Localizations.localeOf(context).languageCode;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text(category.getLocalizedName(languageCode)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _categoryFilter = selected ? category.id : null;
                              });
                            },
                            avatar: Icon(
                              IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : Color(category.colorValue),
                            ),
                            backgroundColor: Color(category.colorValue).withValues(alpha: 0.1),
                            selectedColor: Color(category.colorValue),
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Color(category.colorValue),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),

              // Divider
              const SliverToBoxAdapter(
                child: Divider(height: 1),
              ),

              // Plan My Day Button
              if (selectedDayTodos.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DailyPlanningPage(
                              selectedDate: _selectedDay ?? DateTime.now(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: Text(l10n.planMyDay),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),
                ),

              // Smart Suggestions
              const SliverToBoxAdapter(
                child: SmartSuggestionsCard(),
              ),

              // Todos List or Empty State
              selectedDayTodos.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
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
                              l10n.noTasksForDay,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.all(8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final todo = selectedDayTodos[index];
                            return TodoListItem(
                              todo: todo,
                              isSelectionMode: _isSelectionMode,
                              isSelected: _selectedTodoIds.contains(todo.id),
                              onSelectionChanged: () => _toggleTodoSelection(todo.id),
                            );
                          },
                          childCount: selectedDayTodos.length,
                        ),
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
              Text(l10n.errorWithMessage(error.toString())),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(todosProvider.notifier).loadTodos();
                },
                child: Text(l10n.retry),
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
