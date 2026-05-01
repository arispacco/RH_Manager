/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'AttendanceOS';
  static const String appVersion = '1.0.0';

  // API — Update this when the BaaS URL is available
  static const String baseUrl = 'https://api.attendanceos.com';
  static const int connectTimeout = 15000; // ms
  static const int receiveTimeout = 15000; // ms

  // Geofencing
  static const double defaultGeofenceRadiusMeters = 100.0;

  // QR Code
  static const int qrRotationSeconds = 30;

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // Date formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
}
