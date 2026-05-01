import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../core/network/api_client.dart';
import '../core/services/location_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/attendance/presentation/bloc/attendance_bloc.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies in the service locator.
///
/// Call this once before `runApp()`.
Future<void> initDependencies() async {
  // ── Core ────────────────────────────────────────────────────
  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
  }

  if (!sl.isRegistered<ApiClient>()) {
    sl.registerLazySingleton<ApiClient>(
      () => ApiClient(secureStorage: sl<FlutterSecureStorage>()),
    );
  }

  if (!sl.isRegistered<LocationService>()) {
    sl.registerLazySingleton<LocationService>(() => LocationService());
  }

  // ── BLoCs ───────────────────────────────────────────────────
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerLazySingleton<AuthBloc>(() => AuthBloc());
  }
  if (!sl.isRegistered<AttendanceBloc>()) {
    sl.registerLazySingleton<AttendanceBloc>(
      () => AttendanceBloc(locationService: sl<LocationService>()),
    );
  }
}
