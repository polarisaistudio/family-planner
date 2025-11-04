import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../todos/presentation/providers/todo_providers.dart';

/// Smart defaults based on user patterns
class SmartDefaults {
  final Map<String, SmartTimeOfDay> commonTaskTimes; // task type -> typical time
  final Map<String, String> commonTaskLocations; // task type -> typical location
  final Map<String, int> commonTaskDurations; // task type -> typical duration
  final Map<int, List<String>> weekdayPatterns; // weekday -> common task types

  const SmartDefaults({
    this.commonTaskTimes = const {},
    this.commonTaskLocations = const {},
    this.commonTaskDurations = const {},
    this.weekdayPatterns = const {},
  });
}

class SmartTimeOfDay {
  final int hour;
  final int minute;

  const SmartTimeOfDay(this.hour, this.minute);

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class SmartDefaultsNotifier extends StateNotifier<SmartDefaults> {
  final Ref _ref;

  SmartDefaultsNotifier(this._ref) : super(const SmartDefaults()) {
    // Don't analyze in constructor - will be called when needed
  }

  /// Analyze historical todos to find patterns
  Future<void> _analyzePatterns() async {
    try {
      final todosAsync = _ref.read(todosProvider);
      final todos = todosAsync.value ?? [];

      if (todos.isEmpty) return;

    // Only analyze completed todos (they represent actual behavior)
    final completedTodos = todos.where((t) => t.isCompleted).toList();
    if (completedTodos.isEmpty) return;

    // Analyze by task type
    final timesByType = <String, List<DateTime>>{};
    final locationsByType = <String, List<String>>{};
    final durationsByType = <String, List<int>>{};
    final tasksByWeekday = <int, List<String>>{};

    for (final todo in completedTodos) {
      final type = todo.type.toLowerCase();

      // Track times
      if (todo.todoTime != null) {
        timesByType.putIfAbsent(type, () => []).add(todo.dateTime!);
      }

      // Track locations
      if (todo.location != null && todo.location!.isNotEmpty) {
        locationsByType.putIfAbsent(type, () => []).add(todo.location!);
      }

      // Track durations
      if (todo.preparationTimeMinutes > 0) {
        durationsByType.putIfAbsent(type, () => []).add(todo.preparationTimeMinutes);
      }

      // Track weekday patterns
      final weekday = todo.todoDate.weekday;
      tasksByWeekday.putIfAbsent(weekday, () => []).add(type);
    }

    // Calculate averages and most common values
    final commonTimes = <String, SmartTimeOfDay>{};
    final commonLocations = <String, String>{};
    final commonDurations = <String, int>{};

    // Most common time for each type
    timesByType.forEach((type, times) {
      if (times.length >= 2) { // Need at least 2 occurrences for pattern
        final avgHour = times.map((t) => t.hour).reduce((a, b) => a + b) ~/ times.length;
        final avgMinute = times.map((t) => t.minute).reduce((a, b) => a + b) ~/ times.length;
        commonTimes[type] = SmartTimeOfDay(avgHour, avgMinute);
      }
    });

    // Most common location for each type
    locationsByType.forEach((type, locations) {
      if (locations.length >= 2) {
        final locationFrequency = <String, int>{};
        for (final loc in locations) {
          locationFrequency[loc] = (locationFrequency[loc] ?? 0) + 1;
        }
        final mostCommon = locationFrequency.entries.reduce((a, b) => a.value > b.value ? a : b);
        commonLocations[type] = mostCommon.key;
      }
    });

    // Average duration for each type
    durationsByType.forEach((type, durations) {
      if (durations.isNotEmpty) {
        final avg = durations.reduce((a, b) => a + b) ~/ durations.length;
        commonDurations[type] = avg;
      }
    });

    // Most common task types by weekday
    final weekdayPatterns = <int, List<String>>{};
    tasksByWeekday.forEach((weekday, types) {
      final typeFrequency = <String, int>{};
      for (final type in types) {
        typeFrequency[type] = (typeFrequency[type] ?? 0) + 1;
      }
      // Get top 3 most common types for this weekday
      final sortedTypes = typeFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      weekdayPatterns[weekday] = sortedTypes.take(3).map((e) => e.key).toList();
    });

    state = SmartDefaults(
      commonTaskTimes: commonTimes,
      commonTaskLocations: commonLocations,
      commonTaskDurations: commonDurations,
      weekdayPatterns: weekdayPatterns,
    );

      print('📊 [SMART DEFAULTS] Analyzed ${completedTodos.length} completed todos');
      print('📊 [SMART DEFAULTS] Found patterns for ${commonTimes.length} task types');
    } catch (e) {
      print('🔴 [SMART DEFAULTS] Error analyzing patterns: $e');
      // Don't crash the app, just skip pattern analysis
    }
  }

  /// Get suggested time for a task type
  SmartTimeOfDay? getSuggestedTime(String taskType) {
    return state.commonTaskTimes[taskType.toLowerCase()];
  }

  /// Get suggested location for a task type
  String? getSuggestedLocation(String taskType) {
    return state.commonTaskLocations[taskType.toLowerCase()];
  }

  /// Get suggested duration for a task type
  int? getSuggestedDuration(String taskType) {
    return state.commonTaskDurations[taskType.toLowerCase()];
  }

  /// Get common task types for a weekday
  List<String> getWeekdayPatterns(int weekday) {
    return state.weekdayPatterns[weekday] ?? [];
  }

  /// Get all suggestions for a new task
  Map<String, dynamic> getSuggestionsForTask(String taskType, DateTime date) {
    final suggestions = <String, dynamic>{};

    final suggestedTime = getSuggestedTime(taskType);
    if (suggestedTime != null) {
      suggestions['time'] = suggestedTime;
      suggestions['timeReason'] = 'Based on your typical ${taskType.toLowerCase()} tasks';
    }

    final suggestedLocation = getSuggestedLocation(taskType);
    if (suggestedLocation != null) {
      suggestions['location'] = suggestedLocation;
      suggestions['locationReason'] = 'You usually do ${taskType.toLowerCase()} tasks here';
    }

    final suggestedDuration = getSuggestedDuration(taskType);
    if (suggestedDuration != null) {
      suggestions['duration'] = suggestedDuration;
      suggestions['durationReason'] = 'Your typical ${taskType.toLowerCase()} duration';
    }

    // Check if this task type is common for this weekday
    final weekdayPatterns = getWeekdayPatterns(date.weekday);
    if (weekdayPatterns.contains(taskType.toLowerCase())) {
      suggestions['weekdayPattern'] = true;
      suggestions['weekdayReason'] = 'You often do ${taskType.toLowerCase()} on ${_getWeekdayName(date.weekday)}s';
    }

    return suggestions;
  }

  /// Refresh patterns (call after significant changes)
  Future<void> refreshPatterns() async {
    await _analyzePatterns();
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return 'Monday';
      case 2: return 'Tuesday';
      case 3: return 'Wednesday';
      case 4: return 'Thursday';
      case 5: return 'Friday';
      case 6: return 'Saturday';
      case 7: return 'Sunday';
      default: return '';
    }
  }
}

/// Provider for smart defaults
final smartDefaultsProvider = StateNotifierProvider<SmartDefaultsNotifier, SmartDefaults>((ref) {
  return SmartDefaultsNotifier(ref);
});
