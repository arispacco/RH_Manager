import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_entity.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Manages the global authentication state.
///
/// For the prototype phase this uses mock data.
/// When the BaaS is ready, inject an AuthRepository and
/// delegate to its methods instead of the mock helpers.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  // ── Handlers ──────────────────────────────────────────────────

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // TODO: Check flutter_secure_storage for a cached token
    // and validate it with the BaaS.
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));

      // TODO: Replace with actual BaaS auth call
      // final user = await _authRepository.login(event.email, event.password);

      final role = roleFromEmail(event.email);
      final user = UserEntity.mock(email: event.email, role: role);

      emit(state.copyWith(status: AuthStatus.authenticated, user: user));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Login failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      // TODO: Replace with actual BaaS registration call
      // await _authRepository.register(event.name, event.email, event.password);

      // After registration, go back to unauthenticated (user must login)
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Registration failed: ${e.toString()}',
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // TODO: Clear stored tokens via flutter_secure_storage
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }
}
