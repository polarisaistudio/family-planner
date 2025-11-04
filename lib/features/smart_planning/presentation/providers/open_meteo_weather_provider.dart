import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/open_meteo_weather_service.dart';

/// Provider for OpenMeteoWeatherService singleton
final openMeteoWeatherServiceProvider = Provider<OpenMeteoWeatherService>((ref) {
  return OpenMeteoWeatherService();
});

/// State class for weather data
class OpenMeteoWeatherState {
  final WeatherData? currentWeather;
  final List<WeatherData>? forecast;
  final bool isLoading;
  final String? error;

  const OpenMeteoWeatherState({
    this.currentWeather,
    this.forecast,
    this.isLoading = false,
    this.error,
  });

  OpenMeteoWeatherState copyWith({
    WeatherData? currentWeather,
    List<WeatherData>? forecast,
    bool? isLoading,
    String? error,
  }) {
    return OpenMeteoWeatherState(
      currentWeather: currentWeather ?? this.currentWeather,
      forecast: forecast ?? this.forecast,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing weather state
class OpenMeteoWeatherNotifier extends StateNotifier<OpenMeteoWeatherState> {
  final OpenMeteoWeatherService _weatherService;

  OpenMeteoWeatherNotifier(this._weatherService) : super(const OpenMeteoWeatherState());

  /// Fetch current weather by coordinates
  Future<void> fetchCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final weather = await _weatherService.getCurrentWeather(
        latitude: latitude,
        longitude: longitude,
      );

      if (weather != null) {
        state = state.copyWith(
          currentWeather: weather,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch weather data',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch weather forecast
  Future<void> fetchForecast({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
  }) async {
    try {
      final forecast = await _weatherService.getForecast(
        latitude: latitude,
        longitude: longitude,
        forecastDays: forecastDays,
      );

      if (forecast != null) {
        state = state.copyWith(forecast: forecast);
      }
    } catch (e) {
      print('Error fetching forecast: $e');
    }
  }

  /// Check if weather is outdoor-friendly
  bool isOutdoorFriendly() {
    if (state.currentWeather == null) return false;
    return _weatherService.isOutdoorFriendly(state.currentWeather!);
  }

  /// Get weather advice for a specific activity
  String getWeatherAdvice(bool isOutdoorActivity) {
    if (state.currentWeather == null) {
      return 'Unable to fetch weather data';
    }
    return _weatherService.getWeatherAdvice(
      weather: state.currentWeather!,
      isOutdoorActivity: isOutdoorActivity,
    );
  }

  /// Check if it will rain at a specific time
  Future<bool> willRain({
    required double latitude,
    required double longitude,
    required DateTime targetTime,
  }) async {
    return await _weatherService.willRain(
      latitude: latitude,
      longitude: longitude,
      targetTime: targetTime,
    );
  }

  /// Get weather emoji
  String getWeatherEmoji() {
    if (state.currentWeather == null) return '🌡️';
    return _weatherService.getWeatherEmoji(state.currentWeather!);
  }

  /// Get outfit suggestion
  String getOutfitSuggestion() {
    if (state.currentWeather == null) return 'Check weather first';
    return _weatherService.getOutfitSuggestion(state.currentWeather!);
  }

  /// Get weather summary
  String getWeatherSummary() {
    if (state.currentWeather == null) return 'No weather data';
    return _weatherService.getWeatherSummary(state.currentWeather!);
  }

  /// Clear weather data
  void clear() {
    state = const OpenMeteoWeatherState();
  }
}

/// Provider for weather state notifier
final openMeteoWeatherProvider = StateNotifierProvider<OpenMeteoWeatherNotifier, OpenMeteoWeatherState>((ref) {
  final weatherService = ref.watch(openMeteoWeatherServiceProvider);
  return OpenMeteoWeatherNotifier(weatherService);
});
