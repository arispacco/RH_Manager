import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../app/di.dart';
import '../../domain/entities/user_entity.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// Manages the global authentication state via Supabase.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SupabaseClient _supabase;

  AuthBloc()
      : _supabase = sl<SupabaseClient>(),
        super(const AuthState()) {
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
    final session = _supabase.auth.currentSession;
    if (session != null) {
      try {
        final userEntity = await _fetchUserProfile(session.user.id, session.user.email!);
        emit(state.copyWith(status: AuthStatus.authenticated, user: userEntity));
        return;
      } catch (e) {
        // Session exists but profile fetch failed (maybe expired or deleted)
      }
    }
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );

      if (response.user != null) {
        final userEntity = await _fetchUserProfile(response.user!.id, response.user!.email!);
        emit(state.copyWith(status: AuthStatus.authenticated, user: userEntity));
      } else {
        throw Exception('Login failed, no user returned.');
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e is AuthException ? e.message : e.toString(),
      ));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    try {
      final res = await _supabase.functions.invoke(
        'create_user',
        body: {
          'email': event.email,
          'password': event.password,
          'name': event.name,
          'role': event.accountType,
        },
      );

      if (res.status != 200) {
        throw Exception('Failed to create user: ${res.data['error'] ?? res.data}');
      }

      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e is AuthException ? e.message : e.toString(),
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _supabase.auth.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  // ── Helper ──────────────────────────────────────────────────

  Future<UserEntity> _fetchUserProfile(String userId, String email) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    final roleStr = data['role'] as String;
    UserRole role;
    switch (roleStr) {
      case 'admin':
        role = UserRole.admin;
        break;
      case 'hr':
        role = UserRole.hr;
        break;
      case 'kiosk':
        role = UserRole.kiosk;
        break;
      default:
        role = UserRole.employee;
    }

    return UserEntity(
      id: userId,
      name: data['name'] as String,
      email: email,
      role: role,
      department: data['department'] as String? ?? role.defaultDepartment,
      companyId: data['company_id'] as String?,
    );
  }
}
