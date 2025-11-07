import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../../features/todos/domain/entities/todo_entity.dart';

/// Helper class for handling recurring todos
class RecurrenceHelper {
  /// Generate recurring todo instances from a parent recurring todo
  static List<TodoEntity> generateRecurringInstances({
    required TodoEntity parentTodo,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (!parentTodo.isRecurring) {
      return [parentTodo];
    }

    final instances = <TodoEntity>[];
    final pattern = parentTodo.recurrencePattern;
    final interval = parentTodo.recurrenceInterval ?? 1;
    final recurrenceEnd = parentTodo.recurrenceEndDate ?? endDate;

    DateTime currentDate = startDate;

    switch (pattern) {
      case 'daily':
        instances.addAll(_generateDailyInstances(
          parentTodo: parentTodo,
          startDate: currentDate,
          endDate: recurrenceEnd,
          interval: interval,
        ));
        break;

      case 'weekly':
        instances.addAll(_generateWeeklyInstances(
          parentTodo: parentTodo,
          startDate: currentDate,
          endDate: recurrenceEnd,
          interval: interval,
          weekdays: parentTodo.recurrenceWeekdays ?? [currentDate.weekday],
        ));
        break;

      case 'monthly':
        instances.addAll(_generateMonthlyInstances(
          parentTodo: parentTodo,
          startDate: currentDate,
          endDate: recurrenceEnd,
          interval: interval,
        ));
        break;

      case 'yearly':
        instances.addAll(_generateYearlyInstances(
          parentTodo: parentTodo,
          startDate: currentDate,
          endDate: recurrenceEnd,
          interval: interval,
        ));
        break;

      default:
        instances.add(parentTodo);
    }

    return instances;
  }

  /// Generate daily recurring instances
  static List<TodoEntity> _generateDailyInstances({
    required TodoEntity parentTodo,
    required DateTime startDate,
    required DateTime endDate,
    required int interval,
  }) {
    final instances = <TodoEntity>[];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) || _isSameDay(currentDate, endDate)) {
      instances.add(_createInstance(parentTodo, currentDate));
      currentDate = currentDate.add(Duration(days: interval));
    }

