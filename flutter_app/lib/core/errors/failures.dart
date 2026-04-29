import 'package:equatable/equatable.dart';

/// Base failure class for the domain layer.
///
/// All business-logic failures extend this so the presentation layer
/// can handle errors uniformly.
abstract class Failure extends Equatable {
  const Failure({this.message = 'An unexpected error occurred'});

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Failure when a network request fails (timeout, no connection, etc.).
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'Network error. Check your connection.'});
}

/// Failure returned by the remote server (4xx, 5xx).
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error. Please try again later.'});

  final int? statusCode = null;
}

/// Failure when reading/writing local cache.
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Local storage error.'});
}

/// Failure related to authentication (invalid credentials, expired token).
class AuthFailure extends Failure {
  const AuthFailure({super.message = 'Authentication failed.'});
}

/// Failure related to location/GPS.
class LocationFailure extends Failure {
  const LocationFailure({super.message = 'Could not determine your location.'});
}

/// Failure when the user is outside the allowed geofence.
class GeofenceFailure extends Failure {
  const GeofenceFailure({super.message = 'You are outside the allowed area.'});
}

/// Failure for permission-related issues.
class PermissionFailure extends Failure {
  const PermissionFailure({super.message = 'Required permission was denied.'});
}
