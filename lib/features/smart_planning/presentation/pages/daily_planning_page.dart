import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../todos/domain/entities/todo_entity.dart';
import '../../../todos/presentation/providers/todo_providers.dart';
import '../providers/smart_planning_provider.dart';
import '../../domain/models/smart_schedule.dart';
import '../widgets/time_block_card.dart';
import '../widgets/conflict_alert_card.dart';
import '../../../../shared/widgets/translated_text.dart';

/// Daily Planning Page - Shows optimized schedule with smart suggestions
class DailyPlanningPage extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const DailyPlanningPage({
    super.key,
    required this.selectedDate,
  });

  @override
  ConsumerState<DailyPlanningPage> createState() => _DailyPlanningPageState();
}

class _DailyPlanningPageState extends ConsumerState<DailyPlanningPage> {
  bool _isOptimizing = false;
  SmartSchedule? _optimizedSchedule;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateOptimizedSchedule();
    });
  }

  Future<void> _generateOptimizedSchedule() async {
    setState(() => _isOptimizing = true);

    try {
      final todosAsync = ref.read(todosProvider);
      final todos = todosAsync.value ?? [];

      final selectedDayTodos = todos.where((todo) {
        return isSameDay(todo.todoDate, widget.selectedDate) && !todo.isCompleted;
      }).toList();

      if (selectedDayTodos.isEmpty) {
        setState(() {
          _isOptimizing = false;
          _optimizedSchedule = null;
        });
        return;
      }

      // Generate smart schedule
      final schedule = await _generateSmartSchedule(selectedDayTodos);

      setState(() {
        _optimizedSchedule = schedule;
        _isOptimizing = false;
      });
    } catch (e) {
      print('Error generating schedule: $e');
      setState(() => _isOptimizing = false);
    }
  }

  Future<SmartSchedule> _generateSmartSchedule(List<TodoEntity> todos) async {
    // 1. Detect conflicts
    final conflicts = _detectConflicts(todos);

    // 2. Order tasks intelligently
    final orderedTasks = _orderTasksIntelligently(todos);

    // 3. Generate time blocks
    final timeBlocks = _generateTimeBlocks(orderedTasks);

    // 4. Analyze the schedule
    await ref.read(smartPlanningProvider.notifier).analyzeDayTodos(todos);
    final suggestions = ref.read(smartPlanningProvider).suggestions;

    return SmartSchedule(
      date: widget.selectedDate,
      orderedTasks: orderedTasks,
      timeBlocks: timeBlocks,
      conflicts: conflicts,
      suggestions: suggestions,
      totalEstimatedTime: _calculateTotalTime(orderedTasks),
      optimizationScore: _calculateOptimizationScore(orderedTasks, conflicts),
    );
  }

  List<ScheduleConflict> _detectConflicts(List<TodoEntity> todos) {
    final conflicts = <ScheduleConflict>[];
    final timedTodos = todos.where((t) => t.todoTime != null).toList();

    // Sort by time
    timedTodos.sort((a, b) {
      final aTime = a.dateTime!;
      final bTime = b.dateTime!;
      return aTime.compareTo(bTime);
    });

    // Check for overlaps
    for (int i = 0; i < timedTodos.length - 1; i++) {
      final current = timedTodos[i];
      final next = timedTodos[i + 1];

      final currentStart = current.dateTime!;
      final currentDuration = Duration(minutes: current.preparationTimeMinutes > 0
          ? current.preparationTimeMinutes
          : 60);
      final currentEnd = currentStart.add(currentDuration);

      final nextStart = next.dateTime!;

      // Check for overlap
      if (currentEnd.isAfter(nextStart)) {
        conflicts.add(ScheduleConflict(
          type: ConflictType.timeOverlap,
          tasks: [current, next],
          message: 'Tasks overlap: "${current.title}" and "${next.title}"',
          severity: ConflictSeverity.high,
        ));
      }
      // Check for tight scheduling (less than 15 min buffer)
      else if (nextStart.difference(currentEnd).inMinutes < 15) {
        conflicts.add(ScheduleConflict(
          type: ConflictType.tightSchedule,
          tasks: [current, next],
          message: 'Tight schedule: Only ${nextStart.difference(currentEnd).inMinutes} min between tasks',
          severity: ConflictSeverity.medium,
        ));
      }
    }

    // Check for location conflicts (same time, different locations)
    for (int i = 0; i < timedTodos.length - 1; i++) {
      for (int j = i + 1; j < timedTodos.length; j++) {
        final task1 = timedTodos[i];
        final task2 = timedTodos[j];

        if (task1.location != null &&
            task2.location != null &&
            task1.location != task2.location) {
          final timeDiff = task2.dateTime!.difference(task1.dateTime!).abs();

          // If tasks are within 1 hour and in different locations
          if (timeDiff.inMinutes < 60) {
            conflicts.add(ScheduleConflict(
              type: ConflictType.locationConflict,
              tasks: [task1, task2],
              message: 'Location conflict: Different locations within 1 hour',
              severity: ConflictSeverity.high,
            ));
          }
        }
      }
    }

    return conflicts;
  }

  List<TodoEntity> _orderTasksIntelligently(List<TodoEntity> todos) {
    final orderedTasks = List<TodoEntity>.from(todos);

    // Sorting algorithm: Multi-criteria
    orderedTasks.sort((a, b) {
      // 1. Tasks with specific times come first, sorted by time
      if (a.todoTime != null && b.todoTime == null) return -1;
      if (a.todoTime == null && b.todoTime != null) return 1;
      if (a.todoTime != null && b.todoTime != null) {
        return a.dateTime!.compareTo(b.dateTime!);
      }

      // 2. Priority (lower number = higher priority)
      if (a.priority != b.priority) {
        return a.priority.compareTo(b.priority);
      }

      // 3. Type-based ordering (work/appointments before personal)
      final typeOrderA = _getTypeOrder(a.type);
      final typeOrderB = _getTypeOrder(b.type);
      if (typeOrderA != typeOrderB) {
        return typeOrderA.compareTo(typeOrderB);
      }

      // 4. Tasks with locations (group to minimize travel)
      if (a.location != null && b.location == null) return -1;
      if (a.location == null && b.location != null) return 1;

      // 5. Weather-dependent tasks (prioritize based on conditions)
      if (a.weatherDependent && !b.weatherDependent) return -1;
      if (!a.weatherDependent && b.weatherDependent) return 1;

      return 0;
    });

    return orderedTasks;
  }

  int _getTypeOrder(String type) {
    switch (type.toLowerCase()) {
      case 'appointment':
        return 1;
      case 'work':
        return 2;
      case 'shopping':
        return 3;
      case 'personal':
        return 4;
      default:
        return 5;
    }
  }

  List<TimeBlock> _generateTimeBlocks(List<TodoEntity> todos) {
    final blocks = <TimeBlock>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime currentTime = today.add(const Duration(hours: 8)); // Start at 8 AM

    for (final todo in todos) {
      // If todo has specific time, use it
      if (todo.todoTime != null) {
        final todoDateTime = todo.dateTime!;

        // Add travel time if has location
        int travelMinutes = 0;
        if (todo.location != null) {
          travelMinutes = 20; // Default travel time
        }

        // Add preparation time
        int prepMinutes = todo.preparationTimeMinutes > 0
            ? todo.preparationTimeMinutes
            : _estimateTaskDuration(todo);

        final blockStart = todoDateTime.subtract(Duration(minutes: travelMinutes));

        blocks.add(TimeBlock(
          task: todo,
          startTime: blockStart,
          endTime: todoDateTime.add(Duration(minutes: prepMinutes)),
          includedTravelTime: travelMinutes,
          includedPrepTime: prepMinutes,
        ));
      } else {
        // Auto-schedule: assign time blocks
        int duration = todo.preparationTimeMinutes > 0
            ? todo.preparationTimeMinutes
            : _estimateTaskDuration(todo);

        blocks.add(TimeBlock(
          task: todo,
          startTime: currentTime,
          endTime: currentTime.add(Duration(minutes: duration)),
          includedTravelTime: 0,
          includedPrepTime: duration,
          isSuggested: true,
        ));

        currentTime = currentTime.add(Duration(minutes: duration + 15)); // 15 min buffer
      }
    }

    return blocks;
  }

  int _estimateTaskDuration(TodoEntity todo) {
    switch (todo.type.toLowerCase()) {
      case 'appointment':
        return 60;
      case 'work':
        return 120;
      case 'shopping':
        return 45;
      case 'personal':
        return 30;
      default:
        return 60;
    }
  }

  int _calculateTotalTime(List<TodoEntity> todos) {
    return todos.fold(0, (total, todo) {
      return total + (todo.preparationTimeMinutes > 0
          ? todo.preparationTimeMinutes
          : _estimateTaskDuration(todo));
    });
  }

  double _calculateOptimizationScore(List<TodoEntity> todos, List<ScheduleConflict> conflicts) {
    // Start with 100
    double score = 100.0;

    // Deduct for conflicts
    for (final conflict in conflicts) {
      switch (conflict.severity) {
        case ConflictSeverity.high:
          score -= 20;
          break;
        case ConflictSeverity.medium:
          score -= 10;
          break;
        case ConflictSeverity.low:
          score -= 5;
          break;
      }
    }

    // Bonus for good organization
    final timedTasks = todos.where((t) => t.todoTime != null).length;
    final totalTasks = todos.length;
    if (totalTasks > 0) {
      score += (timedTasks / totalTasks) * 10; // Up to 10 points for having times
    }

    // Bonus for prioritization
    final highPriorityFirst = todos.first.priority <= 2;
    if (highPriorityFirst) score += 5;

    return score.clamp(0, 100);
  }

  bool isSameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.planYourDay),
            Text(
              DateFormat('EEEE, MMM d', Localizations.localeOf(context).languageCode).format(widget.selectedDate),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateOptimizedSchedule,
            tooltip: l10n.retry,
          ),
        ],
      ),
      body: _isOptimizing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.optimizingSchedule),
                ],
              ),
            )
          : _optimizedSchedule == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noTasksForDay,
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : _buildScheduleView(_optimizedSchedule!),
    );
  }

  Widget _buildScheduleView(SmartSchedule schedule) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Optimization Score
        _buildScoreCard(schedule),
        const SizedBox(height: 16),

        // Conflicts (if any)
        if (schedule.conflicts.isNotEmpty) ...[
          _buildConflictsSection(schedule.conflicts),
          const SizedBox(height: 16),
        ],

        // Smart Suggestions
        if (schedule.suggestions.isNotEmpty) ...[
          _buildSuggestionsSection(schedule.suggestions),
          const SizedBox(height: 16),
        ],

        // Time Blocks
        _buildTimeBlocksSection(schedule.timeBlocks),
      ],
    );
  }

  Widget _buildScoreCard(SmartSchedule schedule) {
    final score = schedule.optimizationScore;
    final color = score >= 80
        ? Colors.green
        : score >= 60
            ? Colors.orange
            : Colors.red;

    return Card(
      color: color.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.scheduleScore,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)!.tasksMinutes(schedule.orderedTasks.length, schedule.totalEstimatedTime),
                      style: TextStyle(fontSize: 12, color: color.shade700),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${score.toInt()}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: color.shade100,
              valueColor: AlwaysStoppedAnimation(color.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictsSection(List<ScheduleConflict> conflicts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.conflictsDetected,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...conflicts.map((conflict) => ConflictAlertCard(conflict: conflict)),
      ],
    );
  }

  Widget _buildSuggestionsSection(List<SmartSuggestion> suggestions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.smartSuggestions,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...suggestions.map((suggestion) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                _getSuggestionIcon(suggestion.type),
                color: suggestion.isUrgent ? Colors.orange : Colors.blue,
              ),
              title: TranslatedText(suggestion.message),
              subtitle: suggestion.actionText != null
                  ? TranslatedText(suggestion.actionText!)
                  : null,
              trailing: suggestion.isUrgent
                  ? const Icon(Icons.priority_high, color: Colors.orange)
                  : null,
            ),
          );
        }),
      ],
    );
  }

  IconData _getSuggestionIcon(String type) {
    switch (type) {
      case 'weather':
        return Icons.wb_sunny;
      case 'location':
        return Icons.location_on;
      case 'traffic':
        return Icons.traffic;
      case 'preparation':
        return Icons.alarm;
      default:
        return Icons.info;
    }
  }

  Widget _buildTimeBlocksSection(List<TimeBlock> blocks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.optimizedSchedule,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...blocks.map((block) => TimeBlockCard(block: block)),
      ],
    );
  }
}
