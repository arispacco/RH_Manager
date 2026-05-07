enum BackendMode { local, supabase }

class AppConfig {
  static const BackendMode mode = BackendMode.local; // Default to local

  static bool get isLocal => mode == BackendMode.local;
  static bool get isSupabase => mode == BackendMode.supabase;

  // Local DB Params
  static const String localHost = '10.0.2.2'; // For Android Emulator
  static const int localPort = 5432;
  static const String localDatabase = 'rh_manager';
  static const String localUsername = 'postgres';
  static const String localPassword = 'postgres';

  // Supabase Params
  static const String supabaseUrl = 'https://your-project.supabase.co';
  static const String supabaseAnonKey = 'your-anon-key';
}
