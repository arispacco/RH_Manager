import 'package:equatable/equatable.dart';

/// Events dispatched to the [AuthBloc].
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// User tapped "Sign In".
class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// User tapped "Request Account" (register).
class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.accountType,
  });

  final String name;
  final String email;
  final String password;
  final String accountType;

  @override
  List<Object?> get props => [name, email, password, accountType];
}

/// User tapped "Sign Out".
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// App started – check if there is a cached session.
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}
