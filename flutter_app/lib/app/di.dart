import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/location_service.dart';
import '../core/theme/theme_cubit.dart';
import '../services/postgresql_service.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/attendance/presentation/bloc/attendance_bloc.dart';
import 'config.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Common Services
  if (!sl.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerLazySingleton<SharedPreferences>(() => sharedPreferences);
  }

  if (!sl.isRegistered<ThemeCubit>()) {
    sl.registerLazySingleton<ThemeCubit>(
        () => ThemeCubit(sl<SharedPreferences>()));
  }

  if (!sl.isRegistered<FlutterSecureStorage>()) {
    sl.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
  }

  if (!sl.isRegistered<LocationService>()) {
    sl.registerLazySingleton<LocationService>(() => LocationService());
  }

  // Backend Specific Registration
  if (AppConfig.isSupabase) {
    if (!sl.isRegistered<SupabaseClient>()) {
      try {
        await Supabase.initialize(
          url: AppConfig.supabaseUrl,
          anonKey: AppConfig.supabaseAnonKey,
        );
        sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
      } catch (e) {
        // Handle initialization error
      }
    }
  } else {
    // Local PostgreSQL Mode
    if (!sl.isRegistered<PostgreSQLService>()) {
      sl.registerLazySingleton<PostgreSQLService>(() => PostgreSQLService());
    }
  }

  // Blocs
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerLazySingleton<AuthBloc>(() => AuthBloc());
  }

  if (!sl.isRegistered<AttendanceBloc>()) {
    sl.registerLazySingleton<AttendanceBloc>(
      () => AttendanceBloc(
        locationService: sl<LocationService>(),
        postgres: sl.isRegistered<PostgreSQLService>() ? sl<PostgreSQLService>() : null,
        authBloc: sl<AuthBloc>(),
      ),
    );
  }
}
