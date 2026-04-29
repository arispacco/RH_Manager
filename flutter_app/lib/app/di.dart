import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../core/network/api_client.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

/// Global service locator instance.
final GetIt sl = GetIt.instance;

/// Registers all dependencies in the service locator.
///
/// Call this once before `runApp()`.
Future<void> initDependencies() async {
  // ── Core ────────────────────────────────────────────────────
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(secureStorage: sl<FlutterSecureStorage>()),
  );

  // ── BLoCs ───────────────────────────────────────────────────
  // AuthBloc is registered as a singleton because it must persist
  // across the entire app lifecycle.
  sl.registerLazySingleton<AuthBloc>(() => AuthBloc());

  // TODO: Register additional BLoCs/repositories as features are built
  // sl.registerFactory<AttendanceBloc>(() => AttendanceBloc(...));
}