    return instances;
  }

  /// Generate weekly recurring instances
  static List<TodoEntity> _generateWeeklyInstances({
    required TodoEntity parentTodo,
    required DateTime startDate,
    required DateTime endDate,
    required int interval,
    required List<int> weekdays,
  }) {
    final instances = <TodoEntity>[];
    DateTime currentDate = startDate;

    // Find the first occurrence
    while (!weekdays.contains(currentDate.weekday)) {
      currentDate = currentDate.add(const Duration(days: 1));
      if (currentDate.isAfter(endDate)) return instances;
    }

    while (currentDate.isBefore(endDate) || _isSameDay(currentDate, endDate)) {
      // Add instances for all selected weekdays in this week
      for (final weekday in weekdays) {
        final daysToAdd = (weekday - currentDate.weekday) % 7;
        final instanceDate = currentDate.add(Duration(days: daysToAdd));

        if ((instanceDate.isBefore(endDate) || _isSameDay(instanceDate, endDate)) &&
            !instanceDate.isBefore(startDate)) {
          instances.add(_createInstance(parentTodo, instanceDate));
        }
      }

      // Move to next week(s)
      currentDate = currentDate.add(Duration(days: 7 * interval));
    }

    return instances;
  }

  /// Generate monthly recurring instances
  static List<TodoEntity> _generateMonthlyInstances({
    required TodoEntity parentTodo,
    required DateTime startDate,
    required DateTime endDate,
    required int interval,
  }) {
    final instances = <TodoEntity>[];
    DateTime currentDate = startDate;
    final dayOfMonth = startDate.day;

    while (currentDate.isBefore(endDate) || _isSameDay(currentDate, endDate)) {
      // Handle months with fewer days (e.g., Feb 31 -> Feb 28/29)
      final lastDayOfMonth = DateTime(currentDate.year, currentDate.month + 1, 0).day;
      final actualDay = dayOfMonth > lastDayOfMonth ? lastDayOfMonth : dayOfMonth;

      final instanceDate = DateTime(
        currentDate.year,
        currentDate.month,
        actualDay,
      );

      if ((instanceDate.isBefore(endDate) || _isSameDay(instanceDate, endDate)) &&
          !instanceDate.isBefore(startDate)) {
        instances.add(_createInstance(parentTodo, instanceDate));
      }

      // Move to next month(s)
      final nextMonth = currentDate.month + interval;
      final nextYear = currentDate.year + (nextMonth - 1) ~/ 12;
      final normalizedMonth = ((nextMonth - 1) % 12) + 1;

      currentDate = DateTime(nextYear, normalizedMonth, 1);
    }

    return instances;
  }

  /// Generate yearly recurring instances
  static List<TodoEntity> _generateYearlyInstances({
    required TodoEntity parentTodo,
    required DateTime startDate,
    required DateTime endDate,
    required int interval,
  }) {
    final instances = <TodoEntity>[];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) || _isSameDay(currentDate, endDate)) {
      instances.add(_createInstance(parentTodo, currentDate));
      currentDate = DateTime(
        currentDate.year + interval,
        currentDate.month,
        currentDate.day,
      );
    }

    return instances;
  }

  /// Create a recurring instance from parent todo
  static TodoEntity _createInstance(TodoEntity parentTodo, DateTime date) {
    return parentTodo.copyWith(
      id: const Uuid().v4(),
      todoDate: date,
      isRecurrenceInstance: true,
      recurrenceParentId: parentTodo.id,
    );
  }

  /// Check if two dates are the same day
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Get human-readable recurrence description
  static String getRecurrenceDescription({
    required String pattern,
    int interval = 1,
    List<int>? weekdays,
    DateTime? endDate,
    String? locale,
  }) {
    final buffer = StringBuffer();

    final every = locale == 'zh' ? '每' : 'Every';
    final day = locale == 'zh' ? '天' : 'day';
    final days = locale == 'zh' ? '天' : 'days';
    final week = locale == 'zh' ? '周' : 'week';
    final weeks = locale == 'zh' ? '周' : 'weeks';
    final month = locale == 'zh' ? '月' : 'month';
    final months = locale == 'zh' ? '月' : 'months';
    final year = locale == 'zh' ? '年' : 'year';
    final years = locale == 'zh' ? '年' : 'years';
    final on = locale == 'zh' ? '' : 'on';

    if (interval == 1) {
      switch (pattern) {
        case 'daily':
          buffer.write('$every $day');
          break;
        case 'weekly':
          if (weekdays != null && weekdays.isNotEmpty) {
            buffer.write(locale == 'zh'
              ? '$every${_formatWeekdays(weekdays, locale)}'
              : '$every ${_formatWeekdays(weekdays, locale)}');
          } else {
            buffer.write('$every $week');
          }
          break;
        case 'monthly':
          buffer.write('$every $month');
          break;
        case 'yearly':
          buffer.write('$every $year');
          break;
      }
    } else {
      switch (pattern) {
        case 'daily':
          buffer.write(locale == 'zh' ? '$every$interval$days' : '$every $interval $days');
          break;
        case 'weekly':
          if (weekdays != null && weekdays.isNotEmpty) {
            buffer.write(locale == 'zh'
              ? '$every$interval$weeks${_formatWeekdays(weekdays, locale)}'
              : '$every $interval $weeks $on ${_formatWeekdays(weekdays, locale)}');
          } else {
            buffer.write(locale == 'zh' ? '$every$interval$weeks' : '$every $interval $weeks');
          }
          break;
        case 'monthly':
          buffer.write(locale == 'zh' ? '$every$interval$months' : '$every $interval $months');
          break;
        case 'yearly':
          buffer.write(locale == 'zh' ? '$every$interval$years' : '$every $interval $years');
          break;
      }
    }

    if (endDate != null) {
      buffer.write(' until ${endDate.month}/${endDate.day}/${endDate.year}');
    }

    return buffer.toString();
  }

  /// Format weekdays list to readable string
  static String _formatWeekdays(List<int> weekdays, [String? locale]) {
    final sorted = List<int>.from(weekdays)..sort();
    final dayNames = sorted.map((day) {
      // Use DateFormat to get localized day names
      // ISO weekday: Monday=1, Sunday=7
      // DateTime weekday: Monday=1, Sunday=7 (same)
      final date = DateTime(2025, 1, day); // Week starting Jan 6, 2025 is Monday
      return DateFormat('E', locale).format(date);
    }).toList();

    if (dayNames.length == 1) {
      return dayNames[0];
    } else if (dayNames.length == 2) {
      return '${dayNames[0]} and ${dayNames[1]}';
    } else {
      final lastDay = dayNames.removeLast();
      return '${dayNames.join(', ')}, and $lastDay';
    }
  }

  /// Get the next occurrence date for a recurring todo
  static DateTime? getNextOccurrence({
    required DateTime currentDate,
    required String pattern,
    int interval = 1,
    List<int>? weekdays,
    DateTime? endDate,
  }) {
    DateTime nextDate;

    switch (pattern) {
      case 'daily':
        nextDate = currentDate.add(Duration(days: interval));
        break;

      case 'weekly':
        if (weekdays != null && weekdays.isNotEmpty) {
          // Find next weekday
          nextDate = currentDate.add(const Duration(days: 1));
          while (!weekdays.contains(nextDate.weekday)) {
            nextDate = nextDate.add(const Duration(days: 1));
            // If we've gone through a full week, jump to next interval
            if (nextDate.difference(currentDate).inDays >= 7) {
              nextDate = currentDate.add(Duration(days: 7 * interval));
              while (!weekdays.contains(nextDate.weekday)) {
                nextDate = nextDate.add(const Duration(days: 1));
              }
              break;
            }
          }
        } else {
          nextDate = currentDate.add(Duration(days: 7 * interval));
        }
        break;

      case 'monthly':
        final nextMonth = currentDate.month + interval;
        final nextYear = currentDate.year + (nextMonth - 1) ~/ 12;
        final normalizedMonth = ((nextMonth - 1) % 12) + 1;
        final lastDayOfMonth = DateTime(nextYear, normalizedMonth + 1, 0).day;
        final actualDay = currentDate.day > lastDayOfMonth ? lastDayOfMonth : currentDate.day;
        nextDate = DateTime(nextYear, normalizedMonth, actualDay);
        break;

      case 'yearly':
        nextDate = DateTime(
          currentDate.year + interval,
          currentDate.month,
          currentDate.day,
        );
        break;

      default:
        return null;
    }

    if (endDate != null && nextDate.isAfter(endDate)) {
      return null;
    }

    return nextDate;
  }
}
