import 'dart:convert';
import 'package:http/http.dart' as http;

/// Weather data model
class WeatherData {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;
  final double precipitation;
  final DateTime time;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
    required this.precipitation,
    required this.time,
  });

  /// Get weather condition from weather code
  /// https://open-meteo.com/en/docs
  String get weatherCondition {
    if (weatherCode == 0) return 'Clear';
    if (weatherCode >= 1 && weatherCode <= 3) return 'Partly Cloudy';
    if (weatherCode >= 45 && weatherCode <= 48) return 'Fog';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Rain';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snow';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain Showers';
    if (weatherCode >= 85 && weatherCode <= 86) return 'Snow Showers';
    if (weatherCode >= 95 && weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  /// Get weather emoji
  String get emoji {
    final condition = weatherCondition.toLowerCase();
    if (condition.contains('clear')) return '☀️';
    if (condition.contains('cloudy')) return '☁️';
    if (condition.contains('rain')) return '🌧️';
    if (condition.contains('snow')) return '❄️';
    if (condition.contains('thunder')) return '⛈️';
    if (condition.contains('fog')) return '🌫️';
    return '🌤️';
  }

  /// Check if weather is outdoor-friendly
  bool get isOutdoorFriendly {
    // Not outdoor-friendly if raining, snowing, or thunderstorm
    if (weatherCode >= 51 && weatherCode <= 67) return false; // Rain
    if (weatherCode >= 71 && weatherCode <= 77) return false; // Snow
    if (weatherCode >= 80 && weatherCode <= 86) return false; // Showers
    if (weatherCode >= 95 && weatherCode <= 99) return false; // Thunderstorm

    // Check temperature (comfortable range: 10-30°C)
    if (temperature < 10 || temperature > 30) return false;

    return true;
  }
}

/// Service to fetch weather data from Open-Meteo (100% Free, No API Key Required!)
/// https://open-meteo.com/
class OpenMeteoWeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  /// Get current weather for coordinates
  Future<WeatherData?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('🔵 [WEATHER] Fetching current weather for $latitude, $longitude');

      final url = Uri.parse(
        '$_baseUrl/forecast?latitude=$latitude&longitude=$longitude'
        '&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m'
        '&temperature_unit=celsius&wind_speed_unit=kmh',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('🔴 [WEATHER] Error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      final current = data['current'];

      final weather = WeatherData(
        temperature: (current['temperature_2m'] as num).toDouble(),
        weatherCode: current['weather_code'] as int,
        windSpeed: (current['wind_speed_10m'] as num).toDouble(),
        humidity: current['relative_humidity_2m'] as int,
        precipitation: (current['precipitation'] as num).toDouble(),
        time: DateTime.parse(current['time']),
      );

      print('🟢 [WEATHER] Weather: ${weather.weatherCondition}, ${weather.temperature.toStringAsFixed(1)}°C');
      return weather;
    } catch (e) {
      print('🔴 [WEATHER] Error fetching weather: $e');
      return null;
    }
  }

  /// Get hourly forecast for the next 7 days
  Future<List<WeatherData>?> getForecast({
    required double latitude,
    required double longitude,
    int forecastDays = 7,
  }) async {
    try {
      print('🔵 [WEATHER] Fetching $forecastDays-day forecast for $latitude, $longitude');

      final url = Uri.parse(
        '$_baseUrl/forecast?latitude=$latitude&longitude=$longitude'
        '&hourly=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m'
        '&temperature_unit=celsius&wind_speed_unit=kmh&forecast_days=$forecastDays',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        print('🔴 [WEATHER] Error: ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      final hourly = data['hourly'];

      final List<WeatherData> forecast = [];
      final times = hourly['time'] as List;

      for (int i = 0; i < times.length; i++) {
        forecast.add(WeatherData(
          temperature: (hourly['temperature_2m'][i] as num).toDouble(),
          weatherCode: hourly['weather_code'][i] as int,
          windSpeed: (hourly['wind_speed_10m'][i] as num).toDouble(),
          humidity: hourly['relative_humidity_2m'][i] as int,
          precipitation: (hourly['precipitation'][i] as num).toDouble(),
          time: DateTime.parse(times[i]),
        ));
      }

      print('🟢 [WEATHER] Forecast: ${forecast.length} hourly data points');
      return forecast;
    } catch (e) {
      print('🔴 [WEATHER] Error fetching forecast: $e');
      return null;
    }
  }

  /// Check if it will rain at the target time
  Future<bool> willRain({
    required double latitude,
    required double longitude,
    required DateTime targetTime,
  }) async {
    final forecast = await getForecast(
      latitude: latitude,
      longitude: longitude,
      forecastDays: 7,
    );

    if (forecast == null) return false;

    // Find the closest forecast to target time
    WeatherData? closest;
    Duration? smallestDiff;

    for (final weather in forecast) {
      final diff = weather.time.difference(targetTime).abs();
      if (smallestDiff == null || diff < smallestDiff) {
        smallestDiff = diff;
        closest = weather;
      }
    }

    if (closest == null) return false;

    // Check if it's a rain weather code
    final code = closest.weatherCode;
    return (code >= 51 && code <= 67) || (code >= 80 && code <= 82);
  }

  /// Get weather advice for an activity
  String getWeatherAdvice({
    required WeatherData weather,
    required bool isOutdoorActivity,
  }) {
    final condition = weather.weatherCondition.toLowerCase();
    final temp = weather.temperature;

    if (condition.contains('rain')) {
      if (isOutdoorActivity) {
        return 'Rain expected. Consider rescheduling or bring an umbrella.';
      }
      return 'Rain expected. Drive carefully.';
    }

    if (condition.contains('snow')) {
      return 'Snow expected. Dress warmly and allow extra travel time.';
    }

    if (condition.contains('thunder')) {
      return 'Thunderstorm expected. Stay indoors if possible.';
    }

    if (temp < 10) {
      return 'Cold weather. Dress warmly with layers.';
    }

    if (temp > 30) {
      return 'Hot weather. Stay hydrated and use sun protection.';
    }

    if (condition.contains('fog')) {
      return 'Foggy conditions. Drive carefully with reduced visibility.';
    }

    if (weather.isOutdoorFriendly) {
      return 'Great weather for outdoor activities!';
    }

    return 'Check current conditions before heading out.';
  }

  /// Get outfit suggestion based on weather
  String getOutfitSuggestion(WeatherData weather) {
    final temp = weather.temperature;
    final condition = weather.weatherCondition.toLowerCase();

    if (condition.contains('rain')) {
      return 'Bring an umbrella ☔';
    } else if (condition.contains('snow')) {
      return 'Wear warm clothes and boots 🧥';
    } else if (temp < 10) {
      return 'Dress warmly 🧥';
    } else if (temp > 25) {
      return 'Light clothes recommended 👕';
    } else if (weather.windSpeed > 20) {
      return 'Wear a jacket 🧥';
    }

    return 'Comfortable weather 👍';
  }

  /// Get weather summary for display
  String getWeatherSummary(WeatherData weather) {
    return '${weather.weatherCondition}, ${weather.temperature.toStringAsFixed(0)}°C';
  }

  /// Format temperature for display
  String formatTemperature(double? celsius) {
    if (celsius == null) return '--°C';
    return '${celsius.toStringAsFixed(0)}°C';
  }

  /// Get wind speed description
  String getWindDescription(WeatherData weather) {
    final speed = weather.windSpeed;

    if (speed < 5) return 'Calm';
    if (speed < 10) return 'Light breeze';
    if (speed < 20) return 'Moderate wind';
    if (speed < 30) return 'Strong wind';
    return 'Very strong wind';
  }

  /// Check if weather is suitable for outdoor activities
  bool isOutdoorFriendly(WeatherData weather) {
    return weather.isOutdoorFriendly;
  }

  /// Get weather emoji
  String getWeatherEmoji(WeatherData weather) {
    return weather.emoji;
  }
}
