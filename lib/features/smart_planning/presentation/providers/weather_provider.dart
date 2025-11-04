import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather/weather.dart';
import '../../data/services/weather_service.dart';

/// Provider for WeatherService singleton
final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

/// State class for weather data
class WeatherState {
  final Weather? currentWeather;
  final List<Weather>? forecast;
  final bool isLoading;
  final String? error;

  const WeatherState({
    this.currentWeather,
    this.forecast,
    this.isLoading = false,
    this.error,
  });

  WeatherState copyWith({
    Weather? currentWeather,
    List<Weather>? forecast,
    bool? isLoading,
    String? error,
  }) {
    return WeatherState(
      currentWeather: currentWeather ?? this.currentWeather,
      forecast: forecast ?? this.forecast,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing weather state
class WeatherNotifier extends StateNotifier<WeatherState> {
  final WeatherService _weatherService;

  WeatherNotifier(this._weatherService) : super(const WeatherState());

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

  /// Fetch current weather by city name
  Future<void> fetchCurrentWeatherByCity(String cityName) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final weather = await _weatherService.getCurrentWeatherByCity(cityName);

      if (weather != null) {
        state = state.copyWith(
          currentWeather: weather,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to fetch weather data for $cityName',
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
  }) async {
    try {
      final forecast = await _weatherService.getForecast(
        latitude: latitude,
        longitude: longitude,
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
    state = const WeatherState();
  }
}

/// Provider for weather state notifier
final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  return WeatherNotifier(weatherService);
});
