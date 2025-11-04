import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/services/location_service.dart';

/// Provider for LocationService singleton
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

/// State class for location data
class LocationState {
  final Position? currentPosition;
  final String? currentAddress;
  final bool isLoading;
  final String? error;
  final bool isTracking;

  const LocationState({
    this.currentPosition,
    this.currentAddress,
    this.isLoading = false,
    this.error,
    this.isTracking = false,
  });

  LocationState copyWith({
    Position? currentPosition,
    String? currentAddress,
    bool? isLoading,
    String? error,
    bool? isTracking,
  }) {
    return LocationState(
      currentPosition: currentPosition ?? this.currentPosition,
      currentAddress: currentAddress ?? this.currentAddress,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isTracking: isTracking ?? this.isTracking,
    );
  }

  /// Get formatted coordinates string
  String? get formattedCoordinates {
    if (currentPosition == null) return null;
    return '${currentPosition!.latitude.toStringAsFixed(6)}, ${currentPosition!.longitude.toStringAsFixed(6)}';
  }
}

/// Notifier for managing location state
class LocationNotifier extends StateNotifier<LocationState> {
  final LocationService _locationService;

  LocationNotifier(this._locationService) : super(const LocationState());

  /// Fetch current location
  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final position = await _locationService.getCurrentLocation();

      if (position != null) {
        state = state.copyWith(
          currentPosition: position,
          isLoading: false,
        );

        // Also fetch address
        await _fetchAddress(position.latitude, position.longitude);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to get current location',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Fetch last known location (faster)
  Future<void> fetchLastKnownLocation() async {
    try {
      final position = await _locationService.getLastKnownLocation();
      if (position != null) {
        state = state.copyWith(currentPosition: position);
      }
    } catch (e) {
      print('Error fetching last known location: $e');
    }
  }

  /// Fetch address for current position
  Future<void> _fetchAddress(double latitude, double longitude) async {
    try {
      final address = await _locationService.getAddressFromCoordinates(
        latitude: latitude,
        longitude: longitude,
      );

      if (address != null) {
        state = state.copyWith(currentAddress: address);
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  /// Calculate distance to a target location
  Future<double?> calculateDistanceTo({
    required double targetLat,
    required double targetLon,
  }) async {
    if (state.currentPosition == null) {
      await fetchCurrentLocation();
    }

    if (state.currentPosition == null) return null;

    return _locationService.calculateDistance(
      lat1: state.currentPosition!.latitude,
      lon1: state.currentPosition!.longitude,
      lat2: targetLat,
      lon2: targetLon,
    );
  }

  /// Check if within geofence
  Future<bool> isWithinGeofence({
    required double targetLat,
    required double targetLon,
    required double radiusMeters,
  }) async {
    return await _locationService.isWithinGeofence(
      targetLat: targetLat,
      targetLon: targetLon,
      radiusMeters: radiusMeters,
    );
  }

  /// Format distance for display
  String formatDistance(double meters) {
    return _locationService.formatDistance(meters);
  }

  /// Get coordinates from address
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      final location = await _locationService.getCoordinatesFromAddress(address);
      if (location != null) {
        return {
          'latitude': location.latitude,
          'longitude': location.longitude,
        };
      }
    } catch (e) {
      print('Error geocoding address: $e');
    }
    return null;
  }

  /// Estimate travel time
  double estimateTravelTime({
    required double distanceMeters,
    double averageSpeedKmh = 40,
  }) {
    return _locationService.estimateTravelTime(
      distanceMeters: distanceMeters,
      averageSpeedKmh: averageSpeedKmh,
    );
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _locationService.isLocationServiceEnabled();
  }

  /// Open location settings
  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
  }

  /// Clear location data
  void clear() {
    state = const LocationState();
  }
}

/// Provider for location state notifier
final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return LocationNotifier(locationService);
});

/// Provider for location stream (real-time tracking)
/// Use this for continuous location updates
final locationStreamProvider = StreamProvider.autoDispose<Position>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.getPositionStream(
    distanceFilterMeters: 50,
    intervalMilliseconds: 5000,
  );
});
