// Application configuration, resolved at build time via --dart-define.
//
// Expected flags:
//   --dart-define=SUPABASE_URL=https://<project>.supabase.co
//   --dart-define=SUPABASE_ANON_KEY=<anon-key>
//   --dart-define=LOCAL_DB_PASSWORD=<postgres-password>
enum BackendMode { local, supabase }

class AppConfig {
  static const BackendMode mode = BackendMode.local; // Default to local

  static bool get isLocal => mode == BackendMode.local;
  static bool get isSupabase => mode == BackendMode.supabase;

  // Local DB Params
  static const String localHost = 'localhost';
  static const int localPort = 5432;
  static const String localDatabase = 'rh_manager';
  static const String localUsername = 'postgres';
  static const String localPassword =
      String.fromEnvironment('LOCAL_DB_PASSWORD', defaultValue: 'postgres');

  // Supabase Params
  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: 'http://localhost:54321');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static String get androidEmulatorHost => '10.0.2.2';
}
