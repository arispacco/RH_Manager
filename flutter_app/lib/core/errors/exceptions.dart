/// Base exception for the data layer.
///
/// These are caught by repositories and converted to [Failure] objects
/// for the domain/presentation layers.
class AppException implements Exception {
  const AppException({this.message = 'An unexpected error occurred'});

  final String message;

  @override
  String toString() => 'AppException: $message';
}

/// Thrown when a network call fails at the HTTP level.
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error',
    this.statusCode,
  });

  final int? statusCode;
}

/// Thrown when there is no internet connectivity.
class NetworkException extends AppException {
  const NetworkException({super.message = 'No internet connection'});
}

/// Thrown when local cache read/write fails.
class CacheException extends AppException {
  const CacheException({super.message = 'Cache error'});
}

/// Thrown on authentication errors (401, bad credentials).
class AuthException extends AppException {
  const AuthException({super.message = 'Authentication error'});
}
