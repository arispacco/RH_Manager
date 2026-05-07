import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/models.dart';
import '../services/postgresql_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final PostgreSQLService _postgresService;

  AuthCubit(this._postgresService) : super(const AuthInitial());

  Future<void> signUp(String email, String password) async {
    emit(const AuthLoading());
    try {
      await _postgresService.signUp(email, password);
      emit(const AuthSignUpSuccess());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signIn(String email, String password) async {
    emit(const AuthLoading());
    try {
      final result = await _postgresService.signIn(email, password);
      emit(AuthAuthenticated(result.profile));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signOut() async {
    emit(const AuthLoading());
    try {
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> checkAuthStatus() async {
    // For local dev, skip auto-login
    emit(const AuthUnauthenticated());
  }
}