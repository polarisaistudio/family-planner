import 'package:weather/weather.dart';

/// Service to fetch weather data
/// Uses OpenWeatherMap API for weather information
class WeatherService {
  static const String _apiKey = 'YOUR_OPENWEATHERMAP_API_KEY'; // TODO: Move to environment variables
  late final WeatherFactory _weatherFactory;

  WeatherService() {
    _weatherFactory = WeatherFactory(_apiKey);
  }

  /// Get current weather for coordinates
  Future<Weather?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('🔵 [WEATHER] Fetching current weather for $latitude, $longitude');

      final weather = await _weatherFactory.currentWeatherByLocation(
        latitude,
        longitude,
      );

      print('🟢 [WEATHER] Weather: ${weather.weatherMain}, ${weather.temperature?.celsius?.toStringAsFixed(1)}°C');
      return weather;
    } catch (e) {
      print('🔴 [WEATHER] Error fetching weather: $e');
      return null;
    }
  }

  /// Get current weather by city name
  Future<Weather?> getCurrentWeatherByCity(String cityName) async {
    try {
      print('🔵 [WEATHER] Fetching weather for city: $cityName');

      final weather = await _weatherFactory.currentWeatherByCityName(cityName);

      print('🟢 [WEATHER] Weather in $cityName: ${weather.weatherMain}, ${weather.temperature?.celsius?.toStringAsFixed(1)}°C');
      return weather;
    } catch (e) {
      print('🔴 [WEATHER] Error fetching weather by city: $e');
      return null;
    }
  }

  /// Get 5-day forecast for coordinates
  Future<List<Weather>?> getForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('🔵 [WEATHER] Fetching 5-day forecast for $latitude, $longitude');

      final forecast = await _weatherFactory.fiveDayForecastByLocation(
        latitude,
        longitude,
      );

      print('🟢 [WEATHER] Forecast: ${forecast.length} data points');
      return forecast;
    } catch (e) {
      print('🔴 [WEATHER] Error fetching forecast: $e');
      return null;
    }
  }

  /// Check if weather is suitable for outdoor activities
  bool isOutdoorFriendly(Weather weather) {
    // Check for rain
    if (weather.weatherMain?.toLowerCase().contains('rain') ?? false) {
      return false;
    }

    // Check for snow
    if (weather.weatherMain?.toLowerCase().contains('snow') ?? false) {
      return false;
    }

    // Check for thunderstorm
    if (weather.weatherMain?.toLowerCase().contains('thunderstorm') ?? false) {
      return false;
    }

    // Check temperature (comfortable range: 10-30°C)
    final tempCelsius = weather.temperature?.celsius ?? 20;
    if (tempCelsius < 10 || tempCelsius > 30) {
      return false;
    }

    return true;
  }

  /// Get weather condition emoji
  String getWeatherEmoji(Weather weather) {
    final condition = weather.weatherMain?.toLowerCase() ?? '';

    if (condition.contains('clear') || condition.contains('sun')) {
      return '☀️';
    } else if (condition.contains('cloud')) {
      return '☁️';
    } else if (condition.contains('rain')) {
      return '🌧️';
    } else if (condition.contains('snow')) {
      return '❄️';
    } else if (condition.contains('thunder')) {
      return '⛈️';
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return '🌫️';
    }

    return '🌤️';
  }

  /// Get outfit suggestion based on weather
  String getOutfitSuggestion(Weather weather) {
    final tempCelsius = weather.temperature?.celsius ?? 20;
    final condition = weather.weatherMain?.toLowerCase() ?? '';

    if (condition.contains('rain')) {
      return 'Bring an umbrella ☔';
    } else if (condition.contains('snow')) {
      return 'Wear warm clothes and boots 🧥';
    } else if (tempCelsius < 10) {
      return 'Dress warmly 🧥';
    } else if (tempCelsius > 25) {
      return 'Light clothes recommended 👕';
    } else if (condition.contains('wind')) {
      return 'Wear a jacket 🧥';
    }

    return 'Comfortable weather 👍';
  }

  /// Check if user should be alerted about weather
  bool shouldAlertUser({
    required Weather weather,
    required bool isOutdoorActivity,
  }) {
    // Always alert for severe weather
    final condition = weather.weatherMain?.toLowerCase() ?? '';
    if (condition.contains('thunder') ||
        condition.contains('storm') ||
        condition.contains('extreme')) {
      return true;
    }

    // Alert for outdoor activities in bad weather
    if (isOutdoorActivity && !isOutdoorFriendly(weather)) {
      return true;
    }

    return false;
  }

  /// Get weather summary for display
  String getWeatherSummary(Weather weather) {
    final temp = weather.temperature?.celsius?.toStringAsFixed(0) ?? '--';
    final condition = weather.weatherMain ?? 'Unknown';
    final description = weather.weatherDescription ?? '';

    return '$condition, $temp°C${description.isNotEmpty ? " - $description" : ""}';
  }

  /// Get weather for a future time (from forecast)
  Future<Weather?> getWeatherForTime({
    required double latitude,
    required double longitude,
    required DateTime targetTime,
  }) async {
    try {
      final forecast = await getForecast(
        latitude: latitude,
        longitude: longitude,
      );

      if (forecast == null || forecast.isEmpty) return null;

      // Find the closest forecast to target time
      Weather? closest;
      Duration? smallestDiff;

      for (final weather in forecast) {
        if (weather.date == null) continue;

        final diff = weather.date!.difference(targetTime).abs();

        if (smallestDiff == null || diff < smallestDiff) {
          smallestDiff = diff;
          closest = weather;
        }
      }

      if (closest != null) {
        print('🟢 [WEATHER] Found forecast for ${closest.date}: ${closest.weatherMain}');
      }

      return closest;
    } catch (e) {
      print('🔴 [WEATHER] Error getting weather for time: $e');
      return null;
    }
  }

  /// Check if it will rain at the target time
  Future<bool> willRain({
    required double latitude,
    required double longitude,
    required DateTime targetTime,
  }) async {
    final weather = await getWeatherForTime(
      latitude: latitude,
      longitude: longitude,
      targetTime: targetTime,
    );

    if (weather == null) return false;

    final condition = weather.weatherMain?.toLowerCase() ?? '';
    return condition.contains('rain');
  }

  /// Get temperature at target time
  Future<double?> getTemperatureForTime({
    required double latitude,
    required double longitude,
    required DateTime targetTime,
  }) async {
    final weather = await getWeatherForTime(
      latitude: latitude,
      longitude: longitude,
      targetTime: targetTime,
    );

    return weather?.temperature?.celsius;
  }

  /// Get precipitation probability (if available)
  double? getPrecipitationProbability(Weather weather) {
    // Note: The weather package doesn't directly provide precipitation probability
    // This would need to be fetched from the raw API response
    // For now, we'll estimate based on weather condition
    final condition = weather.weatherMain?.toLowerCase() ?? '';

    if (condition.contains('rain')) {
      return 0.8; // 80% chance
    } else if (condition.contains('drizzle')) {
      return 0.5; // 50% chance
    } else if (condition.contains('cloud')) {
      return 0.2; // 20% chance
    }

    return 0.0; // No rain expected
  }

  /// Format temperature for display
  String formatTemperature(double? celsius) {
    if (celsius == null) return '--°C';
    return '${celsius.toStringAsFixed(0)}°C';
  }

  /// Get wind speed description
  String getWindDescription(Weather weather) {
    final speed = weather.windSpeed ?? 0;

    if (speed < 5) return 'Calm';
    if (speed < 10) return 'Light breeze';
    if (speed < 20) return 'Moderate wind';
    if (speed < 30) return 'Strong wind';
    return 'Very strong wind';
  }

  /// Check if weather data is stale
  bool isWeatherStale(Weather weather) {
    if (weather.date == null) return true;

    final now = DateTime.now();
    final age = now.difference(weather.date!);

    // Consider data stale if older than 30 minutes
    return age.inMinutes > 30;
  }

  /// Get human-readable weather advice
  String getWeatherAdvice({
    required Weather weather,
    required bool isOutdoorActivity,
  }) {
    final condition = weather.weatherMain?.toLowerCase() ?? '';
    final temp = weather.temperature?.celsius ?? 20;

    if (condition.contains('rain')) {
      if (isOutdoorActivity) {
        return 'Rain expected. Consider rescheduling or bring an umbrella.';
      }
      return 'Rain expected. Drive carefully.';
    }

    if (condition.contains('snow')) {
      return 'Snow expected. Allow extra travel time and dress warmly.';
    }

    if (condition.contains('thunder')) {
      return 'Thunderstorm expected. Stay indoors if possible.';
    }

    if (temp < 5) {
      return 'Very cold. Dress in layers and protect exposed skin.';
    }

    if (temp > 30) {
      return 'Very hot. Stay hydrated and seek shade when possible.';
    }

    if (isOutdoorActivity && !isOutdoorFriendly(weather)) {
      return 'Weather may not be ideal for outdoor activities.';
    }

    return 'Weather looks good! ${getOutfitSuggestion(weather)}';
  }
}
