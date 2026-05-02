/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'AttendanceOS';
  static const String appVersion = '1.0.0';

  // Supabase Configuration
  // Android emulator cannot access host localhost directly; it must use 127.0.0.1.
  // Override with --dart-define=SUPABASE_URL=... when using physical devices or cloud Supabase.
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54331',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH',
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
