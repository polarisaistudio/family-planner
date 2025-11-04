import '../../../todos/domain/entities/todo_entity.dart';
import '../../presentation/providers/smart_planning_provider.dart';

/// Smart schedule for a day
class SmartSchedule {
  final DateTime date;
  final List<TodoEntity> orderedTasks;
  final List<TimeBlock> timeBlocks;
  final List<ScheduleConflict> conflicts;
  final List<SmartSuggestion> suggestions;
  final int totalEstimatedTime; // in minutes
  final double optimizationScore; // 0-100

  const SmartSchedule({
    required this.date,
    required this.orderedTasks,
    required this.timeBlocks,
    required this.conflicts,
    required this.suggestions,
    required this.totalEstimatedTime,
    required this.optimizationScore,
  });
}

/// Time block for a task
class TimeBlock {
  final TodoEntity task;
  final DateTime startTime;
  final DateTime endTime;
  final int includedTravelTime; // minutes
  final int includedPrepTime; // minutes
  final bool isSuggested; // true if time was auto-suggested

  const TimeBlock({
    required this.task,
    required this.startTime,
    required this.endTime,
    required this.includedTravelTime,
    required this.includedPrepTime,
    this.isSuggested = false,
  });

  int get durationMinutes => endTime.difference(startTime).inMinutes;
}

/// Schedule conflict
class ScheduleConflict {
  final ConflictType type;
  final List<TodoEntity> tasks;
  final String message;
  final ConflictSeverity severity;

  const ScheduleConflict({
    required this.type,
    required this.tasks,
    required this.message,
    required this.severity,
  });
}

enum ConflictType {
  timeOverlap,
  tightSchedule,
  locationConflict,
  impossibleTravel,
}

enum ConflictSeverity {
  low,
  medium,
  high,
}
