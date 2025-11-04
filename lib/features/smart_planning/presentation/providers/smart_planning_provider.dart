import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../todos/domain/entities/todo_entity.dart';
import 'open_meteo_weather_provider.dart';
import 'location_provider.dart';
import 'notification_provider.dart';
import 'permission_provider.dart';

/// Smart suggestion for a todo
class SmartSuggestion {
  final String type; // 'weather', 'location', 'traffic', 'preparation'
  final String message;
  final String? actionText;
  final DateTime? suggestedTime;
  final bool isUrgent;

  const SmartSuggestion({
    required this.type,
    required this.message,
    this.actionText,
    this.suggestedTime,
    this.isUrgent = false,
  });
}

/// State class for smart planning
class SmartPlanningState {
  final List<SmartSuggestion> suggestions;
  final bool isAnalyzing;
  final String? error;

  const SmartPlanningState({
    this.suggestions = const [],
    this.isAnalyzing = false,
    this.error,
  });

  SmartPlanningState copyWith({
    List<SmartSuggestion>? suggestions,
    bool? isAnalyzing,
    String? error,
  }) {
    return SmartPlanningState(
      suggestions: suggestions ?? this.suggestions,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      error: error,
    );
  }

  /// Get urgent suggestions only
  List<SmartSuggestion> get urgentSuggestions {
    return suggestions.where((s) => s.isUrgent).toList();
  }

  /// Get suggestions by type
  List<SmartSuggestion> getSuggestionsByType(String type) {
    return suggestions.where((s) => s.type == type).toList();
  }
}

/// Coordinator for smart planning features
class SmartPlanningNotifier extends StateNotifier<SmartPlanningState> {
  final Ref _ref;

  SmartPlanningNotifier(this._ref) : super(const SmartPlanningState());

