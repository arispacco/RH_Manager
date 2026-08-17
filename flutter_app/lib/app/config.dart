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

  // Supabase Params.
  // Provided at build time via --dart-define; defaults target the local
  // Supabase stack (`supabase start`). For the Android emulator, pass
  // --dart-define=SUPABASE_URL=http://10.0.2.2:54331
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:54331',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0',
  );
}
