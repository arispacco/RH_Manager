import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/network/api_client.dart';
import '../core/services/location_service.dart';
import '../core/theme/theme_cubit.dart';
import '../services/postgresql_service.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/attendance_cubit.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/attendance/presentation/bloc/attendance_bloc.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies in the service locator.
///
/// Call this once before `runApp()`.
Future<void> initDependencies() async {
  // ── Core ────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  if (!sl.isRegistered<ThemeCubit>()) {
    sl.registerLazySingleton<ThemeCubit>(
        () => ThemeCubit(sl<SharedPreferences>()));
  }

  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }

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

  if (!sl.isRegistered<PostgreSQLService>()) {
    sl.registerLazySingleton<PostgreSQLService>(() => PostgreSQLService());
  }

  // ── Cubits ──────────────────────────────────────────────────
  if (!sl.isRegistered<AuthCubit>()) {
    sl.registerLazySingleton<AuthCubit>(
      () => AuthCubit(sl<PostgreSQLService>()),
    );
  }

  if (!sl.isRegistered<AttendanceCubit>()) {
    sl.registerLazySingleton<AttendanceCubit>(
      () => AttendanceCubit(sl<PostgreSQLService>()),
    );
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
