import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../app/di.dart';
import '../../../../app/config.dart';
import '../../../../services/postgresql_service.dart';
import '../../../../models/models.dart' as pg_models;
import '../../domain/entities/user_entity.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final PostgreSQLService? _postgres;
  final sb.SupabaseClient? _supabase;
  final FlutterSecureStorage _secureStorage;

  static const String _sessionKey = 'auth_user_id';

  AuthBloc()
      : _postgres = AppConfig.isLocal ? sl<PostgreSQLService>() : null,
        _supabase = AppConfig.isSupabase ? sl<sb.SupabaseClient>() : null,
        _secureStorage = sl<FlutterSecureStorage>(),
        super(const AuthState()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  PostgreSQLService get _localPostgres {
    final service = _postgres;
    if (service == null) {
      throw StateError('PostgreSQL backend unavailable in Supabase mode');
    }
    return service;
  }

  sb.SupabaseClient get _remoteSupabase {
    final client = _supabase;
    if (client == null) {
      throw StateError('Supabase backend unavailable in local mode');
    }
    return client;
  }

  Future<void> _onCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final storedUserId = await _secureStorage.read(key: _sessionKey);
    if (storedUserId != null) {
      try {
        if (AppConfig.isLocal) {
          if (!_localPostgres.isConnected) await _localPostgres.initialize();
          final profile = await _localPostgres.getProfile(storedUserId);
          emit(state.copyWith(status: AuthStatus.authenticated, user: _mapProfileToUserEntity(profile)));
        } else {
          final session = _remoteSupabase.auth.currentSession;
          if (session != null) {
            final response = await _remoteSupabase.from('profiles').select().eq('id', storedUserId).single();
            final profile = pg_models.Profile.fromJson(response);
            emit(state.copyWith(status: AuthStatus.authenticated, user: _mapProfileToUserEntity(profile)));
          } else {
            emit(state.copyWith(status: AuthStatus.unauthenticated));
          }
        }
        return;
      } catch (e) {
        await _secureStorage.delete(key: _sessionKey);
      }
    }
    emit(state.copyWith(status: AuthStatus.unauthenticated));
  }

  Future<void> _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      if (AppConfig.isLocal) {
        if (!_localPostgres.isConnected) await _localPostgres.initialize();
        final result = await _localPostgres.signIn(event.email, event.password);
        await _secureStorage.write(key: _sessionKey, value: result.id);
        emit(state.copyWith(status: AuthStatus.authenticated, user: _mapProfileToUserEntity(result.profile)));
      } else {
        final response = await _remoteSupabase.auth.signInWithPassword(email: event.email, password: event.password);
        if (response.user != null) {
          await _secureStorage.write(key: _sessionKey, value: response.user!.id);
          final profileData = await _remoteSupabase.from('profiles').select().eq('id', response.user!.id).single();
          // The live profiles table has no email column: inject the
          // authenticated user's email from the auth session.
          final profile = pg_models.Profile.fromJson(profileData)
              .copyWithEmail(response.user!.email ?? '');
          emit(state.copyWith(status: AuthStatus.authenticated, user: _mapProfileToUserEntity(profile)));
        }
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString()));
    }
  }

  Future<void> _onRegisterRequested(AuthRegisterRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      if (AppConfig.isLocal) {
        if (!_localPostgres.isConnected) await _localPostgres.initialize();
        await _localPostgres.signUp(event.email, event.password);
        emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null));
      } else {
        await _remoteSupabase.auth.signUp(email: event.email, password: event.password);
        emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null));
      }
    } catch (e) {
      emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _secureStorage.delete(key: _sessionKey);
    if (AppConfig.isSupabase) await _remoteSupabase.auth.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  UserEntity _mapProfileToUserEntity(pg_models.Profile profile) {
    return UserEntity(
      id: profile.id,
      name: profile.fullName,
      email: profile.email,
      role: _mapRole(profile.role),
      department: _getDepartmentForRole(profile.role),
      avatarUrl: profile.avatarUrl,
      companyId: profile.companyId,
    );
  }

  UserRole _mapRole(pg_models.AppRole role) {
    return switch (role) {
      pg_models.AppRole.superAdmin => UserRole.superAdmin,
      pg_models.AppRole.owner => UserRole.owner,
      pg_models.AppRole.admin => UserRole.admin,
      pg_models.AppRole.hr => UserRole.hr,
      pg_models.AppRole.employee => UserRole.employee,
      pg_models.AppRole.kiosk => UserRole.kiosk,
    };
  }

  String _getDepartmentForRole(pg_models.AppRole role) {
    return switch (role) {
      pg_models.AppRole.employee => 'Engineering',
      pg_models.AppRole.hr => 'Human Resources',
      pg_models.AppRole.admin => 'Platform Operations',
      pg_models.AppRole.superAdmin => 'Global Administration',
      pg_models.AppRole.owner => 'Executive',
      pg_models.AppRole.kiosk => 'Reception',
    };
  }
}
