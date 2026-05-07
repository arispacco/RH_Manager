/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'AttendanceOS';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  // Local Supabase via Docker Compose on port 54332
  // For Android emulator: use 10.0.2.2 (host machine) instead of localhost
  // For physical device: use actual machine IP or cloud URL
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTYyMzAzMDMzMywiZXhwIjoyMDAwMDAwMDAwfQ.your_test_key',
  );

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
