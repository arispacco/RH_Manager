import 'package:flutter_test/flutter_test.dart';

import 'package:attendance_os_mobile/app/config.dart';

void main() {
  group('AppConfig', () {
    test('falls back to local development defaults', () {
      expect(AppConfig.mode, BackendMode.local);
      expect(AppConfig.isLocal, isTrue);
      expect(AppConfig.isSupabase, isFalse);

      // dart-define defaults: empty Supabase credentials, well-known
      // local database password.
      expect(AppConfig.supabaseUrl, 'http://localhost:54321');
      expect(AppConfig.supabaseAnonKey, isEmpty);
      expect(AppConfig.localPassword, 'postgres');
    });

    test('keeps local database defaults coherent', () {
      expect(AppConfig.localHost, 'localhost');
      expect(AppConfig.localPort, 5432);
      expect(AppConfig.localDatabase, 'rh_manager');
      expect(AppConfig.localUsername, 'postgres');
      expect(AppConfig.androidEmulatorHost, '10.0.2.2');
    });
  });
}
