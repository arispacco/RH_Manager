import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

import '../constants/app_constants.dart';

/// Result of a location check.
class LocationResult {
  const LocationResult({
    required this.isWithinGeofence,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    this.errorMessage,
  });

  /// Whether the user is within the allowed radius.
  final bool isWithinGeofence;

  /// Current latitude.
  final double latitude;

  /// Current longitude.
  final double longitude;

  /// Distance from the office in meters.
  final double distanceMeters;

  /// Error message if location check failed.
  final String? errorMessage;

  /// Formatted distance string.
  String get distanceFormatted {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()}m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
  }

  /// Creates an error result.
  factory LocationResult.error(String message) {
    return LocationResult(
      isWithinGeofence: false,
      latitude: 0,
      longitude: 0,
      distanceMeters: 0,
      errorMessage: message,
    );
  }
}

/// Service responsible for GPS location checks and geofencing.
///
/// Usage:
/// ```dart
/// final service = LocationService();
/// final result = await service.checkLocation(
///   officeLat: 3.8480,
///   officeLng: 11.5021,
/// );
/// if (result.isWithinGeofence) { /* allow clock-in */ }
/// ```
class LocationService {
  LocationService();

  final _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, dateTimeFormat: DateTimeFormat.none),
  );

  /// Checks if location services are enabled and permissions are granted.
  /// Returns `null` if everything is OK, or an error message string.
  Future<String?> _ensurePermissions() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Location services are disabled. Please enable GPS.';
    }

    // Check permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return 'Location permission denied. Please allow access.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return 'Location permission permanently denied. Please enable in Settings.';
    }

    return null; // All good
  }

  /// Gets the current position of the device.
  Future<Position?> getCurrentPosition() async {
    final error = await _ensurePermissions();
    if (error != null) {
      _logger.w('Location permission issue: $error');
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      _logger.e('Failed to get position', error: e);
      return null;
    }
  }

  /// Checks if the user is within the allowed geofence around the office.
  ///
  /// [officeLat] and [officeLng] are the office coordinates.
  /// [radiusMeters] is the allowed radius (defaults to [AppConstants.defaultGeofenceRadiusMeters]).
  Future<LocationResult> checkLocation({
    required double officeLat,
    required double officeLng,
    double radiusMeters = AppConstants.defaultGeofenceRadiusMeters,
  }) async {
    final permError = await _ensurePermissions();
    if (permError != null) {
      return LocationResult.error(permError);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        officeLat,
        officeLng,
      );

      _logger.i(
        'GPS check: ${position.latitude}, ${position.longitude} '
        '→ ${distance.round()}m from office (radius: ${radiusMeters.round()}m)',
      );

      return LocationResult(
        isWithinGeofence: distance <= radiusMeters,
        latitude: position.latitude,
        longitude: position.longitude,
        distanceMeters: distance,
      );
    } catch (e) {
      _logger.e('Location check failed', error: e);
      return LocationResult.error('Could not determine your location: $e');
    }
  }

  /// Streams position updates for real-time tracking.
  Stream<Position> get positionStream {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  /// Opens the device's location settings page.
  Future<bool> openSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Opens the app's permission settings page.
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }
}