  /// Analyze a todo and generate smart suggestions
  Future<void> analyzeTodo(TodoEntity todo) async {
    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      final suggestions = <SmartSuggestion>[];

      // Check permissions first
      final permissionState = _ref.read(permissionProvider);

      if (!permissionState.allGranted) {
        state = state.copyWith(
          isAnalyzing: false,
          error: 'Required permissions not granted: ${permissionState.missingPermissions.join(", ")}',
        );
        return;
      }

      // Weather-based suggestions (for weather-dependent tasks)
      if (todo.weatherDependent) {
        final weatherSuggestion = await _analyzeWeather(todo);
        if (weatherSuggestion != null) {
          suggestions.add(weatherSuggestion);
        }
      }

      // Location-based suggestions
      if (todo.location != null && todo.location!.isNotEmpty) {
        final locationSuggestion = await _analyzeLocation(todo);
        if (locationSuggestion != null) {
          suggestions.add(locationSuggestion);
        }
      }

      // Preparation time suggestions (if has time component)
      if (todo.todoTime != null) {
        final prepSuggestion = _analyzePreparationTime(todo);
        if (prepSuggestion != null) {
          suggestions.add(prepSuggestion);
        }
      }

      state = state.copyWith(
        suggestions: suggestions,
        isAnalyzing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: 'Failed to analyze todo: $e',
      );
    }
  }

  /// Analyze multiple todos for the day
  Future<void> analyzeDayTodos(List<TodoEntity> todos) async {
    state = state.copyWith(isAnalyzing: true, error: null);

    try {
      final suggestions = <SmartSuggestion>[];

      for (final todo in todos) {
        if (!todo.isCompleted) {
          // Weather check for outdoor or weather-dependent activities
          if (_isOutdoorActivity(todo) || todo.weatherDependent) {
            final weatherSuggestion = await _analyzeWeather(todo);
            if (weatherSuggestion != null) {
              suggestions.add(weatherSuggestion);
            }
          }

          // Location reminders
          if (todo.location != null && todo.location!.isNotEmpty) {
            final locationSuggestion = await _analyzeLocation(todo);
            if (locationSuggestion != null) {
              suggestions.add(locationSuggestion);
            }
          }
        }
      }

      state = state.copyWith(
        suggestions: suggestions,
        isAnalyzing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        error: 'Failed to analyze todos: $e',
      );
    }
  }

  /// Weather analysis
  Future<SmartSuggestion?> _analyzeWeather(TodoEntity todo) async {
    try {
      final locationState = _ref.read(locationProvider);

      // Get current location if not available
      if (locationState.currentPosition == null) {
        await _ref.read(locationProvider.notifier).fetchCurrentLocation();
      }

      final position = _ref.read(locationProvider).currentPosition;
      if (position == null) return null;

      // Fetch weather
      await _ref.read(openMeteoWeatherProvider.notifier).fetchCurrentWeather(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final weatherState = _ref.read(openMeteoWeatherProvider);
      if (weatherState.currentWeather == null) return null;

      // Get weather advice for the activity
      final isOutdoor = _isOutdoorActivity(todo);
      final weatherNotifier = _ref.read(openMeteoWeatherProvider.notifier);
      final advice = weatherNotifier.getWeatherAdvice(isOutdoor);
      final emoji = weatherNotifier.getWeatherEmoji();

      // Check if outdoor-friendly
      final isOutdoorFriendly = weatherNotifier.isOutdoorFriendly();

      if (_isOutdoorActivity(todo) && !isOutdoorFriendly) {
        return SmartSuggestion(
          type: 'weather',
          message: '$emoji Weather alert: $advice for "${todo.title}"',
          actionText: 'Consider rescheduling',
          isUrgent: true,
        );
      }

      return SmartSuggestion(
        type: 'weather',
        message: '$emoji Weather tip: $advice',
        actionText: null,
        isUrgent: false,
      );
    } catch (e) {
      print('Error analyzing weather: $e');
      return null;
    }
  }

  /// Location analysis
  Future<SmartSuggestion?> _analyzeLocation(TodoEntity todo) async {
    try {
      final locationNotifier = _ref.read(locationProvider.notifier);

      // Parse location coordinates from todo.location
      // For now, we'll geocode the address
      final coords = await locationNotifier.getCoordinatesFromAddress(todo.location!);
      if (coords == null) return null;

      // Calculate distance
      final distance = await locationNotifier.calculateDistanceTo(
        targetLat: coords['latitude']!,
        targetLon: coords['longitude']!,
      );

      if (distance == null) return null;

      // Estimate travel time
      final travelTime = locationNotifier.estimateTravelTime(
        distanceMeters: distance,
        averageSpeedKmh: 40,
      );

      final formattedDistance = locationNotifier.formatDistance(distance);

      // Calculate suggested departure time (using todoTime if available)
      DateTime? suggestedDeparture;
      if (todo.todoTime != null) {
        final todoDateTime = todo.dateTime!;
        suggestedDeparture = todoDateTime.subtract(
          Duration(minutes: travelTime.ceil() + 10), // Add 10 min buffer
        );
      }

      return SmartSuggestion(
        type: 'location',
        message: '📍 ${todo.location} is $formattedDistance away (~${travelTime.ceil()} min)',
        actionText: 'Set reminder',
        suggestedTime: suggestedDeparture,
        isUrgent: false,
      );
    } catch (e) {
      print('Error analyzing location: $e');
      return null;
    }
  }

  /// Preparation time analysis
  SmartSuggestion? _analyzePreparationTime(TodoEntity todo) {
    try {
      final now = DateTime.now();
      final todoDateTime = todo.dateTime;
      if (todoDateTime == null) return null;

      // Calculate time until due
      final timeUntil = todoDateTime.difference(now);

      // Use preparation time from todo or estimate based on type
      int prepMinutes = todo.preparationTimeMinutes;
      if (prepMinutes == 0) {
        // Estimate based on type
        switch (todo.type.toLowerCase()) {
          case 'work':
          case 'appointment':
            prepMinutes = 45;
            break;
          case 'personal':
            prepMinutes = 20;
            break;
          case 'shopping':
            prepMinutes = 15;
            break;
          default:
            prepMinutes = 30;
        }
      }

      // If event is within prep time, show urgent reminder
      if (timeUntil.inMinutes > 0 && timeUntil.inMinutes <= prepMinutes) {
        return SmartSuggestion(
          type: 'preparation',
          message: '⏰ Time to prepare for "${todo.title}" (in ${timeUntil.inMinutes} min)',
          actionText: 'Start now',
          isUrgent: true,
        );
      }

      // If event is within 2 hours, suggest prep time
      if (timeUntil.inMinutes > prepMinutes && timeUntil.inHours <= 2) {
        final prepTime = todoDateTime.subtract(Duration(minutes: prepMinutes));
        return SmartSuggestion(
          type: 'preparation',
          message: '🔔 Consider preparing for "${todo.title}" around ${_formatTime(prepTime)}',
          actionText: 'Set reminder',
          suggestedTime: prepTime,
          isUrgent: false,
        );
      }

      return null;
    } catch (e) {
      print('Error analyzing preparation time: $e');
      return null;
    }
  }

  /// Check if activity is outdoor
  bool _isOutdoorActivity(TodoEntity todo) {
    final outdoorKeywords = [
      'park', 'outdoor', 'hike', 'walk', 'run', 'jog', 'bike', 'picnic',
      'beach', 'swim', 'garden', 'playground', 'sports', 'soccer', 'football',
    ];

    final title = todo.title.toLowerCase();
    final description = (todo.description ?? '').toLowerCase();
    final type = todo.type.toLowerCase();

    return outdoorKeywords.any((keyword) =>
      title.contains(keyword) ||
      description.contains(keyword) ||
      type.contains(keyword)
    );
  }

  /// Get activity type from todo
  String _getActivityType(TodoEntity todo) {
    if (_isOutdoorActivity(todo)) return 'outdoor';

    final type = todo.type.toLowerCase();
    switch (type) {
      case 'work':
      case 'appointment':
        return 'commute';
      default:
        return 'general';
    }
  }

  /// Format time for display
  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Clear suggestions
  void clearSuggestions() {
    state = const SmartPlanningState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for smart planning coordinator
final smartPlanningProvider = StateNotifierProvider<SmartPlanningNotifier, SmartPlanningState>((ref) {
  return SmartPlanningNotifier(ref);
});
