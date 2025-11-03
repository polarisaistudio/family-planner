import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;

/// Service to handle location-related operations
/// Provides current location, distance calculations, and geofencing
class LocationService {
  /// Get current location
  /// Returns null if location services are disabled or permission denied
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('🔴 [LOCATION] Location services are disabled');
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('🔴 [LOCATION] Location permission denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('🔴 [LOCATION] Location permission permanently denied');
        return null;
      }

      // Get current position
      print('🔵 [LOCATION] Fetching current location...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print('🟢 [LOCATION] Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('🔴 [LOCATION] Error getting location: $e');
      return null;
    }
  }

  /// Get last known location (faster but may be stale)
  Future<Position?> getLastKnownLocation() async {
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        print('🟢 [LOCATION] Last known location: ${position.latitude}, ${position.longitude}');
      }
      return position;
    } catch (e) {
      print('🔴 [LOCATION] Error getting last known location: $e');
      return null;
    }
  }

  /// Calculate distance between two points in meters
  /// Uses Haversine formula for accuracy
  double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final distance = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    print('🔵 [LOCATION] Distance calculated: ${distance.toStringAsFixed(0)}m');
    return distance;
  }

  /// Calculate distance from current location to a point
  Future<double?> calculateDistanceFromCurrent({
    required double targetLat,
    required double targetLon,
  }) async {
    final currentPosition = await getCurrentLocation();
    if (currentPosition == null) return null;

    return calculateDistance(
      lat1: currentPosition.latitude,
      lon1: currentPosition.longitude,
      lat2: targetLat,
      lon2: targetLon,
    );
  }

  /// Check if current location is within geofence radius
  /// Returns true if within radius, false otherwise
  Future<bool> isWithinGeofence({
    required double targetLat,
    required double targetLon,
    required double radiusMeters,
  }) async {
    final distance = await calculateDistanceFromCurrent(
      targetLat: targetLat,
      targetLon: targetLon,
    );

    if (distance == null) return false;

    final isWithin = distance <= radiusMeters;
    print('🔵 [LOCATION] Geofence check: ${isWithin ? "INSIDE" : "OUTSIDE"} (${distance.toStringAsFixed(0)}m / ${radiusMeters.toStringAsFixed(0)}m)');

    return isWithin;
  }

  /// Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      print('🔵 [LOCATION] Reverse geocoding: $latitude, $longitude');
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        print('🔴 [LOCATION] No address found for coordinates');
        return null;
      }

      final place = placemarks.first;
      final address = [
        place.street,
        place.locality,
        place.administrativeArea,
        place.country,
      ].where((e) => e != null && e.isNotEmpty).join(', ');

      print('🟢 [LOCATION] Address: $address');
      return address;
    } catch (e) {
      print('🔴 [LOCATION] Error reverse geocoding: $e');
      return null;
    }
  }

  /// Get coordinates from address (forward geocoding)
  Future<Location?> getCoordinatesFromAddress(String address) async {
    try {
      print('🔵 [LOCATION] Geocoding address: $address');
      final locations = await locationFromAddress(address);

      if (locations.isEmpty) {
        print('🔴 [LOCATION] No coordinates found for address');
        return null;
      }

      final location = locations.first;
      print('🟢 [LOCATION] Coordinates: ${location.latitude}, ${location.longitude}');
      return location;
    } catch (e) {
      print('🔴 [LOCATION] Error geocoding address: $e');
      return null;
    }
  }

  /// Stream of position updates
  /// Use for continuous location tracking
  Stream<Position> getPositionStream({
    int distanceFilterMeters = 50,
    int intervalMilliseconds = 5000,
  }) {
    print('🔵 [LOCATION] Starting position stream (filter: ${distanceFilterMeters}m, interval: ${intervalMilliseconds}ms)');

    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
        timeLimit: Duration(milliseconds: intervalMilliseconds),
      ),
    );
  }

  /// Calculate bearing (direction) between two points
  /// Returns angle in degrees (0-360, where 0 is North)
  double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final bearing = Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
    return bearing;
  }

  /// Convert bearing to cardinal direction (N, NE, E, SE, S, SW, W, NW)
  String bearingToCardinal(double bearing) {
    final directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % 8;
    return directions[index];
  }

  /// Estimate time to reach destination (in minutes)
  /// Based on straight-line distance and average speed
  /// For more accurate estimates, use TrafficService
  double estimateTravelTime({
    required double distanceMeters,
    double averageSpeedKmh = 40, // Default: urban driving speed
  }) {
    final distanceKm = distanceMeters / 1000;
    final timeHours = distanceKm / averageSpeedKmh;
    final timeMinutes = timeHours * 60;

    print('🔵 [LOCATION] Estimated travel time: ${timeMinutes.toStringAsFixed(0)} minutes');
    return timeMinutes;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Get location accuracy in meters
  /// Returns the horizontal accuracy of the position
  double getAccuracy(Position position) {
    return position.accuracy;
  }

  /// Check if location is accurate enough for geofencing
  /// Recommended: accuracy < geofence radius / 2
  bool isAccurateSufficient(Position position, double geofenceRadius) {
    final sufficientAccuracy = geofenceRadius / 2;
    final isAccurate = position.accuracy <= sufficientAccuracy;

    if (!isAccurate) {
      print('🔴 [LOCATION] Accuracy insufficient: ${position.accuracy}m (need < ${sufficientAccuracy}m)');
    }

    return isAccurate;
  }

  /// Format distance for display
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)}m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  /// Format coordinates for display
  String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
}
